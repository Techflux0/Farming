import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

import 'firebase_options.dart';
import 'farm/home.dart';
import 'farm/login.dart';
import 'farm/signup.dart';
import 'vet/vet_login.dart';
import 'vet/vet_signup.dart';
import 'vet/vet_dashboard.dart';
import 'vet/vet_profile.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Firebase initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farm Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/landing': (context) => const HomeLandingPage(),
        '/farm/login': (context) => const EmailLoginPage(),
        '/farm/signup': (context) => const SecureSignUpPage(),
        '/home': (context) => const HomeLandingPage(),
        '/vet/login': (context) => VetLoginPage(),
        '/vet/signup': (context) => VetRegisterPage(),
        '/vet/dashboard': (context) => VetDashboard(),
        '/vet/profile': (context) => const VetProfilePage(),


      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        Navigator.pushReplacementNamed(context, '/landing');
      } else {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final role = userDoc.data()?['role'];

          if (role == 'vet') {
            Navigator.pushReplacementNamed(context, '/vet/dashboard');
          } else if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } catch (e) {
          debugPrint('Error fetching user role: $e');
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 8, 18, 9),
      body: Center(
        child:
            Lottie.asset('assets/launcher/splash.json', fit: BoxFit.contain),
      ),
    );
  }
}
