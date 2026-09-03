import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/contracts/my_contracts_page.dart";
import "package:khabroom/view/pages/notifications/notification_page.dart";
import "package:khabroom/view/pages/profile/personal_info/personal_info_page.dart";
import "package:khabroom/view/pages/profile/profile_controller.dart";
import "package:khabroom/view/pages/reservations/reservations_page.dart";
import "package:khabroom/view/pages/wallet/wallet_page.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileController c = ProfileController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    body: RefreshIndicator(
      onRefresh: c.init,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth + 160,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _identityCard(context),
              const SizedBox(height: 16),
              _walletCard(context),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _MenuRow(icon: Icons.confirmation_number_outlined, title: U.s.myReservations, onTap: () => UNavigator.push(const ReservationsPage())),
                    _MenuRow(icon: Icons.assignment_outlined, title: U.s.dormContracts, onTap: () => UNavigator.push(const MyContractsPage())),
                    _MenuRow(icon: Icons.person_outline_rounded, title: U.s.personalInformation, onTap: () => UNavigator.push(const PersonalInfoPage())),
                    _MenuRow(icon: Icons.notifications_none_rounded, title: U.s.notifications, onTap: () => UNavigator.push(const NotificationPage())),
                    _MenuRow(icon: Icons.dark_mode_outlined, title: U.s.theme, onTap: () => UApp.isDarkTheme() ? UApp.toLightMode() : UApp.toDarkMode(), showDivider: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              UButton(
                title: U.s.logout,
                type: UButtonType.outlined,
                icon: const Icon(Icons.logout_rounded),
                foregroundColor: Theme.of(context).colorScheme.error,
                borderColor: Theme.of(context).colorScheme.error,
                fullWidth: true,
                onTap: c.logout,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _identityCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String name = "${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim();
    return AppCard(
      child: URow(
        children: <Widget>[
          UContainer(
            width: 52,
            height: 52,
            radius: 17,
            alignment: Alignment.center,
            color: scheme.primaryContainer,
            child: UTextTitleLarge(name.isEmpty ? "?" : name.substring(0, 1), color: scheme.primary),
          ),
          const SizedBox(width: 14),
          UColumn(
            expanded: 1,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextTitleLarge(name.isEmpty ? U.s.user : name, color: scheme.onSurface),
              const SizedBox(height: 5),
              UTextBodySmall(U.user.phoneNumber?.toPersianNumber() ?? "", color: scheme.onSurfaceVariant, textDirection: TextDirection.ltr),
            ],
          ),
          UButton(type: UButtonType.icon, icon: const Icon(Icons.edit_outlined), onTap: () => UNavigator.push(const PersonalInfoPage())),
        ],
      ),
    );
  }

  Widget _walletCard(BuildContext context) => UContainer(
    radius: 18,
    padding: const EdgeInsets.all(18),
    gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
    onTap: () => UNavigator.push(const WalletPage()),
    child: URow(
      children: <Widget>[
        UColumn(
          expanded: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextLabelMedium(U.s.walletBalance, color: AppColors.onGradient.withValues(alpha: 0.85)),
            const SizedBox(height: 8),
            Obx(
              () => c.walletState.isLoaded()
                  ? UTextHeadlineSmall(money(c.walletBalance), color: AppColors.onGradient)
                  : const UProgressCircular(size: 22, strokeWidth: 2, progressColor: AppColors.onGradient),
            ),
          ],
        ),
        Icon(Icons.account_balance_wallet_outlined, color: AppColors.onGradient.withValues(alpha: 0.9)),
      ],
    ),
  );
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.onTap, this.showDivider = true});

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        URow(
          children: <Widget>[
            Icon(icon, size: 19, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            UTextBodyLarge(title, color: scheme.onSurface, expanded: 1),
            Icon(Icons.chevron_left_rounded, size: 20, color: scheme.onSurfaceVariant),
          ],
        ).pSymmetric(horizontal: 14, vertical: 14).onTapInk(onTap),
        if (showDivider) Divider(color: scheme.outlineVariant, height: 1, indent: 14, endIndent: 14),
      ],
    );
  }
}
