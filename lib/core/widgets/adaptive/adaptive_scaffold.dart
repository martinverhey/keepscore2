import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'app_platform.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.trailing,
    this.leading,
    this.floatingAction,
    this.bottomBar,
    this.constrainWidth = true,
  });

  final String title;
  final Widget body;
  final Widget? trailing;
  final Widget? leading;
  final Widget? floatingAction;
  final Widget? bottomBar;
  final bool constrainWidth;

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

    final stacked = floatingAction == null
        ? content
        : Stack(
            children: [
              Positioned.fill(child: content),
              Positioned(
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: floatingAction!,
              ),
            ],
          );

    if (AppPlatform.useCupertino) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          leading: leading,
          trailing: trailing,
        ),
        child: SafeArea(
          child: bottomBar == null
              ? stacked
              : Column(
                  children: [
                    Expanded(child: stacked),
                    bottomBar!,
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
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
      ),
      body: SafeArea(child: content),
      floatingActionButton: floatingAction,
      bottomNavigationBar: bottomBar,
    );
  }
}
