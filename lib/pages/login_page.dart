import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Login Page'),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  await signInWithGoogle(context); // ✅ Pass context here
                },
                child: Image.asset(
                  'assets/images/google.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithPopup(googleProvider);

      print('Signed in as: ${userCredential.user?.displayName}');

      // ✅ Navigate to dashboard if login is successful
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
      // Query the collection where email == user's email
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
          print("User is not an admin");
        }
      } else {
        print("User not found in Firestore");
      }
    } catch (e) {
      print('Error accessing Firestore: $e');
    }
  }
}
