import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventId;
  final VoidCallback onUpdate;

  const EventDetailsPage({
    Key? key,
    required this.eventData,
    required this.eventId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPage extends StatefulWidget {
  final Map<String, dynamic> eventData;
  final String eventId;
  final VoidCallback onUpdate;

  const _EventDetailsPage({
    Key? key,
    required this.eventData,
    required this.eventId,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _attendeesList = [];
  String? _organizationId;
  List<String> _organizationIds = []; // This will store the fetched organization IDs

  @override
  void initState() {
    super.initState();
    _organizationId = widget.eventData['organizationId'];
    _fetchOrganizations().then((_) => _loadAttendees());
  }

  Future<void> _fetchOrganizations() async {
    try {
      final organizationsSnapshot = 
          await FirebaseFirestore.instance.collection('organizations').get();
      
      setState(() {
        _organizationIds = organizationsSnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      print('Error fetching organizations: $e');
      setState(() {
        _organizationIds = []; // Fallback to empty list if there's an error
      });
    }
  }

  Future<void> _loadAttendees() async {
    print('Loading attendees for event: ${widget.eventId}');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.eventId.isEmpty) {
      setState(() {
        _errorMessage = 'ERROR: Event ID is empty!';
        _isLoading = false;
      });
      return;
    }

    // Try the specified organization first if valid
    if (_organizationId != null && 
        _organizationIds.contains(_organizationId)) {
      await _tryOrganizationPath(_organizationId!);
      if (_attendeesList.isNotEmpty) return;
    }

    // If not found, try all organizations
    for (final orgId in _organizationIds) {
      if (orgId == _organizationId) continue; // Skip already tried organization

      await _tryOrganizationPath(orgId);
      if (_attendeesList.isNotEmpty) return;
    }

    // If still not found, try direct path
    await _tryDirectPath();
  }

  Future<void> _tryOrganizationPath(String orgId) async {
    print('Trying organization: $orgId');
    try {
      final eventDoc =
          await FirebaseFirestore.instance
              .collection('organizations')
              .doc(orgId)
              .collection('events')
              .doc(widget.eventId)
              .get();

      if (eventDoc.exists) {
        print('Found event in organization: $orgId');
        _organizationId = orgId;

        final snapshot =
            await FirebaseFirestore.instance
                .collection('organizations')
                .doc(orgId)
                .collection('events')
                .doc(widget.eventId)
                .collection('attendees')
                .get();

        final attendees =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'accountid': data['accountid'] ?? 'Unknown',
                'datetimestamp': data['datetimestamp'] ?? Timestamp.now(),
                'status':
                    (data['status'] ?? 'pending').toString().toLowerCase(),
              };
            }).toList();

        setState(() {
          _attendeesList = attendees;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error checking organization $orgId: $e');
    }
  }

  Future<void> _tryDirectPath() async {
    print('Trying direct events path');
    try {
      final eventDoc =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .get();

      if (eventDoc.exists) {
        final snapshot =
            await FirebaseFirestore.instance
                .collection('events')
                .doc(widget.eventId)
                .collection('attendees')
                .get();

        final attendees =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'accountid': data['accountid'] ?? 'Unknown',
                'datetimestamp': data['datetimestamp'] ?? Timestamp.now(),
                'status':
                    (data['status'] ?? 'pending').toString().toLowerCase(),
              };
            }).toList();

        setState(() {
          _attendeesList = attendees;
          _isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Error trying direct path: $e');
    }

    // If all attempts fail
    setState(() {
      _errorMessage = 'Event not found in any organization or direct path';
      _isLoading = false;
    });
  }

  // Simplified version of _tryRootCollection
  void _tryRootCollection() {
    print('Trying root collection with eventId filter');

    FirebaseFirestore.instance
        .collection('attendees')
        .where('eventId', isEqualTo: widget.eventId)
        .get()
        .then((snapshot) {
          print('Found ${snapshot.docs.length} attendees in root collection');

          if (snapshot.docs.isEmpty) {
            setState(() {
              _attendeesList = [];
              _isLoading = false;
              _errorMessage = 'No attendees found in any path';
            });
            return;
          }

          final attendees =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return {
                  'id': doc.id,
                  'accountid': data['accountid'] ?? 'Unknown',
                  'datetimestamp': data['datetimestamp'] ?? Timestamp.now(),
                  'status':
                      (data['status'] ?? 'pending').toString().toLowerCase(),
                };
              }).toList();

          setState(() {
            _attendeesList = attendees;
            _isLoading = false;
          });
        })
        .catchError((error) {
          setState(() {
            _errorMessage = 'Failed to load attendees: $error';
            _isLoading = false;
          });
        });
  }

  // Try alternative paths for attendees
  void _tryAlternativePaths(dynamic error) {
    print('Error loading attendees: $error');
    print('Trying alternative path: Attendees (capitalized)');

    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('Attendees')
        .get()
        .then((snapshot) {
          print(
            'Found ${snapshot.docs.length} attendees (capitalized collection)',
          );

          final attendees =
              snapshot.docs.map((doc) {
                return {'id': doc.id, ...doc.data()};
              }).toList();

          setState(() {
            _attendeesList = attendees;
            _isLoading = false;
          });
        })
        .catchError((secondError) {
          print('Error with alternative path: $secondError');
          _tryRootCollection();
        });
  }

  // Add a test attendee to verify the collection is working
  void _addTestAttendee() {
    setState(() {
      _isLoading = true;
    });

    // Create test attendee data
    final testAttendee = {
      'accountid': '/accounts/testuser${DateTime.now().millisecondsSinceEpoch}',
      'datetimestamp': Timestamp.now(),
      'status': 'pending',
      'eventId':
          widget.eventId, // Add this reference for direct collection queries
    };

    // First try with the organization path structure
    if (_organizationId != null) {
      print(
        'Adding test attendee to: organizations/$_organizationId/events/${widget.eventId}/attendees',
      );

      FirebaseFirestore.instance
          .collection('organizations')
          .doc(_organizationId)
          .collection('events')
          .doc(widget.eventId)
          .collection('attendees')
          .add(testAttendee)
          .then((docRef) {
            print('Test attendee added with ID: ${docRef.id}');
            // Reload attendees after adding
            _loadAttendees();
          })
          .catchError((error) {
            print('Error adding test attendee to organizations path: $error');
            _tryAddToDirectPath(testAttendee);
          });
    } else {
      _tryAddToDirectPath(testAttendee);
    }
  }

  void _tryAddToDirectPath(Map<String, dynamic> testAttendee) {
    print('Adding test attendee to: events/${widget.eventId}/attendees');

    FirebaseFirestore.instance
        .collection('events')
        .doc(widget.eventId)
        .collection('attendees')
        .add(testAttendee)
        .then((docRef) {
          print('Test attendee added with ID: ${docRef.id}');
          // Reload attendees after adding
          _loadAttendees();
        })
        .catchError((error) {
          print('Error adding test attendee: $error');

          // Try alternative collection
          print('Trying to add to capitalized collection');
          FirebaseFirestore.instance
              .collection('events')
              .doc(widget.eventId)
              .collection('Attendees')
              .add(testAttendee)
              .then((docRef) {
                print(
                  'Test attendee added to capitalized collection with ID: ${docRef.id}',
                );
                _loadAttendees();
              })
              .catchError((secondError) {
                // Last attempt - add to a root collection
                print('Trying to add to root attendees collection');
                FirebaseFirestore.instance
                    .collection('attendees')
                    .add(testAttendee)
                    .then((docRef) {
                      print(
                        'Test attendee added to root collection with ID: ${docRef.id}',
                      );
                      _loadAttendees();
                    })
                    .catchError((finalError) {
                      setState(() {
                        _errorMessage =
                            'Failed to add test attendee: $finalError';
                        _isLoading = false;
                      });
                    });
              });
        });
  }

  String fixImgurLink(String url) {
    if (url.contains('imgur.com') && !url.endsWith('.jpg')) {
      final id = url.split('/').last;
      return 'https://i.imgur.com/$id.jpg';
    }
    return url;
  }

  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'verified':
        return 'Verified';
      default:
        return 'Unknown';
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Extract account ID to display as name if name is not available
  String extractNameFromAccountId(String? accountId) {
    if (accountId == null || accountId.isEmpty) return 'Unknown';

    // Extract the last part after the last slash
    final parts = accountId.split('/');
    if (parts.length > 1) {
      return parts.last;
    }

    return accountId;
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method remains the same
    final title = widget.eventData['title'] ?? 'No Title';
    final description = widget.eventData['description'] ?? 'No Description';
    final category = widget.eventData['category'] ?? 'No Category';
    final location = widget.eventData['location'] ?? 'No Location';
    final bannerUrl = widget.eventData['banner'] ?? '';
    final startDate = widget.eventData['datetimestart']?.toDate();
    final endDate = widget.eventData['datetimeend']?.toDate();
    final slots = widget.eventData['total_slots'] ?? '0';

    final formattedStartDate =
        startDate != null ? _formatDateTime(startDate) : 'Not specified';
    final formattedEndDate =
        endDate != null ? _formatDateTime(endDate) : 'Not specified';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal.shade400,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              widget.onUpdate();
            },
          ),
        ],
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
                    print('Image error: $error');
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
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
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
                    category,
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
                  ),
                  const SizedBox(height: 20),
                  // Attendees section with Add button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Attendees',
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
                      // Add refresh and add attendee buttons
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadAttendees,
                          ),
                          // Add attendee button
                          IconButton(
                            icon: const Icon(Icons.person_add),
                            onPressed: _addTestAttendee,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Improved Attendees section
                  _buildAttendeesSection(),
                  // Debug info section
                  const SizedBox(height: 20),
                  // Text(
                  //   'Debug Information',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.grey.shade700,
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text('Event ID: ${widget.eventId}'),
                        if (_organizationId != null)
                          //Text('Organization ID: $_organizationId'),
                          //Text('Primary Path: ${_organizationId != null ? 'organizations/$_organizationId/events/${widget.eventId}/attendees' : 'events/${widget.eventId}/attendees'}',),
                          // Text('Attendees found: ${_attendeesList.length}'),
                          if (_errorMessage != null)
                            Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendeesSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (_errorMessage != null) {
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAttendees,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // No attendees case
    if (_attendeesList.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'No attendees registered yet.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _addTestAttendee,
                child: const Text('Add Test Attendee'),
              ),
            ],
          ),
        ),
      );
    }

    // Show attendees table
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: MaterialStateProperty.all(Colors.teal.shade50),
          columns: const [
            DataColumn(
              label: Text(
                'Account ID',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Registration Date',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows:
              _attendeesList.map((data) {
                try {
                  // Use accountid with better null handling
                  final accountId = data['accountid'] ?? 'Not specified';
                  final displayName = extractNameFromAccountId(accountId);

                  // Handle timestamps properly
                  final timestamp = data['datetimestamp'];
                  final registrationDate =
                      timestamp != null
                          ? _formatDateTime(timestamp.toDate())
                          : 'Not specified';

                  // Get status with better handling
                  final statusField = data['status'];
                  String status = 'unknown';

                  if (statusField is String) {
                    status = statusField.trim().toLowerCase();
                  } else if (statusField is List && statusField.isNotEmpty) {
                    status = statusField.first.toString().trim().toLowerCase();
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(displayName)),
                      DataCell(Text(registrationDate)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: getStatusColor(status)),
                          ),
                          child: Text(
                            getStatusLabel(status),
                            style: TextStyle(color: getStatusColor(status)),
                          ),
                        ),
                      ),
                    ],
                  );
                } catch (e) {
                  print('Error processing attendee: $e');
                  // Return a fallback row with error information
                  return const DataRow(
                    cells: [
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                      DataCell(Text('-')),
                    ],
                  );
                }
              }).toList(),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    // Format date in a more readable way
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }
}

