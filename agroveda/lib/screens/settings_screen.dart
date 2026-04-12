import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../main.dart';
import 'landing_screen.dart';
import 'feedback_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  bool darkMode =
      themeNotifier.value == ThemeMode.dark;

  String selectedLanguage =
      localeNotifier.value.languageCode;

  final passwordController =
      TextEditingController();

  Future<void> changePassword() async {
    try {
      await FirebaseAuth.instance.currentUser!
          .updatePassword(passwordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password Updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Re-login required to change password"),
        ),
      );
    }
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .delete();

    await FirebaseStorage.instance
        .ref()
        .child("profile_images")
        .child(user.uid)
        .delete()
        .catchError((_) {});

    await user.delete();

    Navigator.pop(context);
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Widget tile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF1E2A24),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.greenAccent),
        title: Text(title),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // THEME SWITCH
            tile(
              icon: Icons.dark_mode,
              title: "Dark Mode",
              trailing: Switch(
                value: darkMode,
                onChanged: (val) {
                  setState(() {
                    darkMode = val;
                  });
                  themeNotifier.value = val
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              ),
            ),

            // LANGUAGE
            tile(
              icon: Icons.language,
              title: "Language",
              trailing: DropdownButton<String>(
                value: selectedLanguage,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                      value: 'en',
                      child: Text("English")),
                  DropdownMenuItem(
                      value: 'ta',
                      child: Text("Tamil")),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedLanguage = value!;
                  });
                  localeNotifier.value =
                      Locale(value!);
                },
              ),
            ),

            // CHANGE PASSWORD
            tile(
              icon: Icons.lock,
              title: "Change Password",
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("New Password"),
                    content: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: "Enter new password",
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          changePassword();
                          Navigator.pop(context);
                        },
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                );
              },
            ),

            // ✅ FEEDBACK TILE (FIXED POSITION)
            tile(
              icon: Icons.feedback,
              title: "Send Feedback",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FeedbackScreen(),
                  ),
                );
              },
            ),

            const Spacer(),

            // LOGOUT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Logout"),
              ),
            ),

            const SizedBox(height: 10),

            // DELETE ACCOUNT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Delete Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}