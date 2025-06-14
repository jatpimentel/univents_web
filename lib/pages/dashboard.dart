import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> signOut(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Try to sign out from Google with proper error handling
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.disconnect(); // This revokes access
        }
      } catch (googleError) {
        print('Google sign out error (continuing anyway): $googleError');
      }

      // Clear navigation stack and go to login
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F2), // Background color
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 8),
                            Text("2025it5-teamd2"),
                            TextButton(
                              onPressed: () {
                                signOut(context);
                              },
                              child: const Text("Sign Out"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Top Cards Section Only
              Row(
                children: [
                  Expanded(child: _buildMainCard(context)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPendingCard(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Top Cards ======

  Widget _buildMainCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Navigate to the organizations page
          Navigator.pushNamed(context, '/organizations');
        },
        borderRadius: BorderRadius.circular(20), // Matching the Card's shape
        splashColor: Colors.white24, // Add splash effect when tapped
        highlightColor: Colors.white10, // Add highlight effect when pressed
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 22, 25, 190),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Organizations",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white70),
                ],
              ),
              const Spacer(),
              // Add a subtle hint to indicate it's clickable
              const Text(
                "View all organizations",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          // Navigate to the events page
          Navigator.pushNamed(context, '/events');
        },
        borderRadius: BorderRadius.circular(20), // Matching the Card's shape
        splashColor: Colors.white24, // Add splash effect when tapped
        highlightColor: Colors.white10, // Add highlight effect when pressed
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 200,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 236, 138, 26),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    "Events",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: Colors.white70),
                ],
              ),
              const Spacer(),
              // Add a subtle hint to indicate it's clickable
              const Text(
                "View all events",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
