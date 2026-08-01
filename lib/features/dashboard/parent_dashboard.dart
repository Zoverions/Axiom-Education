import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Student Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          Icon(Icons.timer, size: 40, color: Colors.blue),
                          SizedBox(height: 8),
                          Text(
                            'Study Time',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('45 mins today'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 40,
                            color: Colors.green,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tasks Completed',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('5 / 7 tasks'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: const [
                          Icon(Icons.star, size: 40, color: Colors.orange),
                          SizedBox(height: 8),
                          Text(
                            'Current Level',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Level 3 (75%)'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ListTile(
                    leading: Icon(Icons.menu_book),
                    title: Text('Completed Math Module: Linear Equations'),
                    subtitle: Text('Today at 10:30 AM'),
                    trailing: Text('Score: 90%'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.science),
                    title: Text(
                      'Started Science Experiment: Chemical Reactions',
                    ),
                    subtitle: Text('Yesterday at 2:15 PM'),
                    trailing: Text('In Progress'),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.history_edu),
                    title: Text('Finished History Reading: Confederation'),
                    subtitle: Text('Monday at 11:00 AM'),
                    trailing: Text('Score: 85%'),
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
