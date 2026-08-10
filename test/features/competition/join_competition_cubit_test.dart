import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepscore2/core/error/failure.dart';
import 'package:keepscore2/features/competition/domain/competition_repository.dart';
import 'package:keepscore2/features/competition/domain/join_preview.dart';
import 'package:keepscore2/features/competition/presentation/cubit/join_competition_cubit.dart';
import 'package:keepscore2/features/player/domain/player.dart';
import 'package:mocktail/mocktail.dart';

class MockCompetitionRepository extends Mock implements CompetitionRepository {}

const _preview = JoinPreview(
  competitionId: 'comp-1',
  name: 'Office Table Tennis',
  ownerName: 'Marieke',
  playerCount: 5,
  alreadyMember: false,
  claimable: [
    ClaimablePlayer(id: 'p-fleur', displayName: 'Fleur'),
    ClaimablePlayer(id: 'p-joost', displayName: 'Joost'),
  ],
);

const _joined = Player(
  id: 'p-fleur',
  competitionId: 'comp-1',
  displayName: 'Fleur',
  isActive: true,
  userId: 'user-9',
);

void main() {
  late MockCompetitionRepository repository;

  setUp(() {
    repository = MockCompetitionRepository();
    when(() => repository.preview(any())).thenAnswer((_) async => _preview);
    when(() => repository.join(
          joinCode: any(named: 'joinCode'),
          displayName: any(named: 'displayName'),
          claimPlayerId: any(named: 'claimPlayerId'),
        )).thenAnswer((_) async => _joined);
  });

  group('code normalisation', () {
    test('accepts the ways people actually type a code', () {
      for (final input in ['HDHS39', 'hdhs39', ' hdhs39 ', 'HDH-S39', 'hd hs 39']) {
        final state = JoinCompetitionState(code: input);
        expect(state.normalizedCode, 'HDHS39', reason: 'for "$input"');
        expect(state.codeIsValid, isTrue, reason: 'for "$input"');
      }
    });

    test('rejects the wrong length', () {
      expect(const JoinCompetitionState(code: 'HDHS3').codeIsValid, isFalse);
      expect(const JoinCompetitionState(code: 'HDHS391').codeIsValid, isFalse);
      expect(const JoinCompetitionState(code: '').codeIsValid, isFalse);
    });
  });

  group('look-up', () {
    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'moves to confirm and offers the placeholders',
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
      },
      verify: (cubit) {
        expect(cubit.state.step, JoinStep.confirm);
        expect(cubit.state.preview, _preview);
        expect(cubit.state.selectedClaimId, isNull);
        expect(cubit.state.canJoin, isTrue);
      },
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'does not call the repository for a short code',
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('HDH');
        await cubit.lookUp();
      },
      verify: (_) => verifyNever(() => repository.preview(any())),
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'an unknown code stays on the code step with the failure shown',
      setUp: () => when(() => repository.preview(any()))
          .thenThrow(const ValidationFailure('No competition with that code')),
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('ZZZZZZ');
        await cubit.lookUp();
      },
      verify: (cubit) {
        expect(cubit.state.step, JoinStep.code);
        expect(cubit.state.failure, isA<ValidationFailure>());
        expect(cubit.state.busy, isFalse);
      },
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'an existing member cannot join again',
      setUp: () => when(() => repository.preview(any())).thenAnswer(
        (_) async => const JoinPreview(
          competitionId: 'comp-1',
          name: 'Office Table Tennis',
          playerCount: 5,
          alreadyMember: true,
          claimable: [],
        ),
      ),
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
      },
      verify: (cubit) => expect(cubit.state.canJoin, isFalse),
    );
  });

  group('claiming a placeholder', () {
    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'passes the chosen placeholder through so its history is inherited',
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
        cubit.claimSelected('p-fleur');
        await cubit.join();
      },
      verify: (cubit) {
        verify(() => repository.join(
              joinCode: 'hdhs39',
              claimPlayerId: 'p-fleur',
            )).called(1);
        expect(cubit.state.joined, _joined);
      },
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'tapping the same placeholder again means "none of these, I am new"',
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
        cubit.claimSelected('p-fleur');
        cubit.claimSelected('p-fleur');
        await cubit.join();
      },
      verify: (cubit) {
        expect(cubit.state.selectedClaimId, isNull);
        verify(() => repository.join(joinCode: 'hdhs39', claimPlayerId: null))
            .called(1);
      },
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'losing the race for a placeholder surfaces the server message',
      setUp: () => when(() => repository.join(
            joinCode: any(named: 'joinCode'),
            displayName: any(named: 'displayName'),
            claimPlayerId: any(named: 'claimPlayerId'),
          )).thenThrow(
        const ValidationFailure('That player has already been claimed'),
      ),
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
        cubit.claimSelected('p-fleur');
        await cubit.join();
      },
      verify: (cubit) {
        expect(cubit.state.joined, isNull);
        expect(cubit.state.failure, isA<ValidationFailure>());
        expect(cubit.state.step, JoinStep.confirm);
      },
    );

    blocTest<JoinCompetitionCubit, JoinCompetitionState>(
      'going back clears the pending claim',
      build: () => JoinCompetitionCubit(repository),
      act: (cubit) async {
        cubit.codeChanged('hdhs39');
        await cubit.lookUp();
        cubit.claimSelected('p-joost');
        cubit.back();
      },
      verify: (cubit) {
        expect(cubit.state.step, JoinStep.code);
        expect(cubit.state.selectedClaimId, isNull);
        expect(cubit.state.code, 'hdhs39');
      },
    );
  });
}
