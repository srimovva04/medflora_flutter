import 'package:flutter/material.dart';

import 'availability_map.dart'; // Make sure this path is correct

class PlantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const PlantDetailsPage({super.key, required this.plantData});

  Map<String, List<String>> _parseGroupedString(String? text) {
    if (text == null || text.trim().isEmpty || text == 'N/A') {
      return {};
    }

    Map<String, List<String>> grouped = {};
    // Split the text into major sections (e.g., "bark: ... | leaf: ...")
    List<String> groups = text.split('|');

    for (String group in groups) {
      String trimmedGroup = group.trim();
      if (trimmedGroup.isEmpty) continue;

      // Check if a section has a label (e.g., "bark:")
      if (trimmedGroup.contains(':')) {
        int colonIndex = trimmedGroup.indexOf(':');
        String label = trimmedGroup.substring(0, colonIndex).trim();
        String content = trimmedGroup.substring(colonIndex + 1).trim();

        // If a label is missing (e.g., ": item1, item2"), label it appropriately.
        if (label.isEmpty) {
          label = 'Unspecified Parts';
        } else {
          label = label[0].toUpperCase() + label.substring(1);
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
        // If a section has no label, group its items under "Unspecified Parts".
        List<String> items = trimmedGroup
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();

        // Add items to the list, creating it if it doesn't exist.
        if (items.isNotEmpty) {
          (grouped['Unspecified Parts'] ??= []).addAll(items);
        }
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color cardBackgroundColor = Colors.green.shade50.withOpacity(0.6);

    // --- DATA EXTRACTION ---
    final String plantName = plantData['Common Name']?.toString() ??
        plantData['Scientific Name']?.toString() ??
        'Plant Details';

    // General Info Data
    final String scientificName = plantData['Scientific Name']?.toString() ?? 'N/A';
    final String kingdom = plantData['Kingdom']?.toString() ?? 'N/A';
    final String description = 'A plant from the $kingdom kingdom, scientifically known as $scientificName. '
        'It is widely recognized for its extensive therapeutic applications and rich phytochemical profile.';

    // Therapeutic Use Data
    final String therapeuticUsesRaw = plantData['Therapeutic Uses']?.toString() ?? '';
    final Map<String, List<String>> therapeuticUsesGrouped = _parseGroupedString(therapeuticUsesRaw);

    // Location Data
    final String locations = plantData['Statewise Availability']?.toString() ?? 'No locations specified.';

    // Composition Data
    final String phytochemicalsRaw = plantData['Phytochemicals']?.toString() ?? '';
    final Map<String, List<String>> phytochemicalsGrouped = _parseGroupedString(phytochemicalsRaw);

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
            // 1. General Info Tab - ENHANCED UI
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClassificationCard(
                    context: context,
                    scientificName: scientificName,
                    kingdom: kingdom,
                    backgroundColor: cardBackgroundColor,
                  ),
                  const SizedBox(height: 24),
                  _buildDescriptionCard(
                    context: context,
                    title: 'About This Plant',
                    description: description,
                  ),
                ],
              ),
            ),

            // 2. Therapeutic Use Tab - Uses the chips UI
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildExpandableGroupedCard(
                context: context,
                icon: Icons.favorite_border_outlined,
                title: 'Therapeutic Uses by Plant Part',
                groupedItems: therapeuticUsesGrouped,
                emptyMessage: 'No therapeutic uses listed.',
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
                    title: 'Statewise Availability in India',
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
                  // const SizedBox(height: 24),
                  // _buildLocationCard(
                  //   context: context,
                  //   icon: Icons.wb_sunny,
                  //   title: 'Growing Conditions',
                  //   content: 'Detailed growing conditions are not available.',
                  //   backgroundColor: cardBackgroundColor,
                  // ),
                ],
              ),
            ),

            // 4. Composition Tab - Uses the scientific list UI
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildCompositionCard(
                context: context,
                icon: Icons.science_outlined,
                title: 'Phytochemicals by Plant Part',
                groupedItems: phytochemicalsGrouped,
                emptyMessage: 'Composition not available.',
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

  // --- Helper Widgets for UI Building ---

  /// ✨ NEW: A more structured card for displaying classification details.
  Widget _buildClassificationCard({
    required BuildContext context,
    required String scientificName,
    required String kingdom,
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
            icon: Icons.eco_outlined,
            label: 'Kingdom',
            value: kingdom,
            context: context,
          ),
        ],
      ),
    );
  }

  /// ✨ NEW: A helper for the classification card to format info rows.
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

  /// ✨ NEW: A styled card specifically for the plant description.
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

  /// UI for grouped items using ExpansionTile and Chips (for Therapeutic Use)
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
    // This widget remains unchanged
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

  /// A different UI for the Composition tab using a list format
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
    // This widget remains unchanged
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

  /// UI for the location card
  Widget _buildLocationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    required Color backgroundColor,
  }) {
    // This widget remains unchanged
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

