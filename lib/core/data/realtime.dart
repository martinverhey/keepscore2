import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

int _topicSequence = 0;

/// A stream that ticks on every insert, update or delete the caller is allowed
/// to see on [table], optionally narrowed to `column = value`.
///
/// The payload is deliberately dropped. A season replay rewrites every rating
/// row it owns, so reconciling individual rows costs more than refetching, and
/// `postgres_changes` honours RLS — a tick only ever means "something you can
/// read has changed".
///
/// The channel is opened on the first listener and removed on cancel, so a
/// cubit that closes takes its socket subscription with it.
Stream<void> realtimeTicks(
  SupabaseClient client, {
  required String topic,
  required String table,
  String? column,
  Object? value,
}) {
  // Removing a channel is asynchronous, so a resubscribe to the same filter
  // would otherwise race a channel that is still being torn down.
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

/// Subscribes to [ticks] and calls [onSettled] once no tick has arrived for
/// [quietPeriod].
///
/// A season replay rewrites every rating row it owns, so ticks arrive in
/// bursts; debouncing collapses a burst into a single refetch instead of one
/// per row.
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
