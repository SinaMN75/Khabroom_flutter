import "package:u/utilities.dart";

/// Layout tiers the shell reads from: phones get a bottom bar, wider windows get the side menu.
enum AppLayout { compact, medium, expanded }

abstract class AppResponsive {
  static const double compactMaxWidth = 840;
  static const double expandedMinWidth = 1280;
  static const double contentMaxWidth = 1120;
  static const double readableMaxWidth = 760;

  /// Content-area widths at which a block can afford more columns. These are measured
  /// against the space a widget actually gets, not the window, because the side menu
  /// eats ~280px on desktop.
  static const double twoColumnWidth = 560;
  static const double threeColumnWidth = 900;
  static const double sideBySideWidth = 880;
  static const double sideCardWidth = 320;

  static AppLayout of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < compactMaxWidth) return AppLayout.compact;
    if (width < expandedMinWidth) return AppLayout.medium;
    return AppLayout.expanded;
  }

  static bool isCompact(BuildContext context) => of(context) == AppLayout.compact;

  static EdgeInsets pagePadding(BuildContext context) =>
      isCompact(context) ? const EdgeInsets.fromLTRB(16, 16, 16, 32) : const EdgeInsets.fromLTRB(32, 24, 32, 48);

  static double gap(BuildContext context) => isCompact(context) ? 14 : 20;

  static int columnsFor(double width) {
    if (width >= threeColumnWidth) return 3;
    if (width >= twoColumnWidth) return 2;
    return 1;
  }
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

/// Reflows its children by the width it is actually given, so the side menu can't squash it.
class AppGrid extends StatelessWidget {
  const AppGrid({required this.children, super.key, this.spacing = 16, this.columns});

  final List<Widget> children;
  final double spacing;
  final int? columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int count = columns ?? AppResponsive.columnsFor(constraints.maxWidth);
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

/// Detail-page skeleton: one column when narrow, content plus a side card when there is room.
class AppDetailLayout extends StatelessWidget {
  const AppDetailLayout({required this.content, required this.side, super.key, this.compactSideFirst = false});

  final Widget content;
  final Widget side;
  final bool compactSideFirst;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      if (constraints.maxWidth < AppResponsive.sideBySideWidth)
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
    },
  );
}
