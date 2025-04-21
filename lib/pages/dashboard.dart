// lib/pages/login_page.dart
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Page')),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DashBoard'),
              Row(
                children: [
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12.0), // You can adjust this
                        child: Text("Accounts"),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    width: 300,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(12.0), // You can adjust this
                        child: Text("Organizations"),
                      ),
                    ),
                  ),
                ],
              ),
              Text(""),
            ],
          ),
        ],
      ),
    );
  }
}
