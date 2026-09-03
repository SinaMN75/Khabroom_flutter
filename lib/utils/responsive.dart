import "package:u/utilities.dart";

/// Layout tiers the whole app reads from: phones get one column and a bottom bar,
/// wider windows get a centred content column and a top bar.
enum AppLayout { compact, medium, expanded }

abstract class AppResponsive {
  static const double compactMaxWidth = 840;
  static const double mediumMaxWidth = 1180;
  static const double contentMaxWidth = 1120;
  static const double readableMaxWidth = 720;
  static const double sideCardWidth = 360;

  static AppLayout of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < compactMaxWidth) return AppLayout.compact;
    if (width < mediumMaxWidth) return AppLayout.medium;
    return AppLayout.expanded;
  }

  static bool isCompact(BuildContext context) => of(context) == AppLayout.compact;

  static bool isExpanded(BuildContext context) => of(context) == AppLayout.expanded;

  static int columns(BuildContext context) => switch (of(context)) {
    AppLayout.compact => 1,
    AppLayout.medium => 2,
    AppLayout.expanded => 3,
  };

  static EdgeInsets pagePadding(BuildContext context) =>
      isCompact(context) ? const EdgeInsets.fromLTRB(16, 8, 16, 32) : const EdgeInsets.fromLTRB(28, 20, 28, 48);

  static double gap(BuildContext context) => isCompact(context) ? 14 : 20;
}

/// Centres a page's content and caps its width so wide windows don't stretch lines of text.
class AppContent extends StatelessWidget {
  const AppContent({required this.child, super.key, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? AppResponsive.contentMaxWidth),
      child: child,
    ),
  );
}

/// Reflows its children from one column on phones up to three on wide screens,
/// letting each item keep its natural height.
class AppGrid extends StatelessWidget {
  const AppGrid({required this.children, super.key, this.spacing = 16, this.columns});

  final List<Widget> children;
  final double spacing;
  final int? columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int count = columns ?? AppResponsive.columns(context);
      final double itemWidth = (constraints.maxWidth - spacing * (count - 1)) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: <Widget>[
          for (final Widget child in children) SizedBox(width: itemWidth, child: child),
        ],
      );
    },
  );
}

/// Detail-page skeleton: a single scroll on phones, content plus a sticky side card on desktop.
class AppDetailLayout extends StatelessWidget {
  const AppDetailLayout({required this.content, required this.side, super.key, this.compactSideFirst = false});

  final Widget content;
  final Widget side;
  final bool compactSideFirst;

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isCompact(context))
      return UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: compactSideFirst ? <Widget>[side, const SizedBox(height: 20), content] : <Widget>[content, const SizedBox(height: 20), side],
      );

    return URow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: content),
        const SizedBox(width: 24),
        SizedBox(width: AppResponsive.sideCardWidth, child: side),
      ],
    );
  }
}
