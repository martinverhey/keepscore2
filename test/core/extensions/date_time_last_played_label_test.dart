import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/app/app.dart';
import 'package:keepscore2/core/extensions/date_time.extension.dart';
import 'package:keepscore2/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Future<String> labelFor(
  WidgetTester tester,
  DateTime playedAt, {
  required DateTime now,
  Locale locale = const Locale('en'),
}) async {
  late String label;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: KeepScoreApp.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          label = playedAt.lastPlayedLabel(context, now: now);
          return const SizedBox();
        },
      ),
    ),
  );
  return label;
}

void main() {
  final now = DateTime(2026, 8, 11, 14, 30);

  testWidgets('counts back the last week in days', (tester) async {
    expect(
      await labelFor(tester, DateTime(2026, 8, 11, 9), now: now),
      'Played today',
    );
    expect(
      await labelFor(tester, DateTime(2026, 8, 10, 23), now: now),
      'Played yesterday',
    );
    expect(
      await labelFor(tester, DateTime(2026, 8, 6), now: now),
      'Played 5 days ago',
    );
  });

  testWidgets('dates anything older, dropping the current year', (
    tester,
  ) async {
    final thisYear = await labelFor(tester, DateTime(2026, 8, 4), now: now);
    expect(thisYear, startsWith('Last played Aug'));
    expect(thisYear, isNot(contains('2026')));

    final lastYear = await labelFor(tester, DateTime(2025, 12, 24), now: now);
    expect(lastYear, contains('2025'));
  });

  testWidgets('translates the labels', (tester) async {
    expect(
      await labelFor(
        tester,
        DateTime(2026, 8, 9),
        now: now,
        locale: const Locale('nl'),
      ),
      '2 dagen geleden gespeeld',
    );
  });
}
