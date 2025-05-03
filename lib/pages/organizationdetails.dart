import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrganizationDetailsPage extends StatelessWidget {
  final Map<String, dynamic> organizationData;
  final String? organizationId; // Made nullable to maintain compatibility
  final Function? onUpdate; // Made nullable to maintain compatibility

  const OrganizationDetailsPage({
    Key? key,
    required this.organizationData,
    this.organizationId,
    this.onUpdate,
  }) : super(key: key);

  String fixImgurLink(String url) {
    if (url.contains('imgur.com') && !url.endsWith('.jpg')) {
      final id = url.split('/').last;
      return 'https://i.imgur.com/$id.jpg';
    }
    return url;
  }

  // Helper method to safely get string values
  String _safeString(dynamic value) {
    if (value == null) return 'Not specified';
    if (value is String) return value;
    if (value is List)
      return value.join(', '); // Convert list to comma-separated string
    return value.toString(); // Convert any other type to string
  }

  @override
  Widget build(BuildContext context) {
    final accronym = _safeString(organizationData['accronym']);
    final name = _safeString(organizationData['name']);
    final description = _safeString(organizationData['description']);
    final category = _safeString(organizationData['category']);
    final email = _safeString(organizationData['email']);
    final bannerUrl =
        organizationData['banner'] is String ? organizationData['banner'] : '';

    final facebook = _safeString(organizationData['facebook']);
    final mobile = _safeString(organizationData['mobile']);
    final status = _safeString(organizationData['status']);

    return Scaffold(
      appBar: AppBar(
        title: Text(accronym),
        backgroundColor: Colors.indigo.shade400,
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
                  height: 240,
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
                    accronym,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade800,
                        ) ??
                        const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.indigo.shade600,
                        ) ??
                        const TextStyle(fontSize: 18, color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(Icons.email, 'Email', email),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.category, 'Category', category),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.phone, 'Mobile', mobile),
                          const SizedBox(height: 8),
                          if (facebook != 'Not specified')
                            _buildInfoRow(Icons.facebook, 'Facebook', facebook),
                          const SizedBox(height: 8),
                          _buildInfoRow(Icons.flag, 'Status', status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this organization',
                    style:
                        Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.indigo.shade700,
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.indigo,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        description,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              color: Colors.grey.shade800,
                              height: 1.5,
                            ) ??
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
