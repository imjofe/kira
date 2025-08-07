import 'package:flutter/material.dart';
import 'package:kira_flutter_client/widgets/consumer_widget.dart';
import 'package:kira_flutter_client/widgets/gradient_background.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';
import 'package:kira_flutter_client/models/goal_detail.dart';
import 'package:kira_flutter_client/features/goals/widgets/checkbox_requirement_tile.dart';

class GoalDetailScreen extends ConsumerWidget {
  final int goalId;

  const GoalDetailScreen({super.key, required this.goalId});

  @override
  Widget buildWithRef(BuildContext context, ProviderRef ref) {
    final goalAsync = ref.watch<GoalsProvider>().watchGoal(goalId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.transparent,
      body: goalAsync.when<Widget>(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error) => const Center(child: Text('Could not load goal')),
        data: (GoalDetail gd) => _buildBody(context, gd),
      ),
    );
  }

  Widget _buildBody(BuildContext context, GoalDetail gd) {
    return GradientBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(gd.goal.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(gd.goal.subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ...gd.reqs.map((r) => CheckboxRequirementTile(req: r)),
            const SizedBox(height: 32),
            Text('Recommendations', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Stay consistent! Small steps compound over time.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}