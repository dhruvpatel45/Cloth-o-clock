import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'email.dart';
import 'phone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  String name;
  String email;
  String phone;
  String? imagePath;
  final String userId;

  EditProfileScreen({
    required this.name,
    required this.email,
    required this.phone,
    this.imagePath,
    required this.userId,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profileImage;
  String name = "";
  String email = "";
  String phone = "";
  String? userId;
  String? profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _deleteProfileImage() async {
    final uri = Uri.parse("http://192.168.205.252/flutter_api/upload_image.php");

    try {
      final response = await http.post(
        uri,
        body: {
          'user_id': userId!,
          'action': 'delete',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            profileImageUrl = null;
            _profileImage = null;
          });
          _showSuccessMessage('Profile image deleted successfully.');
        } else {
          _showErrorMessage(data['message']);
        }
      } else {
        _showErrorMessage('Failed to delete profile image.');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }


  Future<void> _fetchUserDetails() async {
    final String apiUrl = 'http://192.168.205.252/flutter_api/get_user_details.php';

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('userId');

      if (userId == null) {
        _showErrorMessage('User not logged in.');
        return;
      }

      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(requestBody),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = jsonDecode(response.body);

        if (data != null && data['status'] == 'success') {
          setState(() {
            name = data['full_name'] ?? 'N/A';
            email = data['email'] ?? 'N/A';
            phone = data['contact_number'] ?? 'N/A';
            // ✅ Correct URL Handling
            if (data['profile_image'] != null && data['profile_image'].startsWith('http')) {
              profileImageUrl = data['profile_image']; // Use full URL if available
            } else if (data['profile_image'] != null) {
              profileImageUrl = "http://192.168.205.252/flutter_api/" + data['profile_image'];
            } else {
              profileImageUrl = null;
            }

          });
        } else {
          _showErrorMessage(data?['message'] ?? 'Failed to fetch user details.');
        }
      } else {
        _showErrorMessage('Error: ${response.statusCode}. Please try again later.');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });

      // ✅ Upload image after selecting it
      String? imageUrl = await _uploadImage();
      if (imageUrl != null) {
        setState(() {
          profileImageUrl = imageUrl; // ✅ Update image URL after upload
        });
      }
    }
  }


  Future<String?> _uploadImage() async {
    final uri = Uri.parse("http://192.168.205.252/flutter_api/upload_image.php");
    var request = http.MultipartRequest("POST", uri);

    if (_profileImage != null) {
      var file = await http.MultipartFile.fromPath("profile_image", _profileImage!.path);
      request.files.add(file);
      request.fields['user_id'] = userId!;
      request.fields['action'] = 'upload'; // ✅ Correct action name
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    print('Response: $responseData');

    if (response.statusCode == 200) {
      final data = jsonDecode(responseData);
      if (data['status'] == 'success') {
        _showSuccessMessage("Profile image uploaded successfully.");
        return data['image_url']; // ✅ Return the new image URL
      } else {
        _showErrorMessage('Error uploading image: ${data['message']}');
        return null;
      }
    } else {
      _showErrorMessage('Error uploading image');
      return null;
    }
  }

  void _saveChanges() async {
    String updateUrl = "http://192.168.205.252/flutter_api/update_profile.php";

    try {
      final response = await http.post(
        Uri.parse(updateUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId!,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _fetchUserDetails();
          _showSuccessMessage("Profile updated successfully.");
        } else {
          _showErrorMessage(data['message']);
        }
      } else {
        _showErrorMessage('Failed to update profile. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred while updating name.');
    }
  }

  void _updateName(String newName) {
    setState(() {
      name = newName;
    });
  }

  void _updateEmail(String newEmail) {
    setState(() {
      email = newEmail;
    });
  }

  void _updatePhone(String newPhone) {
    setState(() {
      phone = newPhone;
    });
    _showSuccessMessage("Phone number updated successfully.");
  }

  Future<void> _showNameUpdateDialog() async {
    TextEditingController _nameController = TextEditingController(text: name);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Name"),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Enter new name"),
          ),
          actions: [
            FloatingActionButton.extended(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  _updateName(_nameController.text);
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Submit', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.deepPurple,
            ),
          ],
        );
      },
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(15),
          height: 210,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Profile Image'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfileImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final shadowColor = isDarkMode ? Colors.transparent : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('Edit Profile', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      backgroundColor: bgColor,
      body: Container(
        color: bgColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : profileImageUrl != null && profileImageUrl!.startsWith("http")
                        ? NetworkImage(profileImageUrl!) as ImageProvider
                        : null,
                    child: _profileImage == null &&
                        (profileImageUrl == null || profileImageUrl!.isEmpty)
                        ? Icon(Icons.person, size: 80, color: textColor)
                        : null,
                  ),
                  FloatingActionButton(
                    backgroundColor: Colors.white,
                    mini: true,
                    child: const Icon(Icons.camera_alt, color: Colors.deepPurple),
                    onPressed: _showImagePickerDialog,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildEditableField("Full Name", name, _showNameUpdateDialog),
                    const SizedBox(height: 20),
                    _buildEditableField("Email", email, () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeEmailScreen(currentEmail: email),
                        ),
                      );
                      if (result != null) _updateEmail(result);
                    }),
                    const SizedBox(height: 20),
                    _buildEditableField("Phone Number", phone, () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangePhoneScreen(currentPhone: phone),
                        ),
                      );
                      if (result != null) _updatePhone(result);
                    }),
                    const SizedBox(height: 30),
                    FloatingActionButton.extended(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Save Changes', style: TextStyle(color: Colors.white)),
                      backgroundColor: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, String value, VoidCallback onEdit) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        boxShadow: [
          if (!isDarkMode) const BoxShadow(color: Colors.grey, blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('$label: $value',
              style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.deepPurple),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
