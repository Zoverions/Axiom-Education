import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/curriculum_provider.dart';

class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(courseOverviewProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Curriculum Diagnostic Overview')),
      body: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading curriculum database: $err')),
        data: (courses) {
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Text(
                        course.id.substring(0, 3),
                        style: const TextStyle(color: Colors.white, fontSize: 12)
                    ),
                  ),
                  title: Text(course.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${course.name}\nExpectations: ${course.expectationCount}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailScreen(courseId: course.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CourseDetailScreen extends ConsumerWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: Text('$courseId Details')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (detail) {
          return ListView.builder(
            itemCount: detail.strands.length,
            itemBuilder: (context, index) {
              final strand = detail.strands[index];
              return ExpansionTile(
                title: Text(strand.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${strand.expectations.length} expectations'),
                children: strand.expectations.map((exp) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
                    title: Text(exp.text),
                    subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Wrap(
                            spacing: 6.0,
                            children: exp.tags.map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                            )).toList(),
                        ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
