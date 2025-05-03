import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'organizationdetails.dart';

class OrganizationsPage extends StatefulWidget {
  const OrganizationsPage({Key? key}) : super(key: key);

  @override
  State<OrganizationsPage> createState() => _OrganizationsPageState();
}

class _OrganizationsPageState extends State<OrganizationsPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadedImageUrl;

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
        // This might not be ideal for all cases, but it's a simple approach
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
        title: const Text('Organizations'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade400,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddOrganizationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('organizations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No organizations found.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final organizations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: organizations.length,
            itemBuilder: (context, index) {
              final organization = organizations[index];
              final organizationData =
                  organization.data() as Map<String, dynamic>;
              final accronym = organizationData['accronym'] ?? 'No Accronym';
              final category = organizationData['category'] ?? 'No Category';
              final email = organizationData['email'] ?? 'No Email';
              final bannerUrl = organizationData['banner'] ?? '';
              final isVisible = organizationData['status'] == 'active';

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
                            (context) => OrganizationDetailsPage(
                              organizationData: organizationData,
                              organizationId: organization.id,
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
                                          Icons.group,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                              ),
                            ),
                            if (!isVisible)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.visibility_off,
                                    color: Colors.white,
                                    size: 16,
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
                                accronym,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                email,
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
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditOrganizationDialog(
                                  context,
                                  organization.id,
                                  organizationData,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(
                                  context,
                                  organization.id,
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                isVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isVisible ? Colors.green : Colors.grey,
                              ),
                              onPressed: () {
                                _toggleVisibility(
                                  organization.id,
                                  isVisible ? 'deactivated' : 'active',
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
        onPressed: () => _showAddOrganizationDialog(context),
        backgroundColor: Colors.indigo.shade400,
        child: const Icon(Icons.add),
      ),
    );
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
      final fileName =
          'organization_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final reference = FirebaseStorage.instance
          .ref()
          .child('organizations')
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
        const Text('Organization Banner:'),
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
            // Add constraints to ensure layout stability
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
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Future<void> _showAddOrganizationDialog(BuildContext context) async {
    // Clear previous state
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _isUploading = false;
    });

    final TextEditingController accronymController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController bannerController = TextEditingController();
    final TextEditingController logoController = TextEditingController();
    final TextEditingController facebookController = TextEditingController();
    final TextEditingController mobileController = TextEditingController();
    String selectedCategory = 'academic';
    String selectedStatus = 'active';

    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add New Organization',
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
                              TextField(
                                controller: accronymController,
                                decoration: const InputDecoration(
                                  labelText: 'Acronym*',
                                ),
                              ),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name*',
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category*',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'academic',
                                    child: Text('Academic'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sports',
                                    child: Text('Sports'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cluster',
                                    child: Text('Cluster'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'health',
                                    child: Text('Health'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description*',
                                ),
                                maxLines: 3,
                              ),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email*',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              _imageUploadWidget(
                                setDialogState,
                                bannerController,
                              ),
                              TextField(
                                controller: logoController,
                                decoration: const InputDecoration(
                                  labelText: 'Logo URL (imgur)',
                                ),
                              ),
                              TextField(
                                controller: facebookController,
                                decoration: const InputDecoration(
                                  labelText: 'Facebook URL',
                                ),
                              ),
                              TextField(
                                controller: mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                ),
                                keyboardType: TextInputType.phone,
                              ),

                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status*',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'deactivated',
                                    child: Text('Deactivated'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (accronymController.text.isEmpty ||
                                  nameController.text.isEmpty ||
                                  emailController.text.isEmpty ||
                                  descriptionController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields',
                                    ),
                                  ),
                                );
                                return;
                              }

                              String? imageUrl = bannerController.text;

                              // If there's a selected image, upload it
                              if (_selectedImage != null) {
                                setDialogState(() {
                                  _isUploading = true;
                                });

                                imageUrl = await _uploadImage();

                                setDialogState(() {
                                  _isUploading = false;
                                });

                                if (imageUrl == null) return; // Upload failed
                              }

                              _addOrganization({
                                'accronym': accronymController.text,
                                'name': nameController.text,
                                'category': selectedCategory,
                                'description': descriptionController.text,
                                'email': emailController.text,
                                'banner': imageUrl,
                                'logo': logoController.text,
                                'facebook': facebookController.text,
                                'mobile': mobileController.text,

                                'status': selectedStatus,
                              });

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                            ),
                            child: const Text('Save'),
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

  String ensureString(dynamic value) {
    if (value == null) {
      return '';
    } else if (value is List) {
      // If the value is a list, join its elements
      return value.join(', ');
    } else {
      // Otherwise convert to string
      return value.toString();
    }
  }

  Future<void> _showEditOrganizationDialog(
    BuildContext context,
    String orgId,
    Map<String, dynamic> orgData,
  ) async {
    // Clear previous state
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
      _isUploading = false;
    });

    final TextEditingController accronymController = TextEditingController(
      text: ensureString(orgData['accronym']),
    );
    final TextEditingController nameController = TextEditingController(
      text: ensureString(orgData['name']),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: ensureString(orgData['description']),
    );
    final TextEditingController emailController = TextEditingController(
      text: ensureString(orgData['email']),
    );
    final TextEditingController bannerController = TextEditingController(
      text: ensureString(orgData['banner']),
    );
    final TextEditingController logoController = TextEditingController(
      text: ensureString(orgData['logo']),
    );
    final TextEditingController facebookController = TextEditingController(
      text: ensureString(orgData['facebook']),
    );
    final TextEditingController mobileController = TextEditingController(
      text: ensureString(orgData['mobile']),
    );

    // Get the category value from the data, ensuring it's one of the valid options
    String rawCategory = ensureString(orgData['category']);
    String selectedCategory =
        ['academic', 'sports', 'cluster', 'health'].contains(rawCategory)
            ? rawCategory
            : 'academic';

    // Get the status value from the data, ensuring it's one of the valid options
    String rawStatus = ensureString(orgData['status']);
    String selectedStatus =
        ['active', 'deactivated'].contains(rawStatus) ? rawStatus : 'active';

    if (!mounted) return;

    return showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Edit Organization',
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
                              TextField(
                                controller: accronymController,
                                decoration: const InputDecoration(
                                  labelText: 'Acronym*',
                                ),
                              ),
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Name*',
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category*',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'academic',
                                    child: Text('Academic'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sports',
                                    child: Text('Sports'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cluster',
                                    child: Text('Cluster'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'health',
                                    child: Text('Health'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedCategory = value;
                                    });
                                  }
                                },
                              ),
                              TextField(
                                controller: descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description*',
                                ),
                                maxLines: 3,
                              ),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email*',
                                ),
                                keyboardType: TextInputType.emailAddress,
                              ),
                              _imageUploadWidget(
                                setDialogState,
                                bannerController,
                              ),
                              if (bannerController.text.isNotEmpty &&
                                  _selectedImage == null)
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
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
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
                              TextField(
                                controller: logoController,
                                decoration: const InputDecoration(
                                  labelText: 'Logo URL (imgur)',
                                ),
                              ),
                              TextField(
                                controller: facebookController,
                                decoration: const InputDecoration(
                                  labelText: 'Facebook URL',
                                ),
                              ),
                              TextField(
                                controller: mobileController,
                                decoration: const InputDecoration(
                                  labelText: 'Mobile Number',
                                ),
                                keyboardType: TextInputType.phone,
                              ),

                              DropdownButtonFormField<String>(
                                value: selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Status*',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'active',
                                    child: Text('Active'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'deactivated',
                                    child: Text('Deactivated'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedStatus = value;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (accronymController.text.isEmpty ||
                                  nameController.text.isEmpty ||
                                  emailController.text.isEmpty ||
                                  descriptionController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill all required fields',
                                    ),
                                  ),
                                );
                                return;
                              }

                              String? imageUrl = bannerController.text;

                              // If there's a selected image, upload it
                              if (_selectedImage != null) {
                                setDialogState(() {
                                  _isUploading = true;
                                });

                                imageUrl = await _uploadImage();

                                setDialogState(() {
                                  _isUploading = false;
                                });

                                if (imageUrl == null) return; // Upload failed
                              }

                              await _updateOrganization(orgId, {
                                'accronym': accronymController.text,
                                'name': nameController.text,
                                'category': selectedCategory,
                                'description': descriptionController.text,
                                'email': emailController.text,
                                'banner': imageUrl,
                                'logo': logoController.text,
                                'facebook': facebookController.text,
                                'mobile': mobileController.text,
                                'status': selectedStatus,
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade400,
                            ),
                            child: const Text('Update'),
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
    String orgId,
  ) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Organization'),
            content: const Text(
              'Are you sure you want to delete this organization? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _deleteOrganization(orgId);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _addOrganization(Map<String, dynamic> orgData) async {
    try {
      await FirebaseFirestore.instance.collection('organizations').add(orgData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add organization')),
        );
      }
    }
  }

  Future<void> _updateOrganization(
    String orgId,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .update(updatedData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update organization: $e')),
        );
      }
    }
  }

  Future<void> _deleteOrganization(String orgId) async {
    try {
      // First, get the organization data to find image URLs
      final orgDoc =
          await FirebaseFirestore.instance
              .collection('organizations')
              .doc(orgId)
              .get();

      if (orgDoc.exists) {
        final orgData = orgDoc.data() as Map<String, dynamic>;

        // Delete the document
        await FirebaseFirestore.instance
            .collection('organizations')
            .doc(orgId)
            .delete();

        // Check if there are Firebase Storage images to delete
        final bannerUrl = orgData['banner'] as String?;
        if (bannerUrl != null &&
            bannerUrl.isNotEmpty &&
            bannerUrl.contains('firebase')) {
          try {
            // Extract the path from the URL
            final ref = FirebaseStorage.instance.refFromURL(bannerUrl);
            await ref.delete();
          } catch (storageError) {
            // Log error but continue with operation
            debugPrint('Failed to delete image: $storageError');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete organization: $e')),
        );
      }
    }
  }

  Future<void> _toggleVisibility(String orgId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('organizations')
          .doc(orgId)
          .update({'status': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'active'
                  ? 'Organization activated'
                  : 'Organization deactivated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update organization status: $e')),
        );
      }
    }
  }
}
