import 'package:flutter/widgets.dart';

import '../../../../core/extensions/double.extension.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import 'team_area_member.model.dart';

export 'team_area_member.model.dart';

class TeamArea extends StatelessWidget {
  const TeamArea({
    super.key,
    required this.title,
    required this.color,
    required this.members,
    required this.rating,
    required this.myPlayerId,
    this.placeholder,
    this.onTap,
  });

  final String title;
  final Color color;
  final List<TeamAreaMember> members;
  final double rating;
  final String? myPlayerId;
  final String? placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final onTap = this.onTap;
    if (onTap == null) return _area(context);

    return AdaptiveTappable(
      onTap: onTap,
      borderRadius: AppRadius.card,
      child: _area(context),
    );
  }

  Widget _area(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        color: color.withValues(alpha: AppOpacity.accentFill),
        border: Border.all(
          color: color.withValues(alpha: AppOpacity.fieldBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.sm),
          if (members.isNotEmpty)
            for (final member in _sortedByName(members))
              _memberRow(context, member)
          else if (placeholder case final placeholder?)
            Text(placeholder, style: AppTypography.caption),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 4),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.eyebrow.copyWith(color: color),
            ),
          ),
        ),
        if (members.isNotEmpty)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: rating),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => Text(
              value.ratingLabel,
              style: AppTypography.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  Widget _memberRow(BuildContext context, TeamAreaMember member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              member.displayName,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: _isMe(member) ? FontWeight.w600 : FontWeight.normal,
                color: _memberColor(context, member),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            member.rating.ratingLabel,
            style: AppTypography.captionSmall.copyWith(
              fontFeatures: AppTypography.tabularFigures,
              color: _memberColor(context, member),
            ),
          ),
        ],
      ),
    );
  }

  Color? _memberColor(BuildContext context, TeamAreaMember member) {
    if (!_isMe(member)) return null;
    return AdaptiveColors.accent(context);
  }

  bool _isMe(TeamAreaMember member) => member.id == myPlayerId;
}

List<TeamAreaMember> _sortedByName(List<TeamAreaMember> members) {
  final sorted = List<TeamAreaMember>.of(members);
  sorted.sort(
    (a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return sorted;
}
