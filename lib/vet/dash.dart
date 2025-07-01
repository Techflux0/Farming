import 'package:flutter/material.dart';
import 'home.dart';
import 'animals.dart';
import 'crops.dart';
import '../farm/weather.dart';
import 'payment.dart';
import '../farm/profile.dart';

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VetHomeScreen(),
    const AnimalScreen(),
    const CropScreen(),
    const WeatherPage(),
    const PaymentPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Veterinary'),
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
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Crops'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
