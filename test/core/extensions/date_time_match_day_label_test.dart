import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/extensions/date_time.extension.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

Future<String> labelFor(
  WidgetTester tester,
  DateTime day, {
  required DateTime now,
  Locale locale = const Locale('en'),
}) async {
  late String label;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          label = day.matchDayLabel(context, now: now);
          return const SizedBox();
        },
      ),
    ),
  );
  return label;
}

void main() {
  final now = DateTime(2026, 8, 11, 14, 30);

  testWidgets('names today and yesterday rather than dating them', (
    tester,
  ) async {
    expect(await labelFor(tester, DateTime(2026, 8, 11), now: now), 'Today');
    expect(
      await labelFor(tester, DateTime(2026, 8, 10), now: now),
      'Yesterday',
    );
  });

  testWidgets('dates anything older, dropping the current year', (
    tester,
  ) async {
    final thisYear = await labelFor(tester, DateTime(2026, 8, 4), now: now);
    expect(thisYear, contains('August'));
    expect(thisYear, isNot(contains('2026')));

    final lastYear = await labelFor(tester, DateTime(2025, 12, 24), now: now);
    expect(lastYear, contains('2025'));
  });

  testWidgets('reads today off the clock, not the time of day', (tester) async {
    expect(
      await labelFor(
        tester,
        DateTime(2026, 8, 11),
        now: DateTime(2026, 8, 11, 0, 1),
      ),
      'Today',
    );
  });

  testWidgets('translates the relative labels', (tester) async {
    expect(
      await labelFor(
        tester,
        DateTime(2026, 8, 11),
        now: now,
        locale: const Locale('nl'),
      ),
      'Vandaag',
    );
  });
}
