import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {

  File? _image;
  bool _loading = false;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Selected: ${pickedFile.name}")),
      );

      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _predictDisease() async {
    if (_image == null) return;

    setState(() => _loading = true);

    try {
      var response = await ApiService.predictDisease(_image!);
      print("API RESPONSE: $response");
      if (!mounted) return;

      setState(() => _loading = false);

      if (response == null) {
        _showMessage("No response from server");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("scan_history")
        .add({
      "plant": response["plant"],
      "disease": (response["disease"] ?? "").toString().isEmpty
          ? "Unknown"
          : response["disease"],
      "confidence": response["confidence"] ?? 0,
      "recommendation": response["recommendation"] ?? {},
      "imageUrl": "",
      "timestamp": Timestamp.now(),
    });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: _image!,
            result: response,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);
      _showMessage("Something went wrong");
    }
  }

  void _showMessage(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("AGROVEDA"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildSplitButtons() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.green,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.camera),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Camera",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
          Container(width: 1, color: Colors.white),
          Expanded(
            child: InkWell(
              onTap: () => _pickImage(ImageSource.gallery),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo, color: Colors.white),
                    SizedBox(width: 8),
                    Text("Gallery",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image == null) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 25),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.file(
            _image!,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loading ? null : _predictDisease,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("Analyze Leaf"),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () {
            setState(() => _image = null);
          },
          child: const Text("Choose Another Image",
              style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Leaf"),
        centerTitle: true,
      ),
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A24),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco,
                    size: 70, color: Colors.greenAccent),
                const SizedBox(height: 20),
                const Text("Scan Leaf",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 25),
                _buildSplitButtons(),
                _buildImagePreview(),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(
                        color: Colors.greenAccent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}