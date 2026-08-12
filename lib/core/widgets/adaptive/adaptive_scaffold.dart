import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.title,
    required this.body,
    this.trailing,
    this.leading,
    this.floatingAction,
    this.bottomBar,
    this.onRefresh,
    this.constrainWidth = true,
    this.hasScrollBody = false,
  });

  final String? title;
  final Widget body;
  final Widget? trailing;
  final Widget? leading;
  final Widget? floatingAction;
  final Widget? bottomBar;
  final Future<void> Function()? onRefresh;
  final bool constrainWidth;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    final content = constrainWidth
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: body,
            ),
          )
        : body;

    final sliverBody = SliverSafeArea(
      top: false,
      sliver: SliverFillRemaining(hasScrollBody: hasScrollBody, child: content),
    );

    return AppPlatform.useCupertino
        ? _cupertino(sliverBody)
        : _material(sliverBody);
  }

  Widget _cupertino(Widget sliverBody) {
    final scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (title case final title?)
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            leading: leading,
            trailing: trailing,
          )
        else
          _bareBar,
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
        sliverBody,
      ],
    );

    return CupertinoPageScaffold(
      child: bottomBar == null
          ? _floated(scrollView)
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _floated(scrollView)),
                  bottomBar!,
                ],
              ),
            ),
    );
  }

  Widget _material(Widget sliverBody) {
    final scrollView = CustomScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (title case final title?)
          SliverAppBar.large(
            title: Text(title),
            leading: leading,
            actions: trailing == null
                ? null
                : [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: trailing!,
                    ),
                  ],
          )
        else
          _bareBar,
        sliverBody,
      ],
    );

    return Scaffold(
      body: onRefresh == null
          ? scrollView
          : RefreshIndicator(onRefresh: onRefresh!, child: scrollView),
      floatingActionButton: floatingAction,
      bottomNavigationBar: bottomBar,
    );
  }

  Widget get _bareBar {
    final hasEnds = leading != null || trailing != null;
    return SliverSafeArea(
      bottom: false,
      sliver: SliverToBoxAdapter(
        child: hasEnds
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    leading ?? const SizedBox.shrink(),
                    trailing ?? const SizedBox.shrink(),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _floated(Widget child) {
    if (floatingAction == null) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          child: floatingAction!,
        ),
      ],
    );
  }
}
