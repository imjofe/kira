import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A simple adapter to provide Riverpod-like ConsumerWidget API using Provider
abstract class ConsumerWidget extends StatelessWidget {
  const ConsumerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return buildWithRef(context, ProviderRef(context));
  }

  Widget buildWithRef(BuildContext context, ProviderRef ref);
}

// Simple provider reference that mimics Riverpod's WidgetRef
class ProviderRef {
  final BuildContext context;

  const ProviderRef(this.context);

  T watch<T extends ChangeNotifier>() {
    return context.watch<T>();
  }

  T read<T extends ChangeNotifier>() {
    return context.read<T>();
  }
}