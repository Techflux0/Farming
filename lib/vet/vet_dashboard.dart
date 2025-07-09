import 'package:flutter/material.dart';

class VetDashboard extends StatefulWidget {
  const VetDashboard({super.key});

  @override
  State<VetDashboard> createState() => _VetDashboardState();
}

class _VetDashboardState extends State<VetDashboard> {
  final List<Map<String, dynamic>> reports = [
    {
      'farmerName': 'John Doe',
      'imageUrl': 'https://via.placeholder.com/150',
      'description': 'Cow has an eye infection.',
      'location': 'Eldoret',
    },
    {
      'farmerName': 'Jane Farmer',
      'imageUrl': 'https://via.placeholder.com/150',
      'description': 'Goat is limping.',
      'location': 'Nakuru',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vet Dashboard"),
        backgroundColor: Colors.green,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.healing), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: ListView.builder(
        itemCount: reports.length,
        itemBuilder: (context, index) {
          final report = reports[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              leading: Image.network(report['imageUrl']),
              title: Text(report['description']),
              subtitle:
                  Text('${report['farmerName']} • ${report['location']}'),
              trailing: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Recommendation"),
                      content: TextField(
                        decoration: const InputDecoration(
                          hintText: "Enter medicine suggestion",
                        ),
                        onSubmitted: (value) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Recommendation saved: $value')),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: const Text("Respond"),
              ),
            ),
          );
        },
      ),
    );
  }
}
