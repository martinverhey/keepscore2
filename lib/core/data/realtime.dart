import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

int _topicSequence = 0;

Stream<void> realtimeTicks(
  SupabaseClient client, {
  required String topic,
  required String table,
  String? column,
  Object? value,
}) {
  final name = '$topic:${_topicSequence++}';

  late final RealtimeChannel channel;
  late final StreamController<void> controller;

  controller = StreamController<void>(
    onListen: () {
      channel = client.channel(name)
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: column == null
              ? null
              : PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: column,
                  value: value,
                ),
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        )
        ..subscribe();
    },
    onCancel: () => client.removeChannel(channel),
  );

  return controller.stream;
}

class DebouncedTicks {
  DebouncedTicks(
    Stream<void> ticks,
    void Function() onSettled, {
    this.quietPeriod = const Duration(milliseconds: 400),
  }) {
    _subscription = ticks.listen((_) {
      _timer?.cancel();
      _timer = Timer(quietPeriod, onSettled);
    });
  }

  final Duration quietPeriod;

  late final StreamSubscription<void> _subscription;
  Timer? _timer;

  void cancel() {
    _timer?.cancel();
    _subscription.cancel();
  }
}
