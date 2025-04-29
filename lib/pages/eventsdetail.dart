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
    final caterogy = eventData['category'] ?? 'No Category';
    final location = eventData['location'] ?? 'No Location';
    final bannerUrl = eventData['banner'] ?? '';
    final startDate = eventData['datetimestart']?.toDate();
    final endDate = eventData['datetimeend']?.toDate();
    final slots = eventData['total_slots'] ?? '';

    final formattedStartDate =
        startDate != null ? startDate.toString() : 'Not specified';
    final formattedEndDate =
        endDate != null ? endDate.toString() : 'Not specified';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal.shade400,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bannerUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Image.network(
                  fixImgurLink(bannerUrl),
                  height: 540,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 240,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 70,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedStartDate == formattedEndDate
                            ? formattedStartDate
                            : '$formattedStartDate - $formattedEndDate',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this event',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ) ??
                        const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Category',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    caterogy,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ) ??
                        const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Slots',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$slots",
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ) ??
                        const TextStyle(fontSize: 16, color: Colors.grey),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
