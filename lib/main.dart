import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/dashboard.dart';
import 'pages/events.dart';
import 'pages/eventsdetail.dart';
import 'pages/organizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Web',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/events':
            (context) =>
                const EventsPage(), // Replace with your actual event page
        '/organizations': (context) => const OrganizationsPage(),
      },
      initialRoute: '/',
    );
  }
}
