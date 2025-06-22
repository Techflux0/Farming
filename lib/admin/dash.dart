import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AdminHomeScreen(),
    const LivestockManagementScreen(),
    const CropManagementScreen(),
    const WeatherDataScreen(),
    const MarketManagementScreen(),
    const AdminProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'Livestock'),
          BottomNavigationBarItem(icon: Icon(Icons.spa), label: 'Crops'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Weather'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Market',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Placeholder screens for each tab
class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin Home'));
  }
}

class LivestockManagementScreen extends StatelessWidget {
  const LivestockManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Livestock Management'));
  }
}

class CropManagementScreen extends StatelessWidget {
  const CropManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Crop Management'));
  }
}

class WeatherDataScreen extends StatelessWidget {
  const WeatherDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Weather Data'));
  }
}

class MarketManagementScreen extends StatelessWidget {
  const MarketManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Market Management'));
  }
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Admin Profile'));
  }
}
