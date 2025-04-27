import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ), // Increased font size
                ),
                const SizedBox(height: 6),
                const Text(
                  "Hi, Welcome back 👋",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ), // Increased font size
                ),
                const SizedBox(height: 24),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await signInWithGoogle(context);
                    },
                    icon: Image.asset(
                      'assets/images/google.png',
                      width: 20,
                      height: 20,
                    ),
                    label: const Text(
                      'Login with Google',
                      style: TextStyle(fontSize: 16),
                    ), // Increased font size
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                const Text(
                  "or Login with Email",
                  style: TextStyle(color: Colors.black45, fontSize: 14),
                ), // Increased font size
                const SizedBox(height: 14),

                // Email Field
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'E.g. johndoe@email.com',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                    ), // Increased font size
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Password Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                    ), // Increased font size
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: const Icon(Icons.visibility_off, size: 20),
                  ),
                ),
                const SizedBox(height: 8),

                // Remember Me and Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value!;
                            });
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                        const Text(
                          "Remember Me",
                          style: TextStyle(fontSize: 14),
                        ), // Increased font size
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Forgot password action
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontSize: 14),
                      ), // Increased font size
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // TODO: Email login action
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 206, 93, 40),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color.fromARGB(255, 221, 221, 233),
                      ),
                    ), // Increased font size
                  ),
                ),
                const SizedBox(height: 16),

                // Create Account Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Not registered yet?",
                      style: TextStyle(fontSize: 14),
                    ), // Increased font size
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to create account
                      },
                      child: const Text(
                        " Create an account ↗",
                        style: TextStyle(
                          color: Color.fromARGB(255, 12, 95, 204),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ), // Increased font size
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // Google Sign-In Method
  // =========================
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // First try to sign out any existing Google session to force a fresh login
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect();
        }
      } catch (e) {
        print('Error clearing previous Google session: $e');
        // Continue anyway
      }

      // Now attempt the sign in
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      // Force select account prompt
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        await checkUserRole(userCredential.user!, context);
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
    } catch (e) {
      print('General Exception: $e');
    }
  }

  Future<void> checkUserRole(User user, BuildContext context) async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('accounts')
              .where('email', isEqualTo: user.email)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        var data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        String role = data['role'];

        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          Navigator.pushNamed(context, '/');
        }
      } else {
        print("User  not found in Firestore");
        signOut();
      }
    } catch (e) {
      print('Error accessing Firestore: $e');
      signOut();
    }
  }
}

Future<void> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  } catch (e) {
    print('Error signing out: $e');
  }
}
