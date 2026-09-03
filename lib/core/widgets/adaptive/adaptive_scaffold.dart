import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../extensions/box_constraints.extension.dart';
import '../../extensions/build_context.extension.dart';
import '../../extensions/double.extension.dart';
import '../../theme/app_tokens.dart';
import 'adaptive_bar_action.dart';
import 'adaptive_bottom_bar_host.dart';
import 'adaptive_glass.dart';
import 'adaptive_top_bar.dart';
import 'app_platform.dart';
import 'suppressed_back_button_scope.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.body,
    this.slivers,
    this.trailing,
    this.leading,
    this.floatingAction,
    this.onRefresh,
    this.constrainWidth = true,
    this.hasScrollBody = false,
  }) : assert(
         (body == null) != (slivers == null),
         'Pass either body or slivers, never both',
       );

  final String? title;
  final Widget? subtitle;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? trailing;
  final Widget? leading;
  final Widget? floatingAction;
  final Future<void> Function()? onRefresh;
  final bool constrainWidth;
  final bool hasScrollBody;

  @override
  Widget build(BuildContext context) {
    final suppressBack = SuppressedBackButtonScope.of(context);
    if (AppPlatform.useCupertino) {
      return _cupertino(context, suppressBack);
    }
    return LayoutBuilder(
      builder: (context, constraints) => _material(
        context,
        _sliverBody(AdaptiveBottomBarHost.insetOf(context)),
        suppressBack,
        AppPlatform.useWideWeb(context) ? constraints.contentGutter : 0,
      ),
    );
  }

  Widget _cupertino(BuildContext context, bool suppressBack) {
    final inset = AdaptiveBottomBarHost.insetOf(context);
    if (_hasGlassTopBar(context)) {
      return _cupertinoGlass(context, inset, suppressBack);
    }
    return CupertinoPageScaffold(
      child: _floated(
        _cupertinoScrollView(_sliverBody(inset), suppressBack),
        extraBottom: inset,
      ),
    );
  }

  bool _hasGlassTopBar(BuildContext context) =>
      title != null && AdaptiveGlass.isEnabled(context);

  Widget _cupertinoGlass(
    BuildContext context,
    double bottomInset,
    bool suppressBack,
  ) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(
            child: _floated(
              _glassScrollView(context, bottomInset),
              extraBottom: bottomInset,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdaptiveTopBar(
              title: title!,
              subtitle: subtitle,
              leading: _glassLeading(context, suppressBack),
              trailing: trailing,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassScrollView(BuildContext context, double bottomInset) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        PinnedHeaderSliver(
          child: SizedBox(
            height:
                MediaQuery.paddingOf(context).top +
                AdaptiveTopBar.insetFor(hasSubtitle: subtitle != null),
          ),
        ),
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
        _sliverBody(bottomInset),
      ],
    );
  }

  Widget? _glassLeading(BuildContext context, bool suppressBack) {
    if (leading != null) return leading;
    if (suppressBack || !(ModalRoute.of(context)?.canPop ?? false)) return null;
    return AdaptiveBarAction(
      glyph: AdaptiveGlyph.back,
      semanticLabel: context.l10n.commonBack,
      onPressed: () => Navigator.maybePop(context),
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
            largeTitle: Text(title, style: _titleStyle),
            leading: leading,
            automaticallyImplyLeading: !suppressBack,
            trailing: trailing,
          )
        else
          _bareBar(0),
        if (onRefresh != null)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
        sliverBody,
      ],
    );
  }

  Widget _material(
    BuildContext context,
    Widget sliverBody,
    bool suppressBack,
    double gutter,
  ) {
    return Scaffold(
      body: onRefresh == null
          ? _materialScrollView(context, sliverBody, suppressBack, gutter)
          : RefreshIndicator(
              onRefresh: onRefresh!,
              child: _materialScrollView(
                context,
                sliverBody,
                suppressBack,
                gutter,
              ),
            ),
      floatingActionButton: _floatingAction(gutter),
    );
  }

  Widget _materialScrollView(
    BuildContext context,
    Widget sliverBody,
    bool suppressBack,
    double gutter,
  ) {
    return CustomScrollView(
      physics: onRefresh == null ? null : const AlwaysScrollableScrollPhysics(),
      slivers: [_appBar(context, suppressBack, gutter), sliverBody],
    );
  }

  Widget _appBar(BuildContext context, bool suppressBack, double gutter) {
    return switch (title) {
      null => _bareBar(gutter),
      final title when AppPlatform.useWideWeb(context) => SliverAppBar(
        pinned: true,
        centerTitle: true,
        toolbarHeight: kToolbarHeight + AppSpacing.md,
        title: Text(title, style: _titleStyle),
        leading: _leading(gutter),
        leadingWidth: leading == null ? null : _leadingSlotWidth + gutter,
        automaticallyImplyLeading: !suppressBack,
        actions: _actions(gutter),
      ),
      final title => SliverAppBar.large(
        title: Text(title, style: _titleStyle),
        leading: _leading(gutter),
        automaticallyImplyLeading: !suppressBack,
        actions: _actions(gutter),
      ),
    };
  }

  Widget? _leading(double gutter) {
    return leading == null
        ? null
        : Padding(
            padding: EdgeInsets.only(left: gutter),
            child: leading,
          );
  }

  Widget? _floatingAction(double gutter) {
    return floatingAction == null
        ? null
        : Padding(
            padding: EdgeInsets.only(right: gutter),
            child: floatingAction,
          );
  }

  static const double _leadingSlotWidth = 56;

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: AppTypography.brandFontFamily,
  );

  Widget _sliverBody(double bottomInset) {
    return SliverSafeArea(top: false, sliver: _bodySliver(bottomInset));
  }

  Widget _bodySliver(double bottomInset) {
    if (slivers case final slivers?) {
      return _sliverWithBottomInset(_constrainedSlivers(slivers), bottomInset);
    }
    if (hasScrollBody) {
      return _ownScrollSliver(_withBottomInset(body!, bottomInset));
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverFillRemaining(
        hasScrollBody: false,
        child: _withBottomInset(
          _content(constraints.crossAxisExtent.contentGutter),
          bottomInset,
        ),
      ),
    );
  }

  Widget _sliverWithBottomInset(Widget sliver, double bottomInset) {
    if (bottomInset == 0) return sliver;
    return SliverPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      sliver: sliver,
    );
  }

  Widget _withBottomInset(Widget child, double bottomInset) {
    if (bottomInset == 0) return child;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: child,
    );
  }

  Widget _constrainedSlivers(List<Widget> slivers) {
    if (!constrainWidth) return _sliverGroup(slivers);
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: EdgeInsets.symmetric(
          horizontal: constraints.crossAxisExtent.contentGutter,
        ),
        sliver: _sliverGroup(slivers),
      ),
    );
  }

  Widget _sliverGroup(List<Widget> slivers) {
    return SliverMainAxisGroup(slivers: slivers);
  }

  Widget _content(double gutter) {
    if (!constrainWidth) return body!;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: body,
      ),
    );
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

  Widget _bareBar(double gutter) {
    final hasEnds = leading != null || trailing != null;
    return SliverSafeArea(
      bottom: false,
      sliver: SliverToBoxAdapter(
        child: hasEnds
            ? Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + gutter,
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

  List<Widget>? _actions(double gutter) {
    return trailing == null
        ? null
        : [
            Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm + gutter),
              child: trailing!,
            ),
          ];
  }

  Widget _floated(Widget child, {double extraBottom = 0}) {
    if (floatingAction == null) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          right: AppSpacing.md,
          bottom: AppSpacing.md + extraBottom,
          child: SafeArea(top: false, child: floatingAction!),
        ),
      ],
    );
  }
}
