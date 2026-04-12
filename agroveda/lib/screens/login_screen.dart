import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;
  bool obscurePassword = true;
  bool showResendButton = false;

  bool showPasswordRules = false;

  // PASSWORD VALIDATION STATES
  bool hasUpper = false;
  bool hasLower = false;
  bool hasNumber = false;
  bool hasSpecial = false;
  bool hasMinLength = false;

  void validatePassword(String password) {
    setState(() {
      showPasswordRules = true;
      hasUpper = password.contains(RegExp(r'[A-Z]'));
      hasLower = password.contains(RegExp(r'[a-z]'));
      hasNumber = password.contains(RegExp(r'[0-9]'));
      hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMinLength = password.length >= 8;
    });
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password reset link sent")),
    );
  }

  Future<void> resendVerification() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification email resent")),
      );
    }
  }

  Future<void> signInWithEmail() async {

    setState(() => isLoading = true);

    try {

      if (isLogin) {

        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await userCredential.user!.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (!user!.emailVerified) {

          await FirebaseAuth.instance.signOut();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Please verify your email (check spam folder)"),
              backgroundColor: Colors.orange,
            ),
          );

          setState(() {
            showResendButton = true;
            isLoading = false;
          });

          return;
        }

        Navigator.pop(context, true);

      } else {

        if (!(hasUpper && hasLower && hasNumber && hasSpecial && hasMinLength)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Password does not meet requirements"),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isLoading = false);
          return;
        }

        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await userCredential.user!.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent (check spam folder)"),
            backgroundColor: Colors.green,
          ),
        );

        await FirebaseAuth.instance.signOut();

        setState(() {
          showResendButton = true;
          isLogin = true;
        });
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> signInWithGoogle() async {

    final GoogleSignInAccount? googleUser =
        await GoogleSignIn().signIn();

    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    Navigator.pop(context, true);
  }

  Widget rule(String text, bool valid) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.cancel,
          color: valid ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: valid ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Stack(
        children: [

          // BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D1B16), Color(0xFF1E2A24)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [

                    const Text(
                      "AGROVEDA",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔥 GOOGLE BUTTON (OFFICIAL STYLE)
                    GestureDetector(
                      onTap: signInWithGoogle,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.g_mobiledata, size: 28, color: Colors.black),
                            SizedBox(width: 10),
                            Text(
                              "Continue with Google",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(hintText: "Email"),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      onChanged: validatePassword,
                      onTap: () {
                        setState(() {
                          showPasswordRules = true;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (!isLogin && showPasswordRules)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2A24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            rule("At least 8 characters", hasMinLength),
                            rule("1 Uppercase letter", hasUpper),
                            rule("1 Lowercase letter", hasLower),
                            rule("1 Number", hasNumber),
                            rule("1 Special character", hasSpecial),
                          ],
                        ),
                      ),

                    if (isLogin)
                      TextButton(
                        onPressed: resetPassword,
                        child: const Text("Forgot Password?"),
                      ),

                    if (showResendButton)
                      TextButton(
                        onPressed: resendVerification,
                        child: const Text("Resend Verification"),
                      ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: isLoading ? null : signInWithEmail,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(isLogin ? "LOGIN" : "REGISTER"),
                    ),

                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                          showPasswordRules = false;
                        });
                      },
                      child: Text(
                        isLogin
                            ? "New user? Register"
                            : "Already have account? Login",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}