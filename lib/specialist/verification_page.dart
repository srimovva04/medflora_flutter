import 'package:flutter/material.dart';
import 'verification_details.dart';

class VerificationListPage extends StatelessWidget {
  const VerificationListPage({super.key});

  // --- UPDATED DUMMY DATA WITH DYNAMIC SUGGESTIONS FOR EACH PLANT ---
  final List<Map<String, dynamic>> submissions = const [
    {
      'id': '201',
      'submittedName': 'Matucana Krahnii',
      'date': '2025-10-30',
      'score': '25%',
      'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Matucana_krahnii.JPG',
      'suggestions': [
        {
          'name': 'Matucana aurantiaca',
          'score': '56%',
          'imageUrl': 'https://www.llifle.com/Encyclopedia/CACTI/Family/Cactaceae/20616/photos/Matucana_aurantiaca_subs._polzii_11881_m.jpg',
        },
        {
          'name': 'Matucana haynii',
          'score': '75%',
          'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/1080/photos/Matucana_haynei_11889_m.jpg',
        },
        {
          'name': 'Matucana ritteri',
          'score': '45%',
          'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/6063/photos/Matucana_ritteri_8932_m.jpg',
        },
        {
          'name': 'Matucana calliantha',
          'score': '70%',
          'imageUrl': 'https://llifle.com/Encyclopedia/CACTI/Family/Cactaceae/6033/photos/Matucana_calliantha_2553_m.jpg',
        },
        {
          'name': 'Matucana paucicostata',
          'score': '15%',
          'imageUrl': 'https://alchetron.com/cdn/matucana-359b153b-680c-4b9e-9839-20b04e8fcc5-resize-750.jpeg',
        },
      ],
    },
    {
      'id': '202',
      'submittedName': 'Eschscholzia',
      'date': '2025-10-29',
      'score': '41%',
      'imageUrl': 'https://as1.ftcdn.net/v2/jpg/14/47/93/76/1000_F_1447937685_JpwbqJl3p7V6L5IDf87PFbxuP8OD0STM.jpg',
      // Add suggestions specific to Eschscholzia
      'suggestions': [
        {
          'name': 'Eschscholzia minutiflora',
          'score': '15%',
          'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/ec/Eschscholzia_minutiflora_1.jpg',
        },
        {
          'name': 'Eschscholzia californica',
          'score': '32%',
          'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/a/a1/California_poppy_%28Eschscholzia_californica%29_-_22.jpg',
        },

      ],
    },
    {
      'id': '203',
      'submittedName': 'Scutellaria',
      'date': '2025-10-28',
      'score': '85%',
      'imageUrl': 'https://as2.ftcdn.net/v2/jpg/15/75/02/71/1000_F_1575027124_juV9JLgb5hMA6WeeAFaPn9MQRDC1zzJQ.jpg',
      // Add suggestions specific to Scutellaria
      'suggestions': [
        {
          'name': 'Scutellaria lateriflora',
          'score': '40%',
          'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Scutellaria_lateriflora_01.JPG',
        },
        {
          'name': 'Scutellaria alpina',
          'score': '35%',
          'imageUrl': 'https://www.freenatureimages.eu/plants/Flora%20S-Z/Scutellaria%20alpina%2C%20Alpine%20Skullcap/Scutellaria%20alpina%201%2C%20Saxifraga-Willem%20van%20Kruijsbergen.jpg',
        },
        {
          'name': 'Scutellaria baicalensis',
          'score': '75%',
          'imageUrl': 'https://www.rialpharma.it/wp-content/uploads/2020/09/Scutellaria_baicalensis_skullcap_herb_620x_f10d02d9-032a-49f7-b72f-16081aa7c1d1-338483_502x700.jpg',
        },
      ],
    },
    // {
    //   'id': '204',
    //   'submittedName': 'Cannabaceae',
    //   'date': '2025-10-27',
    //   'score': '91%',
    //   'imageUrl': 'https://plus.unsplash.com/premium_photo-1669687380166-bc9d3c806955?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
    //   'suggestions': [
    //     {
    //       'name': 'Scutellaria lateriflora',
    //       'score': '92%',
    //       'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Scutellaria_lateriflora_1-jgreenlee.jpg/1024px-Scutellaria_lateriflora_1-jgreenlee.jpg',
    //     },
    //     {
    //       'name': 'Salvia officinalis',
    //       'score': '65%',
    //       'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Salvia_officinalis_0001.jpg',
    //     },
    //     {
    //       'name': 'Lamium purpureum',
    //       'score': '55%',
    //       'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5b/Lamium_purpureum_2005.04.14_12.39.11.jpg/1200px-Lamium_purpureum_2005.04.14_12.39.11.jpg',
    //     },
    //   ],
    // },

    // Add more entries as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Submissions'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: submissions.length,
        itemBuilder: (context, index) {
          final submission = submissions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                leading: ClipOval(
                  child: SizedBox.fromSize(
                    size: const Size.fromRadius(25), // Image radius
                    child: Image.network(
                      submission['imageUrl'],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Image failed to load for ${submission['submittedName']}: $error');
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.eco, color: Colors.green, size: 30),
                        );
                      },
                    ),
                  ),
                ),
                title: Text(
                  submission['submittedName'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Submitted on: ${submission['date']}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  // The entire submission map (including suggestions) is passed here
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerificationDetailPage(submissionData: submission),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

///OLD CODE WITH SAME IMAGES
// import 'package:flutter/material.dart';
// import 'verification_details.dart'; // Make sure this file exists in your project
//
// class VerificationListPage extends StatelessWidget {
//   const VerificationListPage({super.key});
//
//   // --- FIXED DUMMY DATA WITH WORKING IMAGE URLS ---
//   // Using placeholder images from reliable sources that work without special headers
//   final List<Map<String, dynamic>> submissions = const [
//     {
//       'id': '201',
//       'submittedName': 'Matucana Krahnii',
//       'date': '2025-10-30',
//       'score': '25%',
//       // Using a reliable placeholder - replace with your own hosted images or stable URLs
//       'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/e/e7/Matucana_krahnii.JPG',
//     },
//     {
//       'id': '202',
//       'submittedName': 'Eschscholzia',
//       'date': '2025-10-29',
//       'score': '41%',
//       'imageUrl': 'https://as1.ftcdn.net/v2/jpg/14/47/93/76/1000_F_1447937685_JpwbqJl3p7V6L5IDf87PFbxuP8OD0STM.jpg',
//     },
//     {
//       'id': '203',
//       'submittedName': 'Scutellaria',
//       'date': '2025-10-28',
//       'score': '85%',
//       'imageUrl': 'https://as2.ftcdn.net/v2/jpg/15/75/02/71/1000_F_1575027124_juV9JLgb5hMA6WeeAFaPn9MQRDC1zzJQ.jpg',
//     },
//     {
//       'id': '204',
//       'submittedName': 'Cannabaceae',
//       'date': '2025-10-27',
//       'score': '91%',
//       'imageUrl': 'https://plus.unsplash.com/premium_photo-1669687380166-bc9d3c806955?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=687',
//     }
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Submissions'),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16.0),
//         itemCount: submissions.length,
//         itemBuilder: (context, index) {
//           final submission = submissions[index];
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 12.0),
//             child: Card(
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                 leading: ClipOval(
//                   child: SizedBox.fromSize(
//                     size: const Size.fromRadius(25), // Image radius
//                     child: Image.network(
//                       submission['imageUrl'],
//                       fit: BoxFit.cover,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return const Center(child: CircularProgressIndicator());
//                       },
//                       errorBuilder: (context, error, stackTrace) {
//                         debugPrint('Image failed to load for ${submission['submittedName']}: $error');
//                         return Container(
//                           color: Colors.grey.shade200,
//                           child: const Icon(Icons.eco, color: Colors.green, size: 30),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//                 title: Text(
//                   submission['submittedName'],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('Submitted on: ${submission['date']}'),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//                 onTap: () {
//                   // Navigate to the detail page on tap.
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => VerificationDetailPage(submissionData: submission),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }















///OLD CODE
// import 'package:flutter/material.dart';
// import 'verification_details.dart'; // Import the detail page
//
// class VerificationListPage extends StatelessWidget {
//   const VerificationListPage({super.key});
//
//   // --- DUMMY DATA FOR THE SUBMISSION LIST ---
//   // This list creates the entries that appear on the page.
//   final List<Map<String, dynamic>> submissions = const [
//     {
//       'id': '101',
//       'submittedName': 'Tulsi',
//       'date': '2025-10-17',
//       'score': '92%',
//       'imageUrl': 'https://plus.unsplash.com/premium_photo-1671070369255-a459b1a85a4a?q=80&w=2071&auto=format&fit=crop',
//     },
//     {
//       'id': '102',
//       'submittedName': 'Unknown Leaf',
//       'date': '2025-10-16',
//       'score': '88%',
//       'imageUrl': 'https://images.unsplash.com/photo-1629828328229-37a5e0108502?q=80&w=2070&auto=format&fit=crop',
//     },
//     {
//       'id': '103',
//       'submittedName': 'Ashwagandha?',
//       'date': '2025-10-16',
//       'score': '76%',
//       'imageUrl': 'https://images.unsplash.com/photo-1595152772236-4b8156157154?q=80&w=1974&auto=format&fit=crop',
//     },
//     {
//       'id': '104',
//       'submittedName': 'Mint Leaf',
//       'date': '2025-10-15',
//       'score': '95%',
//       'imageUrl': 'https://images.unsplash.com/photo-1620075436900-a8865646f901?q=80&w=2070&auto=format&fit=crop',
//     }
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Verify Submissions'),
//       ),
//       body: ListView.builder(
//         // Use padding on the ListView for better spacing
//         padding: const EdgeInsets.all(16.0),
//         itemCount: submissions.length,
//         itemBuilder: (context, index) {
//           final submission = submissions[index];
//           // Use Padding for spacing between cards
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 12.0),
//             child: Card( // This card uses the global theme from main.dart
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//                 leading: CircleAvatar(
//                   backgroundImage: NetworkImage(submission['imageUrl']),
//                   radius: 25,
//                 ),
//                 title: Text(
//                   submission['submittedName'],
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 subtitle: Text('Submitted on: ${submission['date']}'),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//                 onTap: () {
//                   // Navigate to the detail page, passing the selected submission's data
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => VerificationDetailPage(submissionData: submission),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }