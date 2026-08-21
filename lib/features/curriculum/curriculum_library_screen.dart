import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/curriculum_provider.dart';
import '../learning/mth1w_learning_hub_screen.dart';
import 'curriculum_course_reference_screen.dart';

class CurriculumLibraryScreen extends ConsumerStatefulWidget {
  const CurriculumLibraryScreen({super.key});

  @override
  ConsumerState<CurriculumLibraryScreen> createState() =>
      _CurriculumLibraryScreenState();
}

class _CurriculumLibraryScreenState
    extends ConsumerState<CurriculumLibraryScreen> {
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

  void _retry() => ref.invalidate(courseOverviewProvider);

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(courseOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Curriculum library'),
        actions: [
          IconButton(
            tooltip: 'Reload curriculum',
            onPressed: _retry,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: coursesAsync.when(
          loading: () => const _LibraryLoadingState(),
          error: (error, stackTrace) => _LibraryErrorState(onRetry: _retry),
          data: _buildLibrary,
        ),
      ),
    );
  }

  Widget _buildLibrary(List<CourseOverview> courses) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filtered = courses
        .where((course) {
          if (normalizedQuery.isEmpty) return true;
          return course.id.toLowerCase().contains(normalizedQuery) ||
              course.name.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
    final expectationCount = courses.fold<int>(
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
                  child: _LibraryIntroCard(
                    courseCount: courses.length,
                    expectationCount: expectationCount,
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
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search by course code or name',
                    leading: const Icon(Icons.search_rounded),
                    trailing: [
                      if (_query.isNotEmpty)
                        IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                    ],
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _LibraryEmptyState(
                query: _query.trim(),
                hasCourses: courses.isNotEmpty,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: _CourseReferenceCard(course: filtered[index]),
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

class _LibraryIntroCard extends StatelessWidget {
  const _LibraryIntroCard({
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
              size: 36,
              color: colors.onPrimaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ontario secondary curriculum',
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
                    'Use this local library to look up course and expectation '
                    'references. Browsing here does not enrol a learner, save '
                    'progress, award a grade, or complete an expectation.',
                    style: TextStyle(color: colors.onPrimaryContainer),
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

class _CourseReferenceCard extends StatelessWidget {
  const _CourseReferenceCard({required this.course});

  final CourseOverview course;

  @override
  Widget build(BuildContext context) {
    final isMth1w = course.id == 'MTH1W';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.id,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(course.name),
                      const SizedBox(height: 4),
                      Text(
                        '${course.expectationCount} expectations',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (isMth1w)
                  const Chip(
                    avatar: Icon(Icons.school_rounded, size: 16),
                    label: Text('Learning preview'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => CurriculumCourseReferenceScreen(
                          courseId: course.id,
                          fallbackCourseName: course.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list_alt_rounded),
                  label: const Text('View expectations'),
                ),
                if (isMth1w)
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const Mth1wLearningHubScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Open learning preview'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryLoadingState extends StatelessWidget {
  const _LibraryLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Semantics(
        liveRegion: true,
        label: 'Loading curriculum library',
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _LibraryErrorState extends StatelessWidget {
  const _LibraryErrorState({required this.onRetry});

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
              Icon(
                Icons.menu_book_outlined,
                size: 46,
                color: colors.error,
              ),
              const SizedBox(height: 14),
              Text(
                'The curriculum library could not be opened',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The bundled local curriculum may be unavailable or damaged. '
                'Try loading the local copy again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({required this.query, required this.hasCourses});

  final String query;
  final bool hasCourses;

  @override
  Widget build(BuildContext context) {
    final title = hasCourses
        ? 'No courses match “$query”'
        : 'No courses are available';
    final message = hasCourses
        ? 'Try a course code, subject, or a shorter search.'
        : 'Pull down or use reload to try the bundled local curriculum again.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded, size: 46),
            const SizedBox(height: 14),
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
