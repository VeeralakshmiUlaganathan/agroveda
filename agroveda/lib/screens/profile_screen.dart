import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'settings_screen.dart';
import 'admin_screen.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final user = FirebaseAuth.instance.currentUser;

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final farmSizeController = TextEditingController();
  final cropController = TextEditingController();

  bool _editMode = false;
  bool _loading = false;

  String? photoUrl;
  File? _newImage;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("profile")
        .doc("info")
        .get();

    if (doc.exists) {

      final data = doc.data()!;

      nameController.text = data["name"] ?? "";
      phoneController.text = data["phone"] ?? "";
      locationController.text = data["location"] ?? "";
      farmSizeController.text = data["farmSize"] ?? "";
      cropController.text = data["mainCrop"] ?? "";
      photoUrl = data["photoUrl"];

      _editMode = false;

    } else {

      _editMode = true;

    }

    setState(() {});
  }



  /// PICK IMAGE + CROP
  // ONLY showing modified part inside your existing file

  /// PICK IMAGE + CROP
  Future<void> pickImage() async {

    // 🔥 FIX: Auto-enable edit mode
    if (!_editMode) {
      setState(() {
        _editMode = true;
      });
    }

    final picked =
        await _picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [

        AndroidUiSettings(
          toolbarTitle: "Crop Profile Photo",
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),

        IOSUiSettings(
          title: "Crop Profile Photo",
          aspectRatioLockEnabled: true,
        )
      ],
    );

    if (cropped == null) return;

    setState(() {
      _newImage = File(cropped.path);
    });

    // 🔥 OPTIONAL AUTO SAVE (SAFE ADD)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image selected. Press save to upload.")),
    );
  }

  /// UPLOAD IMAGE
  Future<String?> uploadImage() async {

    if (_newImage == null) return photoUrl;

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images")
        .child("${user!.uid}.jpg");

    await ref.putFile(_newImage!);

    return await ref.getDownloadURL();
  }

  /// DELETE PHOTO
  Future<void> deletePhoto() async {

    try {

      await FirebaseStorage.instance
          .ref("profile_images/${user!.uid}.jpg")
          .delete();

    } catch (_) {}

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("profile")
        .doc("info")
        .update({"photoUrl": null});

    setState(() {

      photoUrl = null;
      _newImage = null;

    });
  }

  /// SAVE PROFILE
  Future<void> saveProfile() async {

    setState(() => _loading = true);

    String? imageUrl = await uploadImage();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("profile")
        .doc("info")
        .set({

      "name": nameController.text,
      "phone": phoneController.text,
      "location": locationController.text,
      "farmSize": farmSizeController.text,
      "mainCrop": cropController.text,
      "photoUrl": imageUrl,
      "email": user!.email,

    });

    setState(() {

      photoUrl = imageUrl;
      _editMode = false;
      _loading = false;

    });
  }

  Widget topButton(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A24),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.4),
            blurRadius: 8,
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.greenAccent),
        onPressed: onTap,
      ),
    );
  }

  Widget infoTile(IconData icon, String value) {

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [

          Icon(icon, color: Colors.greenAccent),

          const SizedBox(width: 15),

          Expanded(
            child: Text(
              value.isEmpty ? "Not Provided" : value,
              style: const TextStyle(fontSize: 15),
            ),
          ),

        ],
      ),
    );
  }

  Widget editableField(
      IconData icon,
      String label,
      TextEditingController controller) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.greenAccent),
          labelText: label,
          filled: true,
          fillColor: const Color(0xFF1E2A24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: Stack(
        children: [

          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(

              padding: const EdgeInsets.all(22),

              child: Column(
                children: [

                  /// TOP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      const Text(
                        "Profile",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [

                          topButton(
                            Icons.settings,
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const SettingsScreen(),
                                ),
                              );
                            },
                          ),

                          topButton(
                            _editMode
                                ? Icons.check_circle
                                : Icons.edit,
                            () {

                              if (_editMode) {
                                saveProfile();
                              } else {
                                setState(() {
                                  _editMode = true;
                                });
                              }

                            },
                          ),

                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 50),

                  /// PROFILE CARD
                  Container(

                    padding: const EdgeInsets.all(26),

                    decoration: BoxDecoration(
                      color: const Color(0xFF121A16),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),

                    child: Column(
                      children: [

                        GestureDetector(

                          onTap: pickImage,

                          child: Stack(
                            children: [

                              CircleAvatar(
                                radius: 65,
                                backgroundColor:
                                    const Color(0xFF1E2A24),

                                backgroundImage: _newImage != null
                                    ? FileImage(_newImage!)
                                    : (photoUrl != null
                                        ? NetworkImage(photoUrl!)
                                        : null) as ImageProvider?,

                                child: (_newImage == null &&
                                        photoUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        size: 55,
                                        color:
                                            Colors.greenAccent,
                                      )
                                    : null,
                              ),

                              if (_editMode)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding:
                                        const EdgeInsets.all(6),
                                    decoration:
                                        const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (_editMode &&
                            (photoUrl != null ||
                                _newImage != null))
                          TextButton.icon(
                            onPressed: deletePhoto,
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            label: const Text(
                              "Delete Photo",
                              style:
                                  TextStyle(color: Colors.red),
                            ),
                          ),

                        const SizedBox(height: 18),

                        Text(
                          nameController.text.isEmpty
                              ? "Farmer"
                              : nameController.text,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          user?.email ?? "",
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 35),

                        if (_editMode) ...[

                          editableField(Icons.person,
                              "Name", nameController),

                          editableField(Icons.phone,
                              "Phone", phoneController),

                          editableField(Icons.location_on,
                              "Location", locationController),

                          editableField(Icons.agriculture,
                              "Farm Size", farmSizeController),

                          editableField(Icons.grass,
                              "Main Crop", cropController),

                        ] else ...[

                          infoTile(Icons.phone,
                              phoneController.text),

                          infoTile(Icons.location_on,
                              locationController.text),

                          infoTile(Icons.agriculture,
                              farmSizeController.text),

                          infoTile(Icons.grass,
                              cropController.text),

                        ],

                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {

                            final user = FirebaseAuth.instance.currentUser;

                            final doc = await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user!.uid)
                                .get();

                            final data = doc.data();

                            if (data != null && data["role"] == "admin") {

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminScreen(),
                                ),
                              );

                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Access Denied")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text("Admin Dashboard"),
                        ),

                        if (_loading)
                          const CircularProgressIndicator(),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}