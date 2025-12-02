import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/task_repo.dart';
import '../../data/task.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final repo = TaskRepo();
  List<Task> tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    tasks = await repo.all();
    setState(() => isLoading = false);
  }

  int get todoCount => tasks.where((t) => t.status == TaskStatus.todo).length;
  int get inProgressCount => tasks.where((t) => t.status == TaskStatus.inProgress).length;
  int get doneCount => tasks.where((t) => t.status == TaskStatus.done).length;
  
  int get highPriorityCount => tasks.where((t) => t.priority == TaskPriority.high).length;
  int get mediumPriorityCount => tasks.where((t) => t.priority == TaskPriority.medium).length;
  int get lowPriorityCount => tasks.where((t) => t.priority == TaskPriority.low).length;

  int get overdueCount {
    final now = DateTime.now();
    return tasks.where((t) => t.due != null && t.due!.isBefore(now) && t.status != TaskStatus.done).length;
  }

  int get dueTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return tasks.where((t) => 
      t.due != null && 
      t.due!.isAfter(today) && 
      t.due!.isBefore(tomorrow) &&
      t.status != TaskStatus.done
    ).length;
  }

  int get dueTomorrowCount {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final dayAfter = tomorrow.add(const Duration(days: 1));
    return tasks.where((t) => 
      t.due != null && 
      t.due!.isAfter(tomorrow) && 
      t.due!.isBefore(dayAfter) &&
      t.status != TaskStatus.done
    ).length;
  }

  int get dueThisWeekCount {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return tasks.where((t) => 
      t.due != null && 
      t.due!.isAfter(now) && 
      t.due!.isBefore(weekFromNow) &&
      t.status != TaskStatus.done
    ).length;
  }

  List<Task> get recentlyCompleted {
    final completed = tasks.where((t) => t.status == TaskStatus.done).toList();
    completed.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return completed.take(5).toList();
  }

  double get completionRate => tasks.isEmpty ? 0 : (doneCount / tasks.length) * 100;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 24),
              
              _buildUpcomingDeadlines(),
              const SizedBox(height: 24),
              
              Text(
                'Task Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusChart(),
              const SizedBox(height: 24),
              
              Text(
                'Priority Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPriorityChart(),
              const SizedBox(height: 24),
              
              Text(
                'Completion Rate',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCompletionProgress(),
              const SizedBox(height: 24),
              
              if (recentlyCompleted.isNotEmpty) ...[
                Text(
                  'Recently Completed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentlyCompleted(),
                const SizedBox(height: 24),
              ],
              
              _buildProductivityInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard('Total Tasks', tasks.length.toString(), Icons.task_alt, Colors.blue, 'all'),
        _buildStatCard('Completed', doneCount.toString(), Icons.check_circle, Colors.green, 'completed'),
        _buildStatCard('In Progress', inProgressCount.toString(), Icons.hourglass_empty, Colors.orange, 'in-progress'),
        _buildStatCard('Overdue', overdueCount.toString(), Icons.warning, Colors.red, 'overdue'),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String filter) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        _showFilteredTasks(filter);
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(isDark ? 0.3 : 0.1),
                color.withOpacity(isDark ? 0.15 : 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilteredTasks(String filter) {
    List<Task> filteredTasks = [];
    String title = '';

    switch (filter) {
      case 'all':
        filteredTasks = tasks;
        title = 'All Tasks';
        break;
      case 'completed':
        filteredTasks = tasks.where((t) => t.status == TaskStatus.done).toList();
        title = 'Completed Tasks';
        break;
      case 'in-progress':
        filteredTasks = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
        title = 'In Progress Tasks';
        break;
      case 'overdue':
        final now = DateTime.now();
        filteredTasks = tasks.where((t) => 
          t.due != null && 
          t.due!.isBefore(now) && 
          t.status != TaskStatus.done
        ).toList();
        title = 'Overdue Tasks';
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${filteredTasks.length} ${filteredTasks.length == 1 ? 'task' : 'tasks'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  _getStatusIcon(task.status),
                                  color: _getStatusColor(task.status),
                                ),
                                title: Text(
                                  task.title,
                                  style: TextStyle(
                                    decoration: task.status == TaskStatus.done 
                                        ? TextDecoration.lineThrough 
                                        : null,
                                  ),
                                ),
                                subtitle: task.due != null
                                    ? Text(_formatDueDate(task.due!))
                                    : null,
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(task.priority).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    task.priority.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _getPriorityColor(task.priority),
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  // Navigate to task details if needed
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.hourglass_empty;
      case TaskStatus.done:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
    }
  }

  String _formatDueDate(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';
    
    if (diff.inDays == 0) return 'Today at $timeStr';
    if (diff.inDays == 1) return 'Tomorrow at $timeStr';
    if (diff.inDays < 0) return 'Overdue - $timeStr';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $timeStr';
  }

  Widget _buildStatusChart() {
    if (tasks.isEmpty) {
      return _buildEmptyState('No tasks to display');
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: todoCount.toDouble(),
                  title: '$todoCount\nTodo',
                  color: Colors.grey,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: inProgressCount.toDouble(),
                  title: '$inProgressCount\nIn Progress',
                  color: Colors.orange,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: doneCount.toDouble(),
                  title: '$doneCount\nDone',
                  color: Colors.green,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChart() {
    if (tasks.isEmpty) {
      return _buildEmptyState('No tasks to display');
    }

    final maxValue = [highPriorityCount, mediumPriorityCount, lowPriorityCount]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxValue + 1,
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: highPriorityCount.toDouble(),
                      color: Colors.red,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: mediumPriorityCount.toDouble(),
                      color: Colors.orange,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 2,
                  barRods: [
                    BarChartRodData(
                      toY: lowPriorityCount.toDouble(),
                      color: Colors.green,
                      width: 40,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      switch (value.toInt()) {
                        case 0:
                          return const Text('High');
                        case 1:
                          return const Text('Medium');
                        case 2:
                          return const Text('Low');
                        default:
                          return const Text('');
                      }
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionProgress() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${completionRate.toStringAsFixed(1)}% Complete',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$doneCount / ${tasks.length} tasks',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completionRate / 100,
                minHeight: 20,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completionRate >= 75
                      ? Colors.green
                      : completionRate >= 50
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Card(
      elevation: 2,
      child: Container(
        height: 200,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(message, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingDeadlines() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Upcoming Deadlines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDeadlineChip('Today', dueTodayCount, Colors.red),
                _buildDeadlineChip('Tomorrow', dueTomorrowCount, Colors.orange),
                _buildDeadlineChip('This Week', dueThisWeekCount, Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentlyCompleted() {
    return Card(
      elevation: 2,
      child: Column(
        children: recentlyCompleted.map((task) {
          return ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green, size: 28),
            title: Text(
              task.title,
              style: const TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.priority.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getPriorityColor(task.priority),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.red;
      case TaskPriority.medium: return Colors.orange;
      case TaskPriority.low: return Colors.green;
    }
  }

  Widget _buildProductivityInsights() {
    final totalWithDue = tasks.where((t) => t.due != null).length;
    final highPriorityPending = tasks.where((t) => 
      t.priority == TaskPriority.high && t.status != TaskStatus.done
    ).length;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Productivity Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInsightRow(
              Icons.task_alt,
              'You have ${tasks.length} total tasks',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInsightRow(
              Icons.trending_up,
              '${completionRate.toStringAsFixed(0)}% completion rate',
              completionRate >= 75 ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            if (highPriorityPending > 0)
              _buildInsightRow(
                Icons.priority_high,
                '$highPriorityPending high priority tasks need attention',
                Colors.red,
              ),
            if (highPriorityPending > 0) const SizedBox(height: 8),
            if (overdueCount > 0)
              _buildInsightRow(
                Icons.warning_amber,
                '$overdueCount overdue ${overdueCount == 1 ? 'task' : 'tasks'} - review them!',
                Colors.red,
              )
            else
              _buildInsightRow(
                Icons.check_circle_outline,
                'No overdue tasks - great job!',
                Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
