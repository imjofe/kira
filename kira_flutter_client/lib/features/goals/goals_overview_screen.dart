import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/models/goal_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/ui/quickadd/quickadd_provider.dart';

class GoalsOverviewScreen extends StatefulWidget {
  const GoalsOverviewScreen({super.key});

  @override
  State<GoalsOverviewScreen> createState() => _GoalsOverviewScreenState();
}

class _GoalsOverviewScreenState extends State<GoalsOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Load goals when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GoalsProvider>().loadGoals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<GoalsProvider>(
        builder: (context, provider, child) {
          return provider.watchAllGoals().when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error) => const Center(child: Text('Failed to load goals')),
            data: (goals) => _buildBody(context, goals, provider),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => QuickAddProvider.openModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Quick Add'),
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.black87,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody(BuildContext context, List<GoalModel> goals, GoalsProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text('Your goals', style: Theme.of(context).textTheme.headlineLarge),
          const Text('In 66 days you\'ll wonder why this ever felt difficult. This is the progress you made so far:'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => _ProgressRing(value: _aggregate(goals, i, provider))),
          ),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _GoalCard(goal: goals[i]),
          ),
          const SizedBox(height: 64), // leave space for FAB
        ],
      ),
    );
  }

  double _aggregate(List<GoalModel> goals, int bucket, GoalsProvider provider) {
    if (goals.isEmpty) return 0.0;
    
    // Simple placeholder aggregation - average of all goals for now
    double sum = 0.0;
    for (final goal in goals) {
      sum += provider.progressFor(goal);
    }
    return sum / goals.length;
  }
}

class _ProgressRing extends StatelessWidget {
  final double value;

  const _ProgressRing({required this.value});

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 36.0, // width 72
      lineWidth: 8.0,
      percent: value,
      center: Text(
        '${(value * 100).round()}%',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      progressColor: Colors.white,
      backgroundColor: Colors.white.withOpacity(0.3),
      circularStrokeCap: CircularStrokeCap.round,
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/goals/${goal.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.2),
              Colors.white.withOpacity(.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(goal.subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              '${goal.targetTime.format(context)} / day',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}