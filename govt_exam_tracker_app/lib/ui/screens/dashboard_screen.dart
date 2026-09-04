import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/exam_provider.dart';
import '../../data/models/exam_status.dart';
import '../widgets/exam_card.dart';
import '../widgets/main_drawer.dart';
import 'exam_form_screen.dart';
import '../../core/services/update_checker_service.dart'; // NEW: Imported the updater

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    // NEW: Check for updates automatically when the dashboard opens!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateCheckerService.checkForUpdates(context);
    });
  }

  List<int> _getAvailableYears(WidgetRef ref) {
    final examsState = ref.watch(examListProvider);
    final Set<int> years = {DateTime.now().year};

    if (examsState is AsyncData) {
      for (var exam in examsState.value!) {
        if (exam.applicationEndDate != null) {
          years.add(exam.applicationEndDate!.year);
        }
      }
    }
    final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
    return sortedYears;
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const SortMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredExamsState = ref.watch(filteredExamsProvider);
    final currentStatusFilter = ref.watch(statusFilterProvider);
    final selectedYear = ref.watch(yearFilterProvider);

    final theme = Theme.of(context);
    final availableYears = _getAvailableYears(ref);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('My Exams', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                dropdownColor: theme.colorScheme.primaryContainer,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                value: selectedYear,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Years', style: TextStyle(color: Colors.black87))),
                  ...availableYears.map((year) => DropdownMenuItem(value: year, child: Text(year.toString(), style: const TextStyle(color: Colors.black87)))),
                ],
                onChanged: (year) {
                  ref.read(yearFilterProvider.notifier).setYear(year);
                },
                selectedItemBuilder: (BuildContext context) {
                  return [
                    const Center(child: Text('All Years', style: TextStyle(color: Colors.white))),
                    ...availableYears.map((year) => Center(child: Text(year.toString(), style: const TextStyle(color: Colors.white)))),
                  ];
                },
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.tune), tooltip: 'Sort & Display Options', onPressed: () => _showSortMenu(context)),
        ],
      ),
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SearchBar(
              hintText: 'Search exams, advt no, or notes...',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(1.0),
              onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip(context, ref, 'All Status', null, currentStatusFilter),
                ...ApplicationStatus.values.where((s) => s != ApplicationStatus.archived).map(
                      (status) => _buildFilterChip(context, ref, status.displayName, status, currentStatusFilter),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredExamsState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (exams) {
                if (exams.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('No exams found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const Text('Try adjusting your filters or year.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: exams.length,
                  itemBuilder: (context, index) => ExamCard(exam: exams[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExamFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Exam'),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, WidgetRef ref, String label, ApplicationStatus? status, ApplicationStatus? currentFilter) {
    final isSelected = currentFilter == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => ref.read(statusFilterProvider.notifier).state = selected ? status : null,
        showCheckmark: false,
        selectedColor: Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }
}

class SortMenuSheet extends ConsumerWidget {
  const SortMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sortField = ref.watch(sortFieldProvider);
    final sortOrder = ref.watch(sortOrderProvider);
    final showNullDates = ref.watch(showNullDatesProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sort & Display Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(label: const Text('Application Deadline'), selected: sortField == SortField.applicationCloseDate, onSelected: (_) => ref.read(sortFieldProvider.notifier).state = SortField.applicationCloseDate),
              ChoiceChip(label: const Text('Exam Date'), selected: sortField == SortField.examDate, onSelected: (_) => ref.read(sortFieldProvider.notifier).state = SortField.examDate),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Order', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              ChoiceChip(label: const Text('Newer First'), selected: sortOrder == SortOrder.newerFirst, onSelected: (_) => ref.read(sortOrderProvider.notifier).state = SortOrder.newerFirst),
              ChoiceChip(label: const Text('Older First'), selected: sortOrder == SortOrder.olderFirst, onSelected: (_) => ref.read(sortOrderProvider.notifier).state = SortOrder.olderFirst),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show Exams with Unknown Dates'),
            subtitle: Text('Include exams where the ${sortField == SortField.examDate ? "Exam Date" : "Deadline"} is not set yet.', style: const TextStyle(fontSize: 12)),
            activeColor: theme.colorScheme.primary,
            value: showNullDates,
            onChanged: (bool value) => ref.read(showNullDatesProvider.notifier).state = value,
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Apply'))),
        ],
      ),
    );
  }
}