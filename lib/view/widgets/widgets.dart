import "package:khabroom/main.dart";
import "package:u/utilities.dart";

/// Brand mark used on the splash, login and verification screens.
class AppBrandMark extends StatelessWidget {
  const AppBrandMark({super.key, this.size = 52});

  final double size;

  @override
  Widget build(BuildContext context) => UContainer(
    width: size,
    height: size,
    radius: size / 3.2,
    alignment: Alignment.center,
    gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
    child: Icon(Icons.holiday_village_rounded, color: AppColors.onGradient, size: size * 0.5),
  );
}

/// Screen intro used at the top of the auth pages: mark, headline and a muted line of copy.
class AppAuthHeader extends StatelessWidget {
  const AppAuthHeader({required this.title, required this.subtitle, super.key, this.trailing});

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const AppBrandMark(),
        const SizedBox(height: 18),
        UTextHeadlineMedium(title, color: scheme.onSurface),
        const SizedBox(height: 8),
        UTextBodySmall(subtitle, color: scheme.onSurfaceVariant),
        if (trailing != null) ...<Widget>[const SizedBox(height: 10), trailing!],
      ],
    );
  }
}

/// Footnote with the terms and privacy links shown under the login action.
class AppLegalNote extends StatelessWidget {
  const AppLegalNote({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        UTextBodySmall(U.s.byContinuingYouAcceptTheTermsAndConditionsAndThePrivacyPolicy, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
        URow(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            UButton(
              title: U.s.termsAndConditions,
              type: UButtonType.text,
              textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary),
              onTap: () => ULaunch.url(AppConstants.termsUrl),
            ),
            UTextBodySmall("·", color: scheme.onSurfaceVariant),
            UButton(
              title: U.s.privacyPolicy,
              type: UButtonType.text,
              textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.primary),
              onTap: () => ULaunch.url(AppConstants.privacyUrl),
            ),
          ],
        ),
      ],
    );
  }
}
