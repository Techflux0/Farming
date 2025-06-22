import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../admin/dash.dart';
import 'notify.dart';

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _redirectUser(userCredential.user?.uid);
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      NotificationBar.show(
        context: context,
        message: e.toString(),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _redirectUser(String? uid) async {
    if (uid == null) {
      debugPrint('[DEBUG] Authentication succeeded but UID is null');
      NotificationBar.show(
        context: context,
        message: 'Authentication failed. Please try again.',
        isError: true,
      );
      return;
    }

    debugPrint('[DEBUG] Attempting to fetch user document for UID: $uid');

    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      debugPrint('[DEBUG] Document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        debugPrint('[DEBUG] User document does not exist in Firestore');
        _setError('User profile not found. Please contact support.');
        return;
      }

      final userData = userDoc.data();
      debugPrint('[DEBUG] User document data: $userData');

      if (userData == null) {
        debugPrint('[DEBUG] User document exists but data is null');
        _setError('User data is corrupted');
        return;
      }

      final role = userData['role'] as String?;
      debugPrint('[DEBUG] Retrieved role: $role');

      if (role == null) {
        debugPrint('[DEBUG] Role field is missing in user document');
      }

      final effectiveRole = role ?? 'member';
      debugPrint('[DEBUG] Effective role being used: $effectiveRole');

      if (!mounted) {
        debugPrint('[DEBUG] Widget not mounted, aborting navigation');
        return;
      }

      debugPrint('[DEBUG] Attempting navigation for role: $effectiveRole');
      switch (effectiveRole) {
        case 'admin':
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false,
          );
          break;
        case 'farmer':
          Navigator.pushReplacementNamed(context, '/farmer-home');
          break;
        case 'veterinary':
          Navigator.pushReplacementNamed(context, '/vet-dashboard');
          break;
        case 'member':
          Navigator.pushReplacementNamed(context, '/member-home');
          break;
        default:
          debugPrint('[DEBUG] Unknown role, redirecting to home');
          Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseException catch (e) {
      debugPrint('[ERROR] Firestore exception: ${e.code} - ${e.message}');
      debugPrint('[ERROR] Stack trace: ${e.stackTrace}');
      _setError('Failed to load user profile. Please try again.');
    } catch (e, stack) {
      debugPrint('[ERROR] Unexpected error: $e');
      debugPrint('[ERROR] Stack trace: $stack');
      _setError('An unexpected error occurred');
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found with this email';
        break;
      case 'wrong-password':
        message = 'Incorrect password';
        break;
      case 'invalid-email':
        message = 'Invalid email address';
        break;
      case 'user-disabled':
        message = 'This account has been disabled';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Try again later.';
        break;
      default:
        message = 'Authentication failed: ${e.message}';
        NotificationBar.show(context: context, message: message, isError: true);
    }
    NotificationBar.show(context: context, message: message, isError: true);
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Image.asset('assets/scafold/sprout.png', height: 60),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 30),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _loginWithEmailPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          '/farm/signup',
                        ),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
