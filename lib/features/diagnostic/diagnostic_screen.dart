import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/curriculum_provider.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(courseOverviewProvider);
    await ref.read(courseOverviewProvider.future);
  }

  void _retry() {
    ref.invalidate(courseOverviewProvider);
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(courseOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Axiom Education'),
        actions: [
          IconButton(
            tooltip: 'Reload curriculum',
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: overviewAsync.when(
          loading: () => const _LoadingState(),
          error: (error, stackTrace) => _LoadError(
            title: 'The Ontario curriculum pack could not be opened',
            message:
                'The local curriculum copy may be unavailable or damaged. '
                'Retry to restore it from the bundled, read-only pack.',
            onRetry: _retry,
          ),
          data: _buildCourseBrowser,
        ),
      ),
    );
  }

  Widget _buildCourseBrowser(List<CourseOverview> courses) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredCourses = courses
        .where((course) {
          if (normalizedQuery.isEmpty) return true;
          return course.id.toLowerCase().contains(normalizedQuery) ||
              course.name.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    final totalExpectations = courses.fold<int>(
      0,
      (total, course) => total + course.expectationCount,
    );

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: _PackSummary(
                    courseCount: courses.length,
                    expectationCount: totalExpectations,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: 'Search courses',
                      hintText: 'Try MTH1W, English, science…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.clear_rounded),
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
            ),
          ),
          if (filteredCourses.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(
                title: courses.isEmpty
                    ? 'No courses are available'
                    : 'No courses match “${_query.trim()}”',
                message: courses.isEmpty
                    ? 'Pull down or use reload to try the local pack again.'
                    : 'Search by course code or course name.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.builder(
                itemCount: filteredCourses.length,
                itemBuilder: (context, index) {
                  final course = filteredCourses[index];
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: _CourseCard(course: course),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PackSummary extends StatelessWidget {
  const _PackSummary({
    required this.courseCount,
    required this.expectationCount,
  });

  final int courseCount;
  final int expectationCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: colors.onPrimaryContainer,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ontario Secondary Curriculum Pack',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$courseCount courses • $expectationCount expectations',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse the bundled local curriculum. Tutoring and learner '
                    'records remain unavailable until their governed providers '
                    'are enabled.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});

  final CourseOverview course;

  String get _monogram {
    final id = course.id.trim();
    if (id.isEmpty) return '?';
    final end = id.length < 3 ? id.length : 3;
    return id.substring(0, end).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        label:
            '${course.id}, ${course.name}, ${course.expectationCount} expectations',
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: CircleAvatar(
            backgroundColor: colors.secondaryContainer,
            foregroundColor: colors.onSecondaryContainer,
            child: Text(
              _monogram,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            course.id,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${course.name}\n${course.expectationCount} expectations',
            ),
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => CourseDetailScreen(
                  courseId: course.id,
                  fallbackCourseName: course.name,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.fallbackCourseName,
  });

  final String courseId;
  final String? fallbackCourseName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(courseDetailProvider(courseId));

    return Scaffold(
      appBar: AppBar(title: Text(courseId)),
      body: SafeArea(
        child: detailAsync.when(
          loading: () => const _LoadingState(),
          error: (error, stackTrace) => _LoadError(
            title: 'This course could not be opened',
            message:
                'Retry to reload the course from the local curriculum pack.',
            onRetry: () => ref.invalidate(courseDetailProvider(courseId)),
          ),
          data: (detail) {
            if (detail.strands.isEmpty) {
              return _EmptyState(
                title: fallbackCourseName ?? detail.name,
                message: 'No expectations are available for this course.',
              );
            }

            final expectationCount = detail.strands.fold<int>(
              0,
              (total, strand) => total + strand.expectations.length,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${detail.strands.length} strands • '
                              '$expectationCount expectations',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...detail.strands.map(
                  (strand) => Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ExpansionTile(
                          title: Text(
                            strand.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${strand.expectations.length} expectations',
                          ),
                          children: strand.expectations
                              .map((expectation) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.fromLTRB(
                                    24,
                                    8,
                                    24,
                                    12,
                                  ),
                                  title: Text(expectation.text),
                                  subtitle: expectation.tags.isEmpty
                                      ? null
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            top: 10,
                                          ),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: expectation.tags
                                                .map(
                                                  (tag) => Chip(
                                                    label: Text(tag),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                                )
                                                .toList(growable: false),
                                          ),
                                        ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading curriculum',
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
