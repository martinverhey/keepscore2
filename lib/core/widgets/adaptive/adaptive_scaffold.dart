import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';
import 'suppressed_back_button_scope.dart';

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
    final suppressBack = SuppressedBackButtonScope.of(context);
    return AppPlatform.useCupertino
        ? _cupertino(_sliverBody(), suppressBack)
        : _material(context, _sliverBody(), suppressBack);
  }

  Widget _cupertino(Widget sliverBody, bool suppressBack) {
    return CupertinoPageScaffold(
      child: bottomBar == null
          ? _floated(_cupertinoScrollView(sliverBody, suppressBack))
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(
                    child: _floated(
                      _cupertinoScrollView(sliverBody, suppressBack),
                    ),
                  ),
                  bottomBar!,
                ],
              ),
            ),
    );
  }

  Widget _cupertinoScrollView(Widget sliverBody, bool suppressBack) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        if (title case final title?)
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            leading: leading,
            automaticallyImplyLeading: !suppressBack,
            trailing: trailing,
          )
        else
          _bareBar(),
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
        sliverBody,
      ],
    );
  }

  Widget _material(BuildContext context, Widget sliverBody, bool suppressBack) {
    return Scaffold(
      body: onRefresh == null
          ? _materialScrollView(context, sliverBody, suppressBack)
          : RefreshIndicator(
              onRefresh: onRefresh!,
              child: _materialScrollView(context, sliverBody, suppressBack),
            ),
      floatingActionButton: floatingAction,
      bottomNavigationBar: bottomBar,
    );
  }

  Widget _materialScrollView(
    BuildContext context,
    Widget sliverBody,
    bool suppressBack,
  ) {
    return CustomScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      slivers: [_appBar(context, suppressBack), sliverBody],
    );
  }

  Widget _appBar(BuildContext context, bool suppressBack) {
    return switch (title) {
      null => _bareBar(),
      final title when AppPlatform.useWideWeb(context) => SliverAppBar(
        pinned: true,
        centerTitle: true,
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: !suppressBack,
        actions: _actions(),
      ),
      final title => SliverAppBar.large(
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: !suppressBack,
        actions: _actions(),
      ),
    };
  }

  Widget _sliverBody() {
    return SliverSafeArea(
      top: false,
      sliver: hasScrollBody
          ? _ownScrollSliver(_content())
          : SliverFillRemaining(hasScrollBody: false, child: _content()),
    );
  }

  Widget _content() {
    return constrainWidth && !hasScrollBody
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
              child: body,
            ),
          )
        : body;
  }

  Widget _ownScrollSliver(Widget child) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final extent = math.max(
          0.0,
          constraints.remainingPaintExtent - math.min(constraints.overlap, 0.0),
        );
        return SliverToBoxAdapter(
          child: SizedBox(height: extent, child: child),
        );
      },
    );
  }

  Widget _bareBar() {
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

  List<Widget>? _actions() {
    return trailing == null
        ? null
        : [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: trailing!,
            ),
          ];
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
