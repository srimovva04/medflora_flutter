import 'package:flutter/material.dart';
import 'availability_map.dart';
import 'package:url_launcher/url_launcher.dart';


class PlantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const PlantDetailsPage({super.key, required this.plantData});

  Map<String, List<String>> _parseGroupedData(dynamic input) {
    if (input == null || (input is String && (input.trim().isEmpty || input == 'N/A'))) {
      return {};
    }

    Map<String, List<String>> grouped = {};

    // --- SCENARIO 1: Input is a Map (MongoDB format: {"root": ["fever"], "leaf": "cough"}) ---
    if (input is Map) {
      input.forEach((key, value) {
        String partName = key.toString().trim();
        // Capitalize first letter (e.g., "root" -> "Root")
        if (partName.isNotEmpty) {
          partName = partName[0].toUpperCase() + partName.substring(1);
        }

        List<String> ailments = [];

        if (value is List) {
          // If value is ["fever", "cough"]
          ailments = value.map((e) => e.toString().trim()).toList();
        } else if (value is String) {
          // If value is "fever, cough" or "fever|cough"
          ailments = value
              .replaceAll('|', ',') // Normalize separators
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        if (ailments.isNotEmpty) {
          grouped[partName] = ailments;
        }
      });
      return grouped;
    }

    // --- SCENARIO 2: Input is a String (Legacy format: "root: fever | leaf: cough") ---
    if (input is String) {
      List<String> groups = input.split('|');

      for (String group in groups) {
        String trimmedGroup = group.trim();
        if (trimmedGroup.isEmpty) continue;

        if (trimmedGroup.contains(':')) {
          int colonIndex = trimmedGroup.indexOf(':');
          String label = trimmedGroup.substring(0, colonIndex).trim();
          String content = trimmedGroup.substring(colonIndex + 1).trim();

          // Capitalize label
          if (label.isNotEmpty) {
            label = label[0].toUpperCase() + label.substring(1);
          } else {
            label = 'Unspecified Parts';
          }

          List<String> items = content
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            grouped[label] = items;
          }
        } else {
          // No label found
          List<String> items = trimmedGroup
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();

          if (items.isNotEmpty) {
            (grouped['Unspecified Parts'] ??= []).addAll(items);
          }
        }
      }
    }

    return grouped;
  }

  String _parseLocationData(dynamic input) {
    if (input == null) return 'No locations specified.';

    // If it's a List ["Goa", "Assam"]
    if (input is List) {
      return input.map((e) => e.toString().trim()).join(', ');
    }

    // If it's a String
    String str = input.toString();
    if (str.isEmpty || str == 'null') return 'No locations specified.';
    return str;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardBackgroundColor = Colors.green.shade50.withOpacity(0.6);

    // --- DATA EXTRACTION ---
    // We check both the mapped keys ("Common Name") and raw Mongo keys ("name_common")
    final String plantName = plantData['Common Name']?.toString() ??
        plantData['name_common']?.toString() ??
        plantData['Scientific Name']?.toString() ??
        'Plant Details';

    // General Info Data
    final String scientificName = plantData['Scientific Name']?.toString() ??
        plantData['name_scientific']?.toString() ??
        'N/A';

    final String kingdom = plantData['Kingdom']?.toString() ??
        plantData['kingdom']?.toString() ??
        'N/A';

    final String family = plantData['Family']?.toString() ??
        plantData['family']?.toString() ??
        'Unknown Family';

    final String description = plantData['Description']?.toString() ??
        'A plant from the $family family, scientifically known as $scientificName. '
            'It is widely recognized for its extensive therapeutic applications.';

    // Therapeutic Use Data (Pass the raw object/string to the parser)
    final dynamic therapeuticRaw = plantData['therapeutic_uses'] ?? plantData['Therapeutic Uses'];
    final Map<String, List<String>> therapeuticUsesGrouped = _parseGroupedData(therapeuticRaw);

    // Location Data
    final dynamic locationRaw = plantData['state_availability'] ?? plantData['Statewise Availability'];
    final String locations = _parseLocationData(locationRaw);

    // Composition Data
    final dynamic chemicalRaw = plantData['phytochemicals'] ?? plantData['Phytochemicals'];
    final Map<String, List<String>> phytochemicalsGrouped = _parseGroupedData(chemicalRaw);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(plantName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            isScrollable: true,
            labelColor: primaryColor,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: primaryColor,
            tabs: const [
              Tab(text: 'General Info'),
              Tab(text: 'Therapeutic Use'),
              Tab(text: 'Location'),
              Tab(text: 'Composition'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. General Info Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassificationCard(
                    context: context,
                    scientificName: scientificName,
                    kingdom: kingdom,
                    family: family,
                    backgroundColor: cardBackgroundColor,
                  ),
                  const SizedBox(height: 24),
                  // _buildDescriptionCard(
                  //   context: context,
                  //   title: 'About This Plant',
                  //   description: description,
                  // ),
                  const SizedBox(height: 24), // Spacing

                  // --- NEW LINK SECTION ---
                  _buildReferenceLink(
                    context: context,
                    scientificName: scientificName,
                  ),
                ],
              ),
            ),

            // 2. Therapeutic Use Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildExpandableGroupedCard(
                context: context,
                icon: Icons.favorite_border_outlined,
                title: 'Therapeutic Uses by Part',
                groupedItems: therapeuticUsesGrouped,
                emptyMessage: 'No therapeutic uses listed in database.',
                backgroundColor: cardBackgroundColor,
                iconColor: Colors.green.shade700,
                iconBackgroundColor: Colors.green.shade100,
              ),
            ),

            // 3. Location Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationCard(
                    context: context,
                    icon: Icons.location_on,
                    title: 'Statewise Availability',
                    content: locations,
                    backgroundColor: cardBackgroundColor,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('View on Map'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AvailabilityMapPage(
                              plantName: plantName,
                              locations: locations,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 4. Composition Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildCompositionCard(
                context: context,
                icon: Icons.science_outlined,
                title: 'Chemical Composition',
                groupedItems: phytochemicalsGrouped,
                emptyMessage: 'Chemical composition data not available.',
                backgroundColor: cardBackgroundColor,
                iconColor: Colors.purple.shade700,
                iconBackgroundColor: Colors.purple.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildClassificationCard({
    required BuildContext context,
    required String scientificName,
    required String kingdom,
    required String family,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Classification',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 20, thickness: 1),
          _buildInfoRow(
            icon: Icons.science_outlined,
            label: 'Scientific Name',
            value: scientificName,
            context: context,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Family',
            value: family,
            context: context,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.eco_outlined,
            label: 'Kingdom',
            value: kingdom,
            context: context,
          ),
        ],
      ),
    );
  }


  // --- Simplified Link Widget ---

  Widget _buildReferenceLink({
    required BuildContext context,
    required String scientificName,
  }) {
    // Dynamic URL based on scientific name
    final String url = 'https://cb.imsc.res.in/imppat/therapeutics/${Uri.encodeComponent(scientificName)}';

    return Center(
      child: TextButton.icon(
        onPressed: () => _launchURL(url),
        icon: const Icon(Icons.open_in_new, size: 18),
        label: Text(
          'View on IMPPAT Database',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline, // Optional: makes it look more like a link
          ),
        ),
      ),
    );
  }

  // Helper to open the link (Requires url_launcher package)
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }



  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard({
    required BuildContext context,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.5,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableGroupedCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Map<String, List<String>> groupedItems,
    required String emptyMessage,
    required Color backgroundColor,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (groupedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
            )
          else
            ...groupedItems.entries.map((entry) {
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                iconColor: iconColor,
                collapsedIconColor: iconColor.withOpacity(0.7),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: entry.value.map((item) {
                          return Chip(
                            label: Text(
                              item,
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: iconColor.withOpacity(0.15),
                            side: BorderSide(color: iconColor.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildCompositionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Map<String, List<String>> groupedItems,
    required String emptyMessage,
    required Color backgroundColor,
    required Color iconColor,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (groupedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                emptyMessage,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                  fontSize: 15,
                ),
              ),
            )
          else
            ...groupedItems.entries.map((entry) {
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                iconColor: iconColor,
                collapsedIconColor: iconColor.withOpacity(0.7),
                title: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0, 16.0, 16.0),
                    child: Column(
                      children: entry.value.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bubble_chart_outlined,
                                size: 18,
                                color: iconColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.5,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
