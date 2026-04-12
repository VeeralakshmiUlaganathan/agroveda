import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pdf_service.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final Map<String, dynamic> result;

  const ResultScreen({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  double confidence = 0;
  String userName = "User";

  @override
  void initState() {
    super.initState();

    confidence =
        (widget.result["confidence"] as num?)?.toDouble() ?? 0;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animation = Tween<double>(
      begin: 0,
      end: confidence / 100,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    fetchUserName(); // 🔥 FETCH USER NAME
  }

  Future<void> fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profile")
          .doc("info")
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc["name"] ?? "User";
        });
      }
    }
  }

  Color getConfidenceColor() {
    if (confidence < 50) return Colors.redAccent;
    if (confidence < 75) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  String getSeverity() {
    if (confidence < 50) return "Mild";
    if (confidence < 75) return "Moderate";
    return "Severe";
  }

  // 🔥 BIG PROFESSIONAL EXPLANATION
  String aiSummary(Map rec) {
    return """
The system has analyzed the uploaded plant leaf image using a trained Convolutional Neural Network (CNN) model and identified the condition as "${widget.result["disease"] ?? "Unknown"}".

This disease is primarily caused by "${rec["pathogen"] ?? "unknown pathogens"}", which can spread rapidly under favorable environmental conditions such as high humidity, poor air circulation, or improper irrigation practices.

Based on the prediction confidence of ${confidence.toStringAsFixed(2)}%, the severity level is categorized as "${getSeverity()}". Immediate action is recommended to prevent further spread and crop damage.

For treatment, the use of "${rec["chemical"] ?? "recommended chemical"}" is advised with a dosage of "${rec["dosage"] ?? "as prescribed"}". This should be applied "${rec["frequency"] ?? "periodically"}" to ensure effective disease control.

Additionally, organic alternatives such as "${rec["organic"] ?? "natural solutions"}" can be considered for environmentally friendly farming practices.

Preventive measures play a crucial role in avoiding recurrence. Farmers are advised to maintain proper field hygiene, ensure optimal watering practices, monitor crops regularly, and adopt crop rotation techniques.

Early detection combined with timely intervention significantly improves crop health, yield quality, and overall agricultural productivity.
""";
  }

  @override
  Widget build(BuildContext context) {

    final rec = widget.result["recommendation"] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Diagnosis Report"),
        centerTitle: true,
        actions: [

          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              PdfService.generateReport(
                widget.image,
                widget.result,
                userName,
                aiSummary(rec),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              PdfService.generateReport(
                widget.image,
                widget.result,
                userName,
                aiSummary(rec),
              );
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 👤 USER NAME
            Text(
              "Farmer: $userName",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.greenAccent,
              ),
            ),

            const SizedBox(height: 15),

            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(widget.image),
            ),

            const SizedBox(height: 25),

            Text("Plant Type",
                style: TextStyle(color: Colors.grey.shade400)),
            Text(widget.result["plant"] ?? "Unknown",
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            Text("Disease",
                style: TextStyle(color: Colors.grey.shade400)),
            Text(
              widget.result["status"] == "healthy"
                  ? "Healthy Leaf"
                  : widget.result["disease"] ?? "Unknown",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.result["status"] == "healthy"
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Confidence: ${confidence.toStringAsFixed(2)}%",
            ),

            const SizedBox(height: 25),

            LinearProgressIndicator(
              value: confidence / 100,
              minHeight: 12,
              color: getConfidenceColor(),
            ),

            const SizedBox(height: 30),

            // 🌿 TREATMENT
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Treatment Details",
                    style: TextStyle(
                        fontWeight: FontWeight.bold),
                  ),

                  const Divider(),

                  detailRow("Pathogen", rec["pathogen"]),
                  detailRow("Chemical", rec["chemical"]),
                  detailRow("Dosage", rec["dosage"]),
                  detailRow("Frequency", rec["frequency"]),
                  detailRow("Organic", rec["organic"]),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                PdfService.generateReport(
                  widget.image,
                  widget.result,
                  userName,
                  aiSummary(rec),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Download Report"),
            ),

            const SizedBox(height: 25),

            // 🔥 BIG EXPLANATION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A24),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Detailed Analysis",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent),
                  ),

                  const SizedBox(height: 10),

                  Text(aiSummary(rec)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget detailRow(String label, dynamic value) {
    if (value == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }
}