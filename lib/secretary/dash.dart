import 'package:flutter/material.dart';
import 'home.dart';
import 'communication.dart';
import '../farm/weather.dart';
import 'reports.dart';
import 'minutes.dart';
import '../farm/profile.dart';

class SecretaryDashboard extends StatefulWidget {
  const SecretaryDashboard({super.key});

  @override
  State<SecretaryDashboard> createState() => _SecretaryDashboardState();
}

class _SecretaryDashboardState extends State<SecretaryDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SecretaryHomeScreen(),
    const CommunicationHomeScreen(),
    const WeatherPage(),
    const ReportsHomeScreen(),
    const MinutesHomeScreen(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Secretary Dashboard'),
        backgroundColor: Colors.green[700],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Communication'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Minutes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}