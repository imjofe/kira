import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:kira_flutter_client/widgets/gradient_background.dart';
import 'package:kira_flutter_client/ui/schedule/schedule_provider.dart';
import 'package:kira_flutter_client/ui/quickadd/quickadd_provider.dart';
import 'package:kira_flutter_client/models/session_model.dart';
import 'package:kira_flutter_client/providers/goals_provider.dart'; // For AsyncValue

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final sessionsAsync = scheduleProvider.watchSessionsForDate(
      DateTime(_selected.year, _selected.month, _selected.day),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Quick Add'),
          onPressed: () => QuickAddProvider.openModal(context),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Calendar', style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 8),
              _DayStrip(selected: _selected, onChange: (d) => setState(() => _selected = d)),
              Expanded(
                child: _SessionList(
                  state: sessionsAsync,
                  onSwipe: context.read<ScheduleProvider>().completeSession,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onChange;

  const _DayStrip({required this.selected, required this.onChange});

  @override
  Widget build(BuildContext ctx) => SizedBox(
        height: 84,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 14,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final date = DateTime.now().add(Duration(days: i));
            final isSel = date.year == selected.year &&
                date.month == selected.month &&
                date.day == selected.day;
            return GestureDetector(
              onTap: () => onChange(date),
              child: Container(
                width: 56,
                decoration: BoxDecoration(
                  color: isSel ? Colors.white : Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E().format(date),
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                        color: isSel ? Colors.black : Colors.white,
                      ),
                    ),
                    Text(
                      '${date.day}',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        color: isSel ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _SessionList extends StatelessWidget {
  final AsyncValue<List<SessionModel>> state;
  final Future<void> Function(int) onSwipe;

  const _SessionList({required this.state, required this.onSwipe});

  @override
  Widget build(BuildContext ctx) {
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error) => const Center(child: Text('Could not load sessions')),
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(child: Text('Nothing scheduled'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100, top: 16),
          itemCount: sessions.length,
          itemBuilder: (_, i) {
            final s = sessions[i];
            return Dismissible(
              key: ValueKey(s.id),
              direction: DismissDirection.startToEnd,
              onDismissed: (_) => onSwipe(s.id),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              child: _SessionTile(s),
            );
          },
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel s;

  const _SessionTile(this.s, {super.key});

  @override
  Widget build(BuildContext ctx) => ListTile(
        leading: Icon(
          s.status == SessionStatus.completed
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: s.status == SessionStatus.completed ? Colors.green : Colors.white,
        ),
        title: Text(
          s.title,
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        subtitle: Text(
          '${DateFormat.Hm().format(s.startTime)} – ${DateFormat.Hm().format(s.endTime)}',
          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        trailing: s.status == SessionStatus.skipped
            ? const Icon(Icons.skip_next, color: Colors.orange)
            : null,
      );
}