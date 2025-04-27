import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: const [
                            SizedBox(width: 8),
                            Text("2025it5-teamd2"),
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
                  Expanded(child: _buildMainCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildPendingCard()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Top Cards ======

  Widget _buildMainCard() {
    return Card(
      elevation: 4, // Add elevation for shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 22, 25, 190),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Organizations",
                style: TextStyle(color: Colors.white, fontSize: 18)),
            Spacer(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingCard() {
    return Card(
      elevation: 4, // Add elevation for shadow effect
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Rounded corners
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 200,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 236, 138, 26),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Events", style: TextStyle(color: Colors.white, fontSize: 18)),
            Spacer(),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
