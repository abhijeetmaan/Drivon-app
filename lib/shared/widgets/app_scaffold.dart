import 'package:flutter/material.dart';

import '../../core/utils/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool safeArea;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.safeArea = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    const navBarHeight = 80.0;
    const fabBottomPadding = navBarHeight - 20;

    Widget content = Padding(
      padding: AppSpacing.screenPadding,
      child: body,
    );

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      body: content,
      floatingActionButton: floatingActionButton == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: fabBottomPadding),
              child: floatingActionButton,
            ),
      floatingActionButtonLocation: floatingActionButtonLocation ?? FloatingActionButtonLocation.endFloat,
    );
  }
}
