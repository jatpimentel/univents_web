import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'eventsdetail.dart';
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({Key? key}) : super(key: key);

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  String fixImgurLink(String url) {
    if (url.isEmpty) return url;

    // Standardize URL by ensuring it uses https
    String standardUrl = url.replaceFirst(RegExp(r'^http://'), 'https://');

    // Handle cases when the URL isn't an Imgur URL
    if (!standardUrl.contains('imgur.com')) return standardUrl;

    // Extract the ID portion from the URL, handling different formats
    String imgurId;

    // Handle album/gallery links (imgur.com/a/ID or imgur.com/gallery/ID)
    if (standardUrl.contains('/a/') || standardUrl.contains('/gallery/')) {
      RegExp albumRegex = RegExp(r'imgur\.com(?:/a/|/gallery/)([a-zA-Z0-9]+)');
      final match = albumRegex.firstMatch(standardUrl);
      if (match != null) {
        // For albums, we just use the first image ID
        imgurId = match.group(1)!;
        return 'https://i.imgur.com/$imgurId.jpg';
      }
    }

    // Handle direct image links that already have extensions
    if (standardUrl.contains('i.imgur.com/')) {
      RegExp extensionRegex = RegExp(
        r'i\.imgur\.com/([a-zA-Z0-9]+)\.([a-zA-Z]+)',
      );
      final match = extensionRegex.firstMatch(standardUrl);
      if (match != null) {
        // Already a direct image link with extension, just return as is
        return standardUrl;
      } else {
        // Direct link without extension - add jpg extension
        RegExp idRegex = RegExp(r'i\.imgur\.com/([a-zA-Z0-9]+)');
        final idMatch = idRegex.firstMatch(standardUrl);
        if (idMatch != null) {
          imgurId = idMatch.group(1)!;
          return 'https://i.imgur.com/$imgurId.jpg';
        }
      }
    }

    // Handle regular imgur.com links
    RegExp regularRegex = RegExp(r'imgur\.com/([a-zA-Z0-9]+)');
    final regularMatch = regularRegex.firstMatch(standardUrl);
    if (regularMatch != null) {
      imgurId = regularMatch.group(1)!;

      // Remove any query parameters
      imgurId = imgurId.split('?').first;

      // Check if the ID already has an extension
      if (imgurId.contains('.')) {
        final parts = imgurId.split('.');
        imgurId = parts.first;
      }

      return 'https://i.imgur.com/$imgurId.jpg';
    }

    // If we can't process it, return the original URL
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collectionGroup('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No events found.', style: TextStyle(fontSize: 16)),
            );
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;
              final title = eventData['title'] ?? 'No Title';
              final category = eventData['category'] ?? 'No Category';
              final location = eventData['location'] ?? 'No Location';
              final bannerUrl = eventData['banner'] ?? '';
              final slots = eventData['total_slots'] ?? 0;

              // Handle date formatting
              final datetimestart =
                  eventData['datetimestart'] is Timestamp
                      ? (eventData['datetimestart'] as Timestamp).toDate()
                      : null;
              final datetimeend =
                  eventData['datetimeend'] is Timestamp
                      ? (eventData['datetimeend'] as Timestamp).toDate()
                      : null;

              final formattedStartDate =
                  datetimestart != null
                      ? DateFormat(
                        'MMM dd, yyyy - hh:mm a',
                      ).format(datetimestart)
                      : 'No date';
              final formattedEndDate =
                  datetimeend != null
                      ? DateFormat('MMM dd, yyyy - hh:mm a').format(datetimeend)
                      : 'No date';

              final status =
                  eventData['status'] is List &&
                          (eventData['status'] as List).isNotEmpty
                      ? (eventData['status'] as List)[0]
                      : 'hidden';

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EventDetailsPage(
                              eventData: eventData,
                              eventId: event.reference.id,
                              onUpdate: () => setState(() {}),
                            ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    bannerUrl.isNotEmpty
                                        ? Image.network(
                                          fixImgurLink(bannerUrl),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                              color: Colors.grey,
                                            );
                                          },
                                        )
                                        : const Icon(
                                          Icons.event,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                              ),
                            ),
                            // Status indicator
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                location,
                                style: TextStyle(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Category: $category',
                                style: TextStyle(color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Start: $formattedStartDate',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Slots: $slots',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Get the proper path to the event document
                                String? orgId;

                                // Try to extract organization ID from the reference path
                                if (event.reference.path.contains(
                                  '/organizations/',
                                )) {
                                  List<String> pathParts = event.reference.path
                                      .split('/');
                                  int orgIndex = pathParts.indexOf(
                                    'organizations',
                                  );
                                  if (orgIndex >= 0 &&
                                      orgIndex < pathParts.length - 1) {
                                    orgId = pathParts[orgIndex + 1];
                                  }
                                }
                                // If still null, try to extract from orguid field
                                else if (eventData['orguid'] is String) {
                                  String orgPath = eventData['orguid'];
                                  if (orgPath.startsWith('/organizations/')) {
                                    orgId = orgPath.split('/').last;
                                  }
                                }

                                // Show edit dialog with the event data and proper references
                                _showEditEventDialog(
                                  context,
                                  event.reference.id,
                                  eventData,
                                  orgId,
                                  event.reference,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(
                                  context,
                                  event.reference,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EventDetailsPage(
                                          eventData: eventData,
                                          eventId: event.reference.id,
                                          onUpdate: () => setState(() {}),
                                        ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: Colors.indigo.shade400,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'hidden':
        return Colors.grey;
      case 'done':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _pickImage() async {
    // Request permission first
    final status = await Permission.photos.request();

    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } else {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission to access gallery denied')),
        );
      }
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploading = true;
    });

    try {
      // Create a unique file name
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final reference = FirebaseStorage.instance
          .ref()
          .child('events')
          .child(fileName);

      // Upload file
      final uploadTask = reference.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() {});

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploading = false;
        _uploadedImageUrl = downloadUrl;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
      }
      return null;
    }
  }

  Widget _imageUploadWidget(
    StateSetter setDialogState,
    TextEditingController bannerController,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text('Event Banner:'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: bannerController,
                decoration: const InputDecoration(
                  labelText: 'Banner URL (or upload)',
                  hintText: 'Enter image URL or upload',
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await _pickImage();
                if (_selectedImage != null && mounted) {
                  setDialogState(() {}); // This updates the dialog state
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade400,
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_selectedImage != null)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 100,
              maxHeight: 100,
              minWidth: double.infinity,
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setDialogState(() {
                      _selectedImage = null;
                      _uploadedImageUrl = null;
                    });
                  },
                ),
              ],
            ),
          ),
        if (bannerController.text.isNotEmpty && _selectedImage == null)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 100,
              maxHeight: 100,
              minWidth: double.infinity,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                fixImgurLink(bannerController.text),
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  );
                },
              ),
            ),
          ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _showDateTimePicker({
    required BuildContext context,
    required bool isStartDate,
    required DateTime? initialDate,
    required TimeOfDay? initialTime,
    required Function(DateTime, TimeOfDay) onDateTimeSelected,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: isStartDate ? now : (initialDate ?? now),
      lastDate: DateTime(now.year + 5),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: initialTime ?? TimeOfDay.now(),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        onDateTimeSelected(selectedDateTime, time);
      }
    }
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    // Clear previous state
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _isUploading = false;
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
    });

    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController bannerController = TextEditingController();
    final TextEditingController totalSlotsController = TextEditingController();

    String selectedCategory = 'tech';
    List<String> selectedStatus = ['pending'];
    List<String> selectedType = ['academics'];
    List<String> selectedTags = [];

    final TextEditingController tagController = TextEditingController();
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();

    // Stream for organizations (for dropdown)
    final organizationsStream =
        FirebaseFirestore.instance
            .collection('organizations')
            .where('status', isEqualTo: 'active')
            .snapshots();
    String? selectedOrgId;
    String? selectedOrgName;

    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add New Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Organization Selection
                              StreamBuilder<QuerySnapshot>(
                                stream: organizationsStream,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  }

                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Text(
                                      'No organizations available',
                                    );
                                  }

                                  final organizations = snapshot.data!.docs;

                                  return DropdownButtonFormField<String>(
                                    value: selectedOrgId,
                                    decoration: const InputDecoration(
                                      labelText: 'Organization*',
                                    ),
                                    hint: const Text('Select Organization'),
                                    items:
                                        organizations.map((org) {
                                          final orgData =
                                              org.data()
                                                  as Map<String, dynamic>;
                                          final orgName =
                                              orgData['accronym'] ?? 'Unknown';
                                          return DropdownMenuItem<String>(
                                            value: org.id,
                                            child: Text(orgName),
                                            onTap: () {
                                              setDialogState(() {
                                                selectedOrgName = orgName;
                                              });
                                            },
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setDialogState(() {
                                          selectedOrgId = value;
                                        });
                                      }
                                    },
                                  );
                                },
                              ),

                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title*',
                                ),
                              ),

                              TextField(
                                controller: TextEditingController(
                                  text: selectedCategory,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Category*',
                                  hintText: 'Enter event category',
                                ),
                                onChanged: (value) {
                                  selectedCategory = value;
                                },
                              ),

                              // Date and Time Fields
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showDateTimePicker(
                                          context: context,
                                          isStartDate: true,
                                          initialDate: _selectedStartDate,
                                          initialTime: _selectedStartTime,
                                          onDateTimeSelected: (date, time) {
                                            setDialogState(() {
                                              _selectedStartDate = date;
                                              _selectedStartTime = time;
                                              startDateController
                                                  .text = DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(date);
                                            });
                                          },
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: startDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'Start Date & Time*',
                                            suffixIcon: Icon(
                                              Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showDateTimePicker(
                                          context: context,
                                          isStartDate: false,
                                          initialDate: _selectedEndDate,
                                          initialTime: _selectedEndTime,
                                          onDateTimeSelected: (date, time) {
                                            setDialogState(() {
                                              _selectedEndDate = date;
                                              _selectedEndTime = time;
                                              endDateController
                                                  .text = DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(date);
                                            });
                                          },
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: endDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'End Date & Time*',
                                            suffixIcon: Icon(
                                              Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description*',
                                ),
                                maxLines: 3,
                              ),

                              TextField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location*',
                                ),
                              ),

                              _imageUploadWidget(
                                setDialogState,
                                bannerController,
                              ),

                              TextField(
                                controller: totalSlotsController,
                                decoration: const InputDecoration(
                                  labelText: 'Total Slots*',
                                ),
                                keyboardType: TextInputType.number,
                              ),

                              // Status selection
                              const SizedBox(height: 16),
                              const Text('Status:'),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Hidden'),
                                    selected: selectedStatus.contains('hidden'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['hidden'];
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Pending'),
                                    selected: selectedStatus.contains(
                                      'pending',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['pending'];
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Done'),
                                    selected: selectedStatus.contains('done'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['done'];
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Type selection
                              const SizedBox(height: 16),
                              const Text('Type:'),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('Academics'),
                                    selected: selectedType.contains(
                                      'academics',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('academics');
                                        } else {
                                          selectedType.remove('academics');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Formation'),
                                    selected: selectedType.contains(
                                      'formation',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('formation');
                                        } else {
                                          selectedType.remove('formation');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Instruction'),
                                    selected: selectedType.contains(
                                      'instruction',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('instruction');
                                        } else {
                                          selectedType.remove('instruction');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Research'),
                                    selected: selectedType.contains('research'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('research');
                                        } else {
                                          selectedType.remove('research');
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Tags section
                              const SizedBox(height: 16),
                              const Text('Tags:'),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tagController,
                                      decoration: const InputDecoration(
                                        labelText: 'Add Tag',
                                        hintText: 'Enter a tag',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (tagController.text
                                          .trim()
                                          .isNotEmpty) {
                                        setDialogState(() {
                                          selectedTags.add(
                                            tagController.text.trim(),
                                          );
                                          tagController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children:
                                    selectedTags.map((tag) {
                                      return Chip(
                                        label: Text(tag),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onDeleted: () {
                                          setDialogState(() {
                                            selectedTags.remove(tag);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                            ),
                            onPressed: () async {
                              // Validate required fields
                              if (selectedOrgId == null ||
                                  titleController.text.trim().isEmpty ||
                                  locationController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty ||
                                  _selectedStartDate == null ||
                                  _selectedEndDate == null ||
                                  totalSlotsController.text.trim().isEmpty ||
                                  !RegExp(r'^\d+$').hasMatch(
                                    totalSlotsController.text.trim(),
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill in all required fields correctly',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text('Creating event...'),
                                        ],
                                      ),
                                    ),
                              );

                              try {
                                // Upload image if selected
                                String? imageUrl =
                                    _selectedImage != null
                                        ? await _uploadImage()
                                        : bannerController.text;

                                // Format dates properly for Firestore
                                final startDateTime = DateTime(
                                  _selectedStartDate!.year,
                                  _selectedStartDate!.month,
                                  _selectedStartDate!.day,
                                  _selectedStartTime!.hour,
                                  _selectedStartTime!.minute,
                                );

                                final endDateTime = DateTime(
                                  _selectedEndDate!.year,
                                  _selectedEndDate!.month,
                                  _selectedEndDate!.day,
                                  _selectedEndTime!.hour,
                                  _selectedEndTime!.minute,
                                );

                                // Create event document reference
                                final orgRef = FirebaseFirestore.instance
                                    .collection('organizations')
                                    .doc(selectedOrgId);

                                // Add event to the organization's events subcollection
                                await orgRef.collection('events').add({
                                  'title': titleController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'category': selectedCategory,
                                  'total_slots': int.parse(
                                    totalSlotsController.text.trim(),
                                  ),
                                  'registered_slots': 0,
                                  'status': selectedStatus,
                                  'type': selectedType,
                                  'tags': selectedTags,
                                  'datetimestart': startDateTime,
                                  'datetimeend': endDateTime,
                                  'banner': imageUrl ?? '',
                                  'orguid':
                                      orgRef, // Store the DocumentReference directly
                                  'orgname': selectedOrgName,
                                });

                                // Close loading dialog and form dialog
                                if (mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Close loading dialog
                                  Navigator.pop(context); // Close form dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Event created successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Close loading dialog
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to create event: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Create Event'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showEditEventDialog(
    BuildContext context,
    String eventId,
    Map<String, dynamic> eventData,
    String? orgId,
    DocumentReference eventRef,
  ) async {
    // Reset state for image selection
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _isUploading = false;
    });

    // Initialize controllers with existing data
    final TextEditingController titleController = TextEditingController(
      text: eventData['title'] ?? '',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: eventData['description'] ?? '',
    );
    final TextEditingController locationController = TextEditingController(
      text: eventData['location'] ?? '',
    );
    final TextEditingController bannerController = TextEditingController(
      text: eventData['banner'] ?? '',
    );
    final TextEditingController totalSlotsController = TextEditingController(
      text: eventData['total_slots']?.toString() ?? '0',
    );

    // Initialize date/time selections
    final DateTime? startDateTime =
        eventData['datetimestart'] is Timestamp
            ? (eventData['datetimestart'] as Timestamp).toDate()
            : null;
    final DateTime? endDateTime =
        eventData['datetimeend'] is Timestamp
            ? (eventData['datetimeend'] as Timestamp).toDate()
            : null;

    _selectedStartDate = startDateTime;
    _selectedEndDate = endDateTime;

    if (startDateTime != null) {
      _selectedStartTime = TimeOfDay(
        hour: startDateTime.hour,
        minute: startDateTime.minute,
      );
    }

    if (endDateTime != null) {
      _selectedEndTime = TimeOfDay(
        hour: endDateTime.hour,
        minute: endDateTime.minute,
      );
    }

    // Initialize controllers for dates
    final TextEditingController startDateController = TextEditingController(
      text:
          startDateTime != null
              ? DateFormat('MMM dd, yyyy - hh:mm a').format(startDateTime)
              : '',
    );
    final TextEditingController endDateController = TextEditingController(
      text:
          endDateTime != null
              ? DateFormat('MMM dd, yyyy - hh:mm a').format(endDateTime)
              : '',
    );

    // Initialize category, status, type selections
    String selectedCategory = eventData['category'] ?? 'tech';
    List<String> selectedStatus =
        eventData['status'] is List
            ? List<String>.from(eventData['status'])
            : ['pending'];
    List<String> selectedType =
        eventData['type'] is List
            ? List<String>.from(eventData['type'])
            : ['academics'];
    List<String> selectedTags =
        eventData['tags'] is List ? List<String>.from(eventData['tags']) : [];

    final TextEditingController tagController = TextEditingController();

    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Edit Event',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Organization info (read-only for edit)
                              if (orgId != null)
                                FutureBuilder<DocumentSnapshot>(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('organizations')
                                          .doc(orgId)
                                          .get(),
                                  builder: (context, snapshot) {
                                    String orgName = "Loading...";

                                    if (snapshot.hasData) {
                                      final orgData =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>?;
                                      orgName =
                                          orgData?['accronym'] ?? 'Unknown';
                                    } else if (snapshot.hasError) {
                                      orgName = "Error loading";
                                    }

                                    return TextField(
                                      controller: TextEditingController(
                                        text: orgName,
                                      ),
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Organization',
                                      ),
                                    );
                                  },
                                ),

                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Title*',
                                ),
                              ),

                              TextField(
                                controller: TextEditingController(
                                  text: selectedCategory,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Category*',
                                  hintText: 'Enter event category',
                                ),
                                onChanged: (value) {
                                  selectedCategory = value;
                                },
                              ),

                              // Date and Time Fields
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showDateTimePicker(
                                          context: context,
                                          isStartDate: true,
                                          initialDate: _selectedStartDate,
                                          initialTime: _selectedStartTime,
                                          onDateTimeSelected: (date, time) {
                                            setDialogState(() {
                                              _selectedStartDate = date;
                                              _selectedStartTime = time;
                                              startDateController
                                                  .text = DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(date);
                                            });
                                          },
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: startDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'Start Date & Time*',
                                            suffixIcon: Icon(
                                              Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        _showDateTimePicker(
                                          context: context,
                                          isStartDate: false,
                                          initialDate: _selectedEndDate,
                                          initialTime: _selectedEndTime,
                                          onDateTimeSelected: (date, time) {
                                            setDialogState(() {
                                              _selectedEndDate = date;
                                              _selectedEndTime = time;
                                              endDateController
                                                  .text = DateFormat(
                                                'MMM dd, yyyy - hh:mm a',
                                              ).format(date);
                                            });
                                          },
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: TextField(
                                          controller: endDateController,
                                          decoration: const InputDecoration(
                                            labelText: 'End Date & Time*',
                                            suffixIcon: Icon(
                                              Icons.calendar_today,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description*',
                                ),
                                maxLines: 3,
                              ),

                              TextField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location*',
                                ),
                              ),

                              _imageUploadWidget(
                                setDialogState,
                                bannerController,
                              ),

                              TextField(
                                controller: totalSlotsController,
                                decoration: const InputDecoration(
                                  labelText: 'Total Slots*',
                                ),
                                keyboardType: TextInputType.number,
                              ),

                              // Status selection
                              const SizedBox(height: 16),
                              const Text('Status:'),
                              Wrap(
                                spacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Hidden'),
                                    selected: selectedStatus.contains('hidden'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['hidden'];
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Pending'),
                                    selected: selectedStatus.contains(
                                      'pending',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['pending'];
                                      });
                                    },
                                  ),
                                  ChoiceChip(
                                    label: const Text('Done'),
                                    selected: selectedStatus.contains('done'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        selectedStatus = ['done'];
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Type selection
                              const SizedBox(height: 16),
                              const Text('Type:'),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilterChip(
                                    label: const Text('Academics'),
                                    selected: selectedType.contains(
                                      'academics',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('academics');
                                        } else {
                                          selectedType.remove('academics');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Formation'),
                                    selected: selectedType.contains(
                                      'formation',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('formation');
                                        } else {
                                          selectedType.remove('formation');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Instruction'),
                                    selected: selectedType.contains(
                                      'instruction',
                                    ),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('instruction');
                                        } else {
                                          selectedType.remove('instruction');
                                        }
                                      });
                                    },
                                  ),
                                  FilterChip(
                                    label: const Text('Research'),
                                    selected: selectedType.contains('research'),
                                    onSelected: (selected) {
                                      setDialogState(() {
                                        if (selected) {
                                          selectedType.add('research');
                                        } else {
                                          selectedType.remove('research');
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),

                              // Tags section
                              const SizedBox(height: 16),
                              const Text('Tags:'),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: tagController,
                                      decoration: const InputDecoration(
                                        labelText: 'Add Tag',
                                        hintText: 'Enter a tag',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      if (tagController.text
                                          .trim()
                                          .isNotEmpty) {
                                        setDialogState(() {
                                          selectedTags.add(
                                            tagController.text.trim(),
                                          );
                                          tagController.clear();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                children:
                                    selectedTags.map((tag) {
                                      return Chip(
                                        label: Text(tag),
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 18,
                                        ),
                                        onDeleted: () {
                                          setDialogState(() {
                                            selectedTags.remove(tag);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                            ),
                            onPressed: () async {
                              // Validate required fields
                              if (titleController.text.trim().isEmpty ||
                                  locationController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty ||
                                  _selectedStartDate == null ||
                                  _selectedEndDate == null ||
                                  totalSlotsController.text.trim().isEmpty ||
                                  !RegExp(r'^\d+$').hasMatch(
                                    totalSlotsController.text.trim(),
                                  )) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill in all required fields correctly',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (context) => const AlertDialog(
                                      content: Row(
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(width: 16),
                                          Text('Updating event...'),
                                        ],
                                      ),
                                    ),
                              );

                              try {
                                // Upload image if selected
                                String? imageUrl =
                                    _selectedImage != null
                                        ? await _uploadImage()
                                        : bannerController.text;

                                // Format dates properly for Firestore
                                final startDateTime = DateTime(
                                  _selectedStartDate!.year,
                                  _selectedStartDate!.month,
                                  _selectedStartDate!.day,
                                  _selectedStartTime!.hour,
                                  _selectedStartTime!.minute,
                                );

                                final endDateTime = DateTime(
                                  _selectedEndDate!.year,
                                  _selectedEndDate!.month,
                                  _selectedEndDate!.day,
                                  _selectedEndTime!.hour,
                                  _selectedEndTime!.minute,
                                );

                                // Update Firestore document
                                await eventRef.update({
                                  'title': titleController.text.trim(),
                                  'description':
                                      descriptionController.text.trim(),
                                  'location': locationController.text.trim(),
                                  'category': selectedCategory,
                                  'total_slots': int.parse(
                                    totalSlotsController.text.trim(),
                                  ),
                                  'status': selectedStatus,
                                  'type': selectedType,
                                  'tags': selectedTags,
                                  'datetimestart': startDateTime,
                                  'datetimeend': endDateTime,
                                  'banner': imageUrl ?? '',
                                });

                                // Close loading dialog and form dialog
                                if (mounted) {
                                  Navigator.pop(
                                    context,
                                  ); // Close loading dialog
                                  Navigator.pop(context); // Close form dialog
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Event updated successfully',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                // Close loading dialog
                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update event: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Update Event'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    DocumentReference eventRef,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Event'),
          content: const Text(
            'Are you sure you want to delete this event? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Show loading
                Navigator.pop(context); // Close the dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Deleting event...'),
                          ],
                        ),
                      ),
                );

                try {
                  // Delete the event document
                  await eventRef.delete();

                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context); // Close loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete event: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
