import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'dart:async';
import 'package:excel/excel.dart' as excel;
import 'plant_result.dart';

class PlantDataService {
  static const String SCIENTIFIC_NAME_KEY = 'Scientific Name';
  static const String STATE_AVAILABILITY_KEY = 'Statewise Availability';
  static const String _assetPath = 'assets/plant_data.xlsx';

  static Future<List<Map<String, dynamic>>> _loadRawPlantRecords() async {
    try {
      ByteData data = await rootBundle.load(_assetPath);
      var bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      var excelFile = excel.Excel.decodeBytes(bytes);
      final sheetName = excelFile.tables.keys.first;
      var sheet = excelFile.tables[sheetName];

      if (sheet == null || sheet.maxRows < 2) return [];

      final headerRow = sheet.row(0).map((cell) => cell?.value.toString().trim() ?? '').toList();
      final List<Map<String, dynamic>> rawRecords = [];

      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;

        final Map<String, dynamic> record = {};
        for (int j = 0; j < headerRow.length; j++) {
          if (j < row.length) {
            record[headerRow[j]] = row[j]?.value.toString();
          }
        }
        if (record.containsKey(SCIENTIFIC_NAME_KEY) && record.containsKey(STATE_AVAILABILITY_KEY)) {
          rawRecords.add(record);
        }
      }
      return rawRecords;
    } catch (e) {
      debugPrint("Error loading raw plant data file: $e");
      return [];
    }
  }

  static Future<List<String>> loadAllPlantNames() async {
    final rawRecords = await _loadRawPlantRecords();
    final Set<String> names = {};
    for (final record in rawRecords) {
      final String scientificName = record[SCIENTIFIC_NAME_KEY]?.toString().trim() ?? '';
      if (scientificName.isNotEmpty) names.add(scientificName);
    }
    final List<String> sortedNames = names.toList();
    sortedNames.sort();
    return sortedNames;
  }
}

class SearchByNamePage extends StatefulWidget {
  const SearchByNamePage({super.key});

  @override
  State<SearchByNamePage> createState() => _SearchByNamePageState();
}

class _SearchByNamePageState extends State<SearchByNamePage> {
  late Future<List<String>> _plantNamesFuture;
  List<String> _allPlantNames = [];
  List<String> _filteredPlantNames = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _plantNamesFuture = PlantDataService.loadAllPlantNames();
    _plantNamesFuture.then((data) {
      setState(() {
        _allPlantNames = data;
        _filteredPlantNames = data;
      });
    });
    _searchController.addListener(_filterPlants);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterPlants);
    _searchController.dispose();
    super.dispose();
  }

  void _filterPlants() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPlantNames = _allPlantNames
          .where((plant) => plant.toLowerCase().contains(query))
          .toList();
    });
  }

  void _onPlantTap(BuildContext context, String plantName) {


    // --- CALL THE COMPONENT ---
    Navigator.push(
      context,
      MaterialPageRoute(
        // We reuse the PlantResultPage from plant_result.dart
        // It handles loading the specific details internally.
        builder: (context) => PlantResultPage(
          plantName: plantName,
          imageUrl: 'null',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Flora by Name'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: FutureBuilder<List<String>>(
        future: _plantNamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Failed to load data.'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by Scientific Name...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterPlants();
                        FocusScope.of(context).unfocus();
                      },
                    )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.all(14.0),
                  ),
                ),
              ),
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: _filteredPlantNames.length,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    itemBuilder: (context, index) {
                      final plant = _filteredPlantNames[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(Icons.grass, color: Theme.of(context).primaryColor, size: 28),
                            ),
                            title: Text(plant, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF388E3C))),
                            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                            onTap: () => _onPlantTap(context, plant),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

