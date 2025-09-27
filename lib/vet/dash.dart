import 'package:flutter/material.dart';
import 'animals.dart';
import '../farm/weather.dart';
import '../farm/profile.dart';
import 'drugs.dart';
import '../farm/chat.dart';
import 'treat.dart';

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const VeterinaryLivestockPage(),
    const MedicalTreatmentScreen(),
    const FarmerDrugsPage(),
    const ChatPage(),
    const ProfilePage(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Veterinary'),
        backgroundColor: Colors.lightBlue,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Animals'),
          BottomNavigationBarItem(icon: Icon(Icons.healing), label: 'Treat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Drugs',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
