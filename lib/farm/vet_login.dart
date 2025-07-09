import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VetLoginPage extends StatefulWidget {
  const VetLoginPage({super.key});

  @override
  State<VetLoginPage> createState() => _VetLoginPageState();
}

class _VetLoginPageState extends State<VetLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void loginVet() async {
  try {
    print("⏳ Logging in...");
    UserCredential cred = await FirebaseAuth.instance
        .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim());
    print("✅ Firebase Auth success");

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(cred.user!.uid)
        .get();

    if (!userDoc.exists) {
      print("❌ Firestore document does not exist.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No vet record found in database.")),
      );
      return;
    }

    final role = userDoc.data()?['role'];
    print("👤 Role found: $role");

    if (role != 'vet') {
      print("❌ Role is not vet, access denied.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Access denied: Not a vet account.")),
      );
      return;
    }

    print("✅ Login success, navigating to dashboard...");
    Navigator.pushReplacementNamed(context, '/vet/dashboard');
  } catch (e) {
    print("❌ Firebase Auth Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Login failed: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Vet Login")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loginVet,
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/vet/signup'),
              child: const Text("Don't have an account? Sign up here"),
            ),
          ],
        ),
      ),
    );
  }
}
