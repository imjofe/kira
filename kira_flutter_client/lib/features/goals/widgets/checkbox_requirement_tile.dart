import 'package:flutter/material.dart';
import 'package:kira_flutter_client/widgets/consumer_widget.dart';
import 'package:kira_flutter_client/models/requirement_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart';

class CheckboxRequirementTile extends ConsumerWidget {
  final RequirementModel req;

  const CheckboxRequirementTile({super.key, required this.req});

  @override
  Widget buildWithRef(BuildContext context, ProviderRef ref) {
    return CheckboxListTile(
      value: req.completed,
      title: Text(req.description),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (val) {
        if (val == null) return;
        ref.read<GoalsProvider>().toggleRequirement(req.id, val);
      },
    );
  }
}