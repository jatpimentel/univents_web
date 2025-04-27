import 'package:flutter/material.dart';

class EventDetailsPage extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailsPage({Key? key, required this.eventData}) : super(key: key);

  String fixImgurLink(String url) {
    if (url.contains('imgur.com') && !url.endsWith('.jpg')) {
      final id = url.split('/').last;
      return 'https://i.imgur.com/$id.jpg';
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final title = eventData['title'] ?? 'No Title';
    final description = eventData['description'] ?? 'No Description';
    final location = eventData['location'] ?? 'No Location';
    final bannerUrl = eventData['banner'] ?? '';
    final startDate = eventData['datetimestart']?.toDate();
    final endDate = eventData['datetimeend']?.toDate();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bannerUrl.isNotEmpty)
              Image.network(
                fixImgurLink(bannerUrl),
                height: 200,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (startDate != null && endDate != null)
                    Text(
                      "From: ${startDate.toString()}\nTo: ${endDate.toString()}",
                      style: const TextStyle(fontSize: 16),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Location: $location',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(description, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
