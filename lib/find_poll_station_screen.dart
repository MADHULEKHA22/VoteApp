import 'package:flutter/material.dart';

class FindPollStationScreen extends StatelessWidget {
  FindPollStationScreen({super.key});

  final List<Map<String, String>> stations = [
    {
      "name": "Community Hall Polling Booth",
      "address": "123 Main Street, Chennai",
      "distance": "0.8 km"
    },
    {
      "name": "Municipal School Polling Booth",
      "address": "456 Anna Salai, Chennai",
      "distance": "1.5 km"
    },
    {
      "name": "Library Polling Booth",
      "address": "789 Gandhi Road, Chennai",
      "distance": "2.3 km"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Poll Station"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F9FD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Heading
            Text(
              "Nearby Polling Stations",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(height: 16),

            /// Map preview
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: NetworkImage(
                    // you can replace with your own map image or integrate Google Maps later
                    "https://maps.googleapis.com/maps/api/staticmap?center=Chennai,India&zoom=13&size=600x300&maptype=roadmap&key=YOUR_API_KEY",
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// Stations list
            ...stations.map(
              (station) => Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.deepPurple),
                  title: Text(
                    station['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  subtitle: Text(
                    "${station['address']}\n${station['distance']} away",
                    style: const TextStyle(fontSize: 13),
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Directions to ${station['name']} coming soon!")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: const Text("Navigate"),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
