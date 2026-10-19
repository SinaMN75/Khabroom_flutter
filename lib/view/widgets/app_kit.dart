import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// A tappable row: round icon, title, optional subtitle and trailing widget.
class AppTile extends StatelessWidget {
  const AppTile({required this.title, super.key, this.subtitle, this.icon, this.iconColor, this.trailing, this.onTap, this.dense = false});

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color color = iconColor ?? scheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: dense ? 8 : 11),
        child: URow(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              UContainer(width: 40, height: 40, radius: 13, color: color.withValues(alpha: 0.12), alignment: Alignment.center, child: Icon(icon, size: 20, color: color)),
              const SizedBox(width: 12),
            ],
            UColumn(
              expanded: 1,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextTitleSmall(title, maxLines: 2),
                if (subtitle != null && subtitle!.isNotEmpty) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant, maxLines: 2),
              ],
            ),
            if (trailing != null) ...<Widget>[const SizedBox(width: 8), trailing!] else if (onTap != null) Icon(Icons.chevron_left_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

/// A big number with its caption, used on every "today" page.
class AppStat extends StatelessWidget {
  const AppStat({required this.label, required this.value, super.key, this.icon, this.tone = AppTone.brand, this.onTap, this.caption});

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final AppTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              if (icon != null) ...<Widget>[Icon(icon, size: 16, color: tone.foreground(context)), const SizedBox(width: 6)],
              UTextBodySmall(label, color: scheme.onSurfaceVariant, expanded: 1, maxLines: 1),
            ],
          ),
          const SizedBox(height: 6),
          UTextHeadlineSmall(value, color: scheme.onSurface, maxLines: 1),
          if (caption != null) UTextLabelSmall(caption!, color: tone.foreground(context), maxLines: 1),
        ],
      ),
    );
  }
}

/// Square shortcut into one part of a place (rooms, residents, menu...).
class AppFeatureTile extends StatelessWidget {
  const AppFeatureTile({required this.title, required this.icon, required this.onTap, super.key, this.subtitle, this.badge});

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              UContainer(width: 38, height: 38, radius: 12, color: scheme.primaryContainer, alignment: Alignment.center, child: Icon(icon, size: 20, color: scheme.primary)),
              const Spacer(),
              if (badge != null) AppChip(label: badge!, tone: AppTone.warning),
            ],
          ),
          const SizedBox(height: 12),
          UTextTitleSmall(title, maxLines: 1),
          if (subtitle != null) UTextBodySmall(subtitle!, color: scheme.onSurfaceVariant, maxLines: 2),
        ],
      ),
    );
  }
}

/// Shown instead of a personal page while the user is a guest.
class AppSignInPrompt extends StatelessWidget {
  const AppSignInPrompt({required this.title, super.key, this.icon = Icons.lock_outline_rounded, this.onSignedIn});

  final String title;
  final IconData icon;
  final VoidCallback? onSignedIn;

  @override
  Widget build(BuildContext context) => Center(
    child: AppEmpty(title: title, subtitle: U.s.signInWithYourPhoneNumberNoPasswordNeeded, icon: icon, actionTitle: U.s.signIn, onAction: () => AppSession.require(() => onSignedIn?.call())),
  );
}

/// A page body that waits for sign-in: guests see [AppSignInPrompt], signed-in users see [child].
class AppSignedIn extends StatelessWidget {
  const AppSignedIn({required this.title, required this.child, super.key, this.icon = Icons.lock_outline_rounded});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => UObx(() => AppSession.signedIn.value ? child : AppSignInPrompt(title: title, icon: icon));
}

/// A scrolling page body with the app's padding and width.
class AppPageBody extends StatelessWidget {
  const AppPageBody({required this.children, super.key, this.onRefresh, this.maxWidth});

  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final Widget list = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppResponsive.pagePadding(context),
      child: AppContent(
        maxWidth: maxWidth,
        child: UColumn(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      ),
    );
    return onRefresh == null ? list : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

/// Bottom-sheet form: fields, then one primary button. Returns true when [onSubmit] succeeded.
abstract class AppForm {
  static Future<bool> show({
    required String title,
    required List<Widget> Function(BuildContext context, StateSetter setState) children,
    required Future<bool> Function() onSubmit,
    String? submitTitle,
    String? help,
  }) async =>
      await UNavigator.bottomSheet<bool>(_AppFormSheet(title: title, builder: children, onSubmit: onSubmit, submitTitle: submitTitle, help: help), showDragHandle: true) ?? false;
}

class _AppFormSheet extends StatefulWidget {
  const _AppFormSheet({required this.title, required this.builder, required this.onSubmit, this.submitTitle, this.help});

  final String title;
  final List<Widget> Function(BuildContext context, StateSetter setState) builder;
  final Future<bool> Function() onSubmit;
  final String? submitTitle;
  final String? help;

  @override
  State<_AppFormSheet> createState() => _AppFormSheetState();
}

class _AppFormSheetState extends State<_AppFormSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool busy = false;

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final bool ok = await widget.onSubmit();
    if (!mounted) return;
    if (ok) {
      UNavigator.back(true);
      return;
    }
    setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    child: Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            widget.help == null ? UTextTitleLarge(widget.title) : UTextTitleLarge(widget.title).help(widget.help!, inline: true),
            const SizedBox(height: 14),
            ...widget.builder(context, setState).map((Widget w) => Padding(padding: const EdgeInsets.only(bottom: 10), child: w)),
            const SizedBox(height: 6),
            UButton(title: widget.submitTitle ?? U.s.save, isLoading: busy, onTap: busy ? null : _submit),
          ],
        ),
      ),
    ),
  );
}

/// Turns a service call's `(ok, error, exception)` into a toast and a bool.
Future<bool> appSend(Future<(dynamic, dynamic, String?)> call, {bool toast = true}) async {
  final (dynamic ok, dynamic error, String? exception) = await call;
  if (ok == null) {
    UToast.error(message: (error is UEmptyResponse ? error.message : error is UResponse ? error.message : null) ?? exception ?? U.s.error);
    return false;
  }
  if (toast) UToast.success(message: ok is UEmptyResponse && ok.message.isNotEmpty ? ok.message : U.s.done);
  return true;
}

/// Thin section title used inside long pages.
class AppLabel extends StatelessWidget {
  const AppLabel(this.text, {super.key, this.action, this.onAction});

  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => AppSectionHeader(title: text, actionTitle: action, onAction: onAction).pOnly(top: 8, bottom: 10);
}

/// A field with a number keyboard for money, shown in tomans but stored in rials.
class AppMoneyField extends StatelessWidget {
  const AppMoneyField({required this.controller, required this.label, super.key, this.required = true});

  final TextEditingController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => UTextField(
    controller: controller,
    labelText: "$label (${U.s.toman})",
    keyboardType: TextInputType.number,
    formatters: <TextInputFormatter>[UCurrencyInputFormatter()],
    validator: required ? UValidators.required<String>() : null,
  );
}

double tomanToRial(TextEditingController c) => c.numDouble() * 10;

String rialToTomanText(double? rial) => rial == null || rial == 0 ? "" : (rial / 10).round().toString().separateNumbers3By3();
