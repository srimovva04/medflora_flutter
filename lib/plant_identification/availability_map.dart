import 'dart:convert';
import 'dart:math'; // Required for the Point class
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:diacritic/diacritic.dart';
import 'package:polylabel/polylabel.dart';

class AvailabilityMapPage extends StatefulWidget {
  final String plantName;
  final String locations;

  const AvailabilityMapPage({
    super.key,
    required this.plantName,
    required this.locations,
  });

  @override
  State<AvailabilityMapPage> createState() => _AvailabilityMapPageState();
}

class _AvailabilityMapPageState extends State<AvailabilityMapPage> {
  List<Polygon> _polygons = [];
  List<Marker> _labelMarkers = [];
  bool _isLoading = true;

  final Color presentColor = const Color(0xFF2AAA8A);
  final Color notPresentColor = const Color(0xFFFFCCCB);

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  /// Calculates the bounding box area of a polygon, used for dynamic sizing.
  double _getPolygonArea(List<LatLng> points) {
    if (points.isEmpty) return 0;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLon = points.first.longitude, maxLon = points.first.longitude;
    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return (maxLat - minLat) * (maxLon - minLon);
  }

  /// Normalizes state names to be simple and consistent for matching.
  String _normalizeStateName(String name) {
    String plainName = removeDiacritics(name.toLowerCase());
    plainName = plainName.replaceAll('&', 'and').replaceAll('\n', '');
    return plainName.replaceAll(RegExp(r'[^a-z]'), '');
  }

  /// Loads GeoJSON, processes state data, and builds map layers.
  Future<void> _loadMapData() async {
    // Programmatically correct known typos from the source data before processing.
    String correctedLocations = widget.locations.replaceAll("Maharastra", "Maharashtra");
    final availableStates = correctedLocations.split(',').map((s) => _normalizeStateName(s.trim())).toSet();

    final geoJsonString = await rootBundle.loadString('assets/geoBoundaries-IND-ADM1_simplified.geojson');
    final geoJson = json.decode(geoJsonString);
    final features = geoJson['features'] as List;

    final List<Polygon> processedPolygons = [];
    final List<Marker> processedMarkers = [];

    for (final feature in features) {
      final properties = feature['properties'] as Map<String, dynamic>;
      final geometry = feature['geometry'] as Map<String, dynamic>;
      final shapeName = properties['shapeName'] as String? ?? '';
      final normalizedShapeName = _normalizeStateName(shapeName);
      final isPresent = availableStates.contains(normalizedShapeName);

      List<LatLng> pointsForLabel = [];
      double largestArea = 0;

      void processPolygonCoordinates(List polygonCoords, {bool isMulti = false}) {
        final points = polygonCoords
            .map<LatLng>((p) => LatLng(p[1] as double, p[0] as double))
            .toList();

        processedPolygons.add(Polygon(
          points: points,
          color: isPresent ? presentColor.withOpacity(0.7) : notPresentColor.withOpacity(0.7),
          borderColor: Colors.black,
          borderStrokeWidth: 0.5,
          isFilled: true,
        ));

        // For multi-part states, find the largest part to place the label on.
        if (!isMulti || points.length > largestArea) {
          largestArea = points.length.toDouble();
          pointsForLabel = points;
        }
      }

      if (geometry['type'] == 'Polygon') {
        processPolygonCoordinates(geometry['coordinates'][0]);
      } else if (geometry['type'] == 'MultiPolygon') {
        for (final poly in geometry['coordinates']) {
          processPolygonCoordinates(poly[0], isMulti: true);
        }
      }

      final double area = _getPolygonArea(pointsForLabel);
      // Set a threshold to hide labels for very small states to reduce clutter.
      const double areaThreshold = 0.3;

      if (pointsForLabel.isNotEmpty && area > areaThreshold) {
        // Use polylabel to find the best visual center for the label.
        final polylabelInput = [pointsForLabel.map((p) => Point(p.longitude, p.latitude)).toList()];
        final centerPoint = polylabel(polylabelInput);

        // Dynamically adjust marker and font size based on state size.
        final double markerWidth = (area * 30).clamp(50.0, 100.0);
        final double fontSize = (6 + (area * 2.5)).clamp(6.0, 10.0);

        processedMarkers.add(
          Marker(
            point: LatLng(centerPoint.point.y.toDouble(), centerPoint.point.x.toDouble()),
            width: markerWidth,
            height: 40,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(shapeName),
                    content: Text(
                      'This plant is ${isPresent ? "present" : "not present"} in $shapeName.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    shapeName.replaceAll(' and ', ' & ').replaceAll(' Pradesh', ' P.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _polygons = processedPolygons;
      _labelMarkers = processedMarkers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Availability of ${widget.plantName}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(22.5, 82.0),
          initialZoom: 4.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Allow pan/zoom, disable rotate
          ),
        ),
        children: [
          PolygonLayer(polygons: _polygons),
          MarkerLayer(markers: _labelMarkers),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(padding: const EdgeInsets.all(10.0), child: _buildLegend()),
          )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem(color: presentColor, text: 'Present'),
          const SizedBox(height: 8),
          _buildLegendItem(color: notPresentColor, text: 'Not Present'),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, border: Border.all(color: Colors.black, width: 0.5)),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

