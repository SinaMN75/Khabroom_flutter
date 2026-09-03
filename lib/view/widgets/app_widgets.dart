import "package:khabroom/main.dart";
import "package:u/utilities.dart";

enum AppTone { neutral, brand, positive, warning, danger }

extension AppToneColors on AppTone {
  Color foreground(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (this) {
      AppTone.neutral => scheme.onSurfaceVariant,
      AppTone.brand => scheme.primary,
      AppTone.positive => AppColors.success,
      AppTone.warning => AppColors.warning,
      AppTone.danger => scheme.error,
    };
  }

  Color background(BuildContext context) => foreground(context).withValues(alpha: 0.12);
}

/// Title + optional trailing action, used above every list and section.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({required this.title, super.key, this.subtitle, this.actionTitle, this.onAction});

  final String title;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return URow(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        UColumn(
          expanded: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge(title, color: scheme.onSurface),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant),
            ],
          ],
        ),
        if (actionTitle != null && onAction != null)
          UButton(
            title: actionTitle,
            type: UButtonType.text,
            textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, fontSize: 12.5, fontWeight: FontWeight.w600, color: scheme.primary),
            onTap: onAction,
          ),
      ],
    );
  }
}

/// A bordered surface used for every grouped block of content.
class AppCard extends StatelessWidget {
  const AppCard({required this.child, super.key, this.padding, this.onTap, this.clip = false});

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      radius: 18,
      color: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: padding ?? const EdgeInsets.all(16),
      onTap: onTap,
      child: child,
    );
  }
}

/// Card with a small caption above its body.
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({required this.title, required this.child, super.key, this.icon});

  final String title;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 8),
              ],
              UTextTitleSmall(title, color: scheme.onSurface),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Cover photo with a graceful fallback when a place has no media yet.
class AppCoverImage extends StatelessWidget {
  const AppCoverImage({required this.media, super.key, this.height = 180, this.radius = 0, this.fallbackIcon = Icons.photo_camera_back_outlined});

  final List<UMediaResponse>? media;
  final double height;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UMediaResponse? first = (media ?? <UMediaResponse>[]).firstOrDefault();
    final String? source = first?.url ?? first?.path;

    if (source == null || source.isEmpty)
      return UContainer(
        height: height,
        radius: radius,
        color: scheme.primaryContainer,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, size: 30, color: scheme.primary.withValues(alpha: 0.6)),
      );

    return UImage(source, height: height, width: double.infinity, fit: BoxFit.cover, borderRadius: radius);
  }
}

/// Small pill used for statuses, tags and counts.
class AppChip extends StatelessWidget {
  const AppChip({required this.label, super.key, this.icon, this.tone = AppTone.neutral, this.filled = true});

  final String label;
  final IconData? icon;
  final AppTone tone;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color color = tone.foreground(context);
    return UContainer(
      radius: 9,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: filled ? tone.background(context) : null,
      border: filled ? null : Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      child: URow(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          UTextLabelMedium(label, color: color, fontWeight: FontWeight.w600),
        ],
      ),
    );
  }
}

/// Label/value row used through detail pages and receipts.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({required this.label, required this.value, super.key, this.icon, this.valueColor, this.emphasize = false});

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: URow(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          UTextBodySmall(label, color: scheme.onSurfaceVariant, expanded: 1),
          const SizedBox(width: 12),
          Flexible(
            child: emphasize
                ? UTextTitleSmall(value, color: valueColor ?? scheme.onSurface, textAlign: TextAlign.end)
                : UTextBodyMedium(value, color: valueColor ?? scheme.onSurface, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

/// Wrapped list of short facts — amenities, rules, documents.
class AppChipList extends StatelessWidget {
  const AppChipList({required this.items, super.key, this.icon});

  final List<String> items;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: <Widget>[
      for (final String item in items) AppChip(label: item, icon: icon, filled: false),
    ],
  );
}

/// Bulleted list used for rules and required documents.
class AppBulletList extends StatelessWidget {
  const AppBulletList({required this.items, super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final String item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: URow(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                UContainer(width: 5, height: 5, radius: 3, color: scheme.primary, margin: const EdgeInsets.only(top: 8)),
                const SizedBox(width: 10),
                UTextBodyMedium(item, color: scheme.onSurface, expanded: 1),
              ],
            ),
          ),
      ],
    );
  }
}

/// Score plus review count, shown on cards and detail headers.
class AppRating extends StatelessWidget {
  const AppRating({required this.score, required this.count, super.key, this.compact = false});

  final double score;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    if (count == 0) return UTextBodySmall(U.s.noReviewsYet, color: scheme.onSurfaceVariant);
    return URow(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
        const SizedBox(width: 4),
        UTextTitleSmall(score.toStringAsFixed(1).toPersianNumber(), color: scheme.onSurface),
        if (!compact) ...<Widget>[
          const SizedBox(width: 6),
          UTextBodySmall("(${count.toString().toPersianNumber()})", color: scheme.onSurfaceVariant),
        ],
      ],
    );
  }
}

/// Price with its unit, aligned so the number reads first.
class AppPrice extends StatelessWidget {
  const AppPrice({required this.amount, super.key, this.caption, this.large = false});

  final double? amount;
  final String? caption;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        large
            ? UTextHeadlineSmall(money(amount), color: scheme.onSurface)
            : UTextTitleMedium(money(amount), color: scheme.onSurface),
        if (caption != null) UTextLabelSmall(caption!, color: scheme.onSurfaceVariant),
      ],
    );
  }
}

/// Empty and error placeholders sized for both a full page and a section.
class AppEmpty extends StatelessWidget {
  const AppEmpty({required this.title, super.key, this.icon = Icons.inbox_outlined, this.subtitle, this.actionTitle, this.onAction});

  final String title;
  final IconData icon;
  final String? subtitle;
  final String? actionTitle;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UIconBackground(icon, color: scheme.primary, size: 48),
        const SizedBox(height: 14),
        UTextTitleSmall(title, color: scheme.onSurface, textAlign: TextAlign.center),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 6),
          UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
        ],
        if (actionTitle != null && onAction != null) ...<Widget>[
          const SizedBox(height: 16),
          UButton(title: actionTitle, onTap: onAction),
        ],
      ],
    ).pAll(28);
  }
}

/// Renders the four states a loaded section can be in, so pages stay short.
class AppStateView extends StatelessWidget {
  const AppStateView({required this.state, required this.onLoaded, required this.onRetry, super.key, this.emptyTitle, this.emptyIcon = Icons.inbox_outlined, this.loadingHeight = 180});

  final RxState state;
  final WidgetBuilder onLoaded;
  final VoidCallback onRetry;
  final String? emptyTitle;
  final IconData emptyIcon;
  final double loadingHeight;

  @override
  Widget build(BuildContext context) => Obx(() {
    if (state.isLoading() || state.isInitial())
      return SizedBox(height: loadingHeight, child: const UProgressCircular(size: 34, strokeWidth: 3).alignAtCenter());
    if (state.isError()) return UErrorRetry(onTap: onRetry);
    if (state.isEmpty()) return AppEmpty(title: emptyTitle ?? U.s.noData, icon: emptyIcon);
    return onLoaded(context);
  });
}
