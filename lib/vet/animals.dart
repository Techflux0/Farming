import 'package:flutter/material.dart';

class AnimalScreen extends StatelessWidget {
  const AnimalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome to the Animals Home Screen',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
