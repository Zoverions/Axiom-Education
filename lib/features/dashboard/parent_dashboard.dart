import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Dashboard')),
      body: const Center(child: Text('Parent Dashboard Placeholder')),
    );
  }
}
