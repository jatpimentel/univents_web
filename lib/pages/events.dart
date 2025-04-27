import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'eventsdetail.dart'; // <-- import this!

class EventsPage extends StatelessWidget {
  const EventsPage({Key? key}) : super(key: key);

  String fixImgurLink(String url) {
    if (url.contains('imgur.com') && !url.endsWith('.jpg')) {
      final id = url.split('/').last;
      return 'https://i.imgur.com/$id.jpg';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collectionGroup('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No events found.'));
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;
              final title = eventData['title'] ?? 'No title';
              final description = eventData['description'] ?? 'No description';
              final location = eventData['location'] ?? 'No location';
              final bannerUrl = eventData['banner'] ?? '';

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading:
                      bannerUrl.isNotEmpty
                          ? Image.network(
                            fixImgurLink(bannerUrl),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                          : const Icon(Icons.event),
                  title: Text(title),
                  subtitle: Text('$description\nLocation: $location'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventDetailsPage(eventData: eventData),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
