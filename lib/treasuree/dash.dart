import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'monthly.dart';
import 'registration.dart';
import 'other_payments.dart';

class TreasurerDashboard extends StatefulWidget {
  const TreasurerDashboard({super.key});

  @override
  State<TreasurerDashboard> createState() => _TreasurerDashboardState();
}

class _TreasurerDashboardState extends State<TreasurerDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Widget? _activePage;
  String _activeTitle = 'Dashboard';
  bool _loading = true;

  int _regFeeMembers = 0;
  int _monthlyFeeMembers = 0;
  double _regFeeAmount = 0;
  double _monthlyFeeAmount = 0;
  double _otherPaymentsAmount = 0;

  @override
  void initState() {
    super.initState();
    _verifyTreasurerRole();
    _fetchSummaryData();
  }

  Future<void> _verifyTreasurerRole() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final roles = (data['roles'] as List?)?.cast<String>() ?? ['member'];
          if (!roles.contains('treasurer')) {
            Navigator.pop(context);
          }
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error verifying role: $e')));
    }
  }

  Future<void> _fetchSummaryData() async {
    try {
      final regSnap = await _firestore.collection('registration_fees').get();
      final monthlySnap = await _firestore.collection('monthly_payments').get();
      final otherSnap = await _firestore.collection('other_payments').get();

      double regTotal = 0;
      double monthlyTotal = 0;
      double otherTotal = 0;

      for (var doc in regSnap.docs) {
        regTotal += (doc['amount_paid'] as num).toDouble();
      }

      for (var doc in monthlySnap.docs) {
        monthlyTotal += (doc['amount_paid'] as num).toDouble();
      }

      for (var doc in otherSnap.docs) {
        otherTotal += (doc['amount_paid'] as num).toDouble();
      }

      setState(() {
        _regFeeMembers = regSnap.size;
        _monthlyFeeMembers = monthlySnap.size;
        _regFeeAmount = regTotal;
        _monthlyFeeAmount = monthlyTotal;
        _otherPaymentsAmount = otherTotal;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    }
  }

  void _selectPage(String title, Widget page) {
    setState(() {
      _activeTitle = title;
      _activePage = page;
    });
  }

  double get totalCollected =>
      _regFeeAmount + _monthlyFeeAmount + _otherPaymentsAmount;
  int get totalMembersPaid => _regFeeMembers + _monthlyFeeMembers;
  double get estimatedTotalDue =>
      totalMembersPaid * 500; // Adjust calculation as needed
  double get totalOutstanding => estimatedTotalDue - totalCollected;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Treasurer - $_activeTitle'),
        backgroundColor: Colors.green[700],
        actions: [
          if (_activeTitle != 'Dashboard')
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchSummaryData,
            ),
        ],
      ),
      body: Column(
        children: [Expanded(child: _activePage ?? _buildDashboardContent())],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[800],
        unselectedItemColor: Colors.grey[600],
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
             setState(() {
              _activeTitle = 'Dashboard';
              _activePage = null; // This will trigger _buildDashboardContent()
      });
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
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Registration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Monthly',
          ),
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
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryTile(
                    'Total Collected',
                    'Ksh ${totalCollected.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildSummaryTile(
                    'Total Outstanding',
                    'Ksh ${totalOutstanding.toStringAsFixed(2)}',
                    Icons.warning,
                    Colors.orange,
                  ),
                  _buildSummaryTile(
                    'Members Paid',
                    '$_regFeeMembers Registration • $_monthlyFeeMembers Monthly',
                    Icons.people,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildSummaryCard(
                'Registration Fees',
                'Ksh ${_regFeeAmount.toStringAsFixed(2)}',
                '$_regFeeMembers Members',
                Icons.receipt_long,
                Colors.blue[700]!,
              ),
              _buildSummaryCard(
                'Monthly Payments',
                'Ksh ${_monthlyFeeAmount.toStringAsFixed(2)}',
                '$_monthlyFeeMembers Members',
                Icons.calendar_month,
                Colors.green[700]!,
              ),
              _buildSummaryCard(
                'Other Payments',
                'Ksh ${_otherPaymentsAmount.toStringAsFixed(2)}',
                'Miscellaneous',
                Icons.payment,
                Colors.purple[700]!,
              ),
              _buildSummaryCard(
                'Estimated Due',
                'Ksh ${estimatedTotalDue.toStringAsFixed(2)}',
                'Based on current members',
                Icons.assessment,
                Colors.orange[700]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String amount,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
