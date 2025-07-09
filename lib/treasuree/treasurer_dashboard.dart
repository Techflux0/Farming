import 'package:flutter/material.dart';
import 'registration_fee.dart';
import 'monthly_payment.dart';
import 'other_payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TreasurerDashboard extends StatefulWidget {
  const TreasurerDashboard({super.key});

  @override
  State<TreasurerDashboard> createState() => _TreasurerDashboardState();
}

class _TreasurerDashboardState extends State<TreasurerDashboard> {
  Widget? _activePage;
  String _activeTitle = 'Dashboard';

  int regFeeMembers = 0;
  int monthlyFeeMembers = 0;
  int regFeeAmount = 0;
  int monthlyFeeAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    try {
      final regSnap = await FirebaseFirestore.instance.collection('registration_fees').get();
      final monthlySnap = await FirebaseFirestore.instance.collection('monthly_payments').get();

      int regTotal = 0;
      int monthlyTotal = 0;

      for (var doc in regSnap.docs) {
        regTotal += int.tryParse(doc['amount_paid'].toString()) ?? 0;
      }

      for (var doc in monthlySnap.docs) {
        monthlyTotal += int.tryParse(doc['amount_paid'].toString()) ?? 0;
      }

      setState(() {
        regFeeMembers = regSnap.size;
        monthlyFeeMembers = monthlySnap.size;
        regFeeAmount = regTotal;
        monthlyFeeAmount = monthlyTotal;
      });
    } catch (e) {
      debugPrint('Error fetching summary data: $e');
    }
  }

  void _selectPage(String title, Widget page) {
    setState(() {
      _activeTitle = title;
      _activePage = page;
    });
  }

  int get totalCollected => regFeeAmount + monthlyFeeAmount;
  int get totalMembersPaid => regFeeMembers + monthlyFeeMembers;
  int get estimatedTotalDue => totalMembersPaid * 500; // Replace 500 with your logic if different
  int get totalOutstanding => estimatedTotalDue - totalCollected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppBar(
            title: Text('💼 Treasurer - $_activeTitle'),
            backgroundColor: Colors.green[700],
          ),
          Expanded(
            child: _activePage ?? _buildDashboardContent(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green[900],
        unselectedItemColor: Colors.grey,
        currentIndex: _activeTitle == 'Dashboard'
            ? 0
            : _activeTitle == 'Registration Fee'
                ? 1
                : _activeTitle == 'Monthly Payment'
                    ? 2
                    : 3,
        onTap: (index) {
          switch (index) {
            case 0:
              _selectPage('Dashboard', Container());
              break;
            case 1:
              _selectPage('Registration Fee', const RegistrationFeePage());
              break;
            case 2:
              _selectPage('Monthly Payment', const MonthlyPaymentPage());
              break;
            case 3:
              _selectPage('Other Payments', const OtherPaymentPage());
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Registration'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Monthly'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Other'),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome Back, Treasurer 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildSummaryCard(
                'Members Paid',
                '$regFeeMembers - registration fee\n$monthlyFeeMembers - monthly payment',
                Icons.group,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Amount Collected',
                'Ksh $regFeeAmount - registration\nKsh $monthlyFeeAmount - monthly',
                Icons.attach_money,
              ),
              const SizedBox(width: 16),
              _buildSummaryCard(
                'Outstanding',
                'Ksh $totalOutstanding',
                Icons.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade300, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(title, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}
