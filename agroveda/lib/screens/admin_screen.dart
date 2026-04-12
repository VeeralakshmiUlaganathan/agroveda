import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  // ================= STREAMS =================

  // 🔥 FIXED USER COUNT
  Stream<int> getTotalUsers() {
    return FirebaseFirestore.instance
        .collectionGroup("profile")
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getTotalScans() {
    return FirebaseFirestore.instance
        .collectionGroup("scan_history")
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<double> getAverageRating() {
    return FirebaseFirestore.instance
        .collection("feedback")
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc["rating"] ?? 0);
      }
      return total / snapshot.docs.length;
    });
  }

  // ================= TILE =================

  Widget statTile({
    required String title,
    required Stream stream,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _loadingTile(title, icon);
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A24),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.greenAccent),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  snapshot.data.toString(),
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loadingTile(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A24),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(height: 10),
          Text(title),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B16),
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [

            // 👤 USERS TILE
            statTile(
              title: "Users",
              stream: getTotalUsers(),
              icon: Icons.people,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersScreen()),
                );
              },
            ),

            // 📊 SCANS TILE
            statTile(
              title: "Scans",
              stream: getTotalScans(),
              icon: Icons.analytics,
            ),

            // ⭐ RATING TILE
            statTile(
              title: "Avg Rating",
              stream: getAverageRating(),
              icon: Icons.star,
            ),

            // 💬 FEEDBACK TILE
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FeedbackScreenAdmin()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feedback, color: Colors.greenAccent),
                    SizedBox(height: 10),
                    Text("Feedback"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// 👤 USERS SCREEN (FIXED)
//////////////////////////////////////////////////////////

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  // 🔥 DELETE USER FULLY
  Future<void> deleteUser(String uid) async {
    final firestore = FirebaseFirestore.instance;

    // Delete profile/info
    await firestore
        .collection("users")
        .doc(uid)
        .collection("profile")
        .doc("info")
        .delete()
        .catchError((_) {});

    // Delete root user doc
    await firestore.collection("users").doc(uid).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup("profile")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {

              final profileDoc = users[index];
              final userId = profileDoc.reference.parent.parent!.id;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("profile")
                    .doc("info")
                    .get(),
                builder: (context, snap) {

                  if (!snap.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final data =
                      snap.data!.data() as Map<String, dynamic>?;

                  final name = data?["name"] ?? "User";
                  final email = data?["email"] ?? "No Email";

                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                    subtitle: Text(email),

                    // 🔥 DELETE BUTTON
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {

                        await deleteUser(userId);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User deleted")),
                        );
                      },
                    ),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UserScansScreen(userId: userId),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// 🌿 USER SCANS
//////////////////////////////////////////////////////////

class UserScansScreen extends StatelessWidget {
  final String userId;

  const UserScansScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("User Scans")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("scan_history")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final scans = snapshot.data!.docs;

          return ListView(
            children: scans.map((doc) {
              final data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data["plant"] ?? ""),
                subtitle: Text(data["disease"] ?? ""),
                trailing: Text("${data["confidence"]}%"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

//////////////////////////////////////////////////////////
// 💬 FEEDBACK SCREEN
//////////////////////////////////////////////////////////

class FeedbackScreenAdmin extends StatelessWidget {
  const FeedbackScreenAdmin({super.key});

  String getSentiment(int rating) {
    if (rating >= 4) return "Positive";
    if (rating <= 2) return "Negative";
    return "Neutral";
  }

  Color getColor(String sentiment) {
    if (sentiment == "Positive") return Colors.green;
    if (sentiment == "Negative") return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Feedback")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("feedback")
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final feedbacks = snapshot.data!.docs;

          return ListView(
            children: feedbacks.map((doc) {

              final data = doc.data() as Map<String, dynamic>;
              final rating = (data["rating"] ?? 0).toInt();
              final sentiment = getSentiment(rating);

              return ListTile(
                title: Text(data["comment"] ?? ""),
                subtitle: Text("⭐ $rating"),
                trailing: Text(
                  sentiment,
                  style: TextStyle(color: getColor(sentiment)),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}