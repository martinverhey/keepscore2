import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/features/profile/presentation/widgets/profile_avatar_button.dart';
import 'package:keepscore2/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'a long display name is bottom-aligned next to the avatar and truncated to a single line',
    (tester) async {
      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFFFFFFFF),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, _) => const ProfileAvatarButton(
            competitionId: 'c1',
            playerId: 'p1',
            displayName: 'Bartholomew Alexandertonovich',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.crossAxisAlignment, CrossAxisAlignment.end);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(ProfileAvatarButton)),
      );
      final text = tester.widget<Text>(
        find.text(l10n.profileGreeting('Bartholomew Alexandertonovich')),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    },
  );
}
