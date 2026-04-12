import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {

  double rating = 3;
  final commentController = TextEditingController();
  bool isLoading = false;

  Future<void> submitFeedback() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    if (commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter feedback")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {

      // Fetch user name
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("profile")
          .doc("info")
          .get();

      String name = doc.exists ? doc["name"] ?? "User" : "User";

      await FirebaseFirestore.instance.collection("feedback").add({
        "userId": user.uid,
        "name": name,
        "rating": rating,
        "comment": commentController.text,
        "timestamp": Timestamp.now(),
      });

      setState(() {
        isLoading = false;
        rating = 3;
        commentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully")),
      );

      Navigator.pop(context);

    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error submitting feedback")),
      );
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      icon: Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
      ),
      onPressed: () {
        setState(() {
          rating = index + 1;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Feedback"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const Text(
              "Rate Your Experience",
              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index)),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Write your feedback...",
                filled: true,
                fillColor: const Color(0xFF1E2A24),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Submit Feedback"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}