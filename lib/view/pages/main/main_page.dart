import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/view/pages/home/home_page.dart";
import "package:khabroom/view/pages/payments/payments_page.dart";
import "package:khabroom/view/pages/profile/profile_page.dart";
import "package:khabroom/view/pages/reservations/reservations_page.dart";
import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:khabroom/view/pages/scan/scan_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

class AppDestination {
  const AppDestination({required this.id, required this.title, required this.icon, required this.activeIcon});

  final String id;
  final String title;
  final IconData icon;
  final IconData activeIcon;
}

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final USideMenuController menu;

  List<AppDestination> get _destinations => <AppDestination>[
    AppDestination(id: "home", title: U.s.accommodation, icon: Icons.holiday_village_outlined, activeIcon: Icons.holiday_village_rounded),
    AppDestination(id: "reservations", title: U.s.myReservations, icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number_rounded),
    AppDestination(id: "scan", title: U.s.scan, icon: Icons.qr_code_scanner_rounded, activeIcon: Icons.qr_code_scanner_rounded),
    AppDestination(id: "payments", title: U.s.myPayments, icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded),
    AppDestination(id: "profile", title: U.s.profile, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
  ];

  @override
  void initState() {
    AppShell.tabIndex(widget.initialIndex);
    menu = USideMenuController(selectedId: _destinations[widget.initialIndex].id);
    super.initState();
  }

  @override
  void dispose() {
    menu.dispose();
    super.dispose();
  }

  void _select(int index) {
    if (_destinations[index].id == "scan") {
      ScanPage.open();
      return;
    }
    AppShell.go(index);
    menu.select(_destinations[index].id);
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = AppResponsive.isCompact(context);
    return UObx(
      () => UScaffold(
        safeArea: false,
        body: URow(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (compact) const SizedBox.shrink() else _sideMenu(context),
            const Expanded(child: _ShellPages()),
          ],
        ),
        bottomNavigationBar: compact ? _bottomBar() : null,
      ),
    );
  }

  Widget _sideMenu(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return USideMenu(
      controller: menu,
      enableSearch: false,
      enablePinning: false,
      header: URow(
        children: <Widget>[
          const AppBrandMark(size: 36),
          const SizedBox(width: 10),
          UTextTitleLarge(AppConstants.appName, color: scheme.onPrimary, expanded: 1),
        ],
      ),
      profileName: AppSession.isGuest ? U.s.guest : "${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim(),
      profileSubtitle: AppSession.isGuest ? null : U.user.phoneNumber,
      isDarkMode: UApp.isDarkTheme(),
      onToggleTheme: (bool dark) {
        dark ? UApp.toDarkMode() : UApp.toLightMode();
        setState(() {});
      },
      profileMenuItems: <UMenuItem>[
        UMenuItem(id: "profile", title: U.s.personalInformation, icon: Icons.person_outline_rounded),
        UMenuItem(id: "logout", title: U.s.logout, icon: Icons.logout_rounded),
      ],
      onProfileMenuSelected: (String id) async {
        if (id == "profile") {
          _select(_destinations.length - 1);
          return;
        }
        await AppSession.signOut();
        await UNavigator.offAll(const SplashPage());
      },
      items: <UMenuEntry>[
        for (int i = 0; i < _destinations.length; i++)
          UMenuItem(
            id: _destinations[i].id,
            title: _destinations[i].title,
            icon: _destinations[i].icon,
            selectedIcon: _destinations[i].activeIcon,
            pinnable: false,
            onTap: () => _select(i),
          ),
      ],
    );
  }

  Widget _bottomBar() => BottomNavigationBar(
    currentIndex: AppShell.tabIndex.value,
    onTap: _select,
    items: <BottomNavigationBarItem>[
      for (final AppDestination destination in _destinations)
        destination.id == "scan"
            ? BottomNavigationBarItem(icon: const _ScanButton().help("app.home.nav.scan", inline: true), label: "")
            : BottomNavigationBarItem(
                icon: Icon(destination.icon, size: 21).help("app.home.nav.${destination.id}", inline: true),
                activeIcon: Icon(destination.activeIcon, size: 21).help("app.home.nav.${destination.id}", inline: true),
                label: destination.title,
              ),
    ],
  );
}

class _ScanButton extends StatelessWidget {
  const _ScanButton();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      width: 52,
      height: 52,
      radius: 18,
      alignment: Alignment.center,
      color: scheme.primary,
      boxShadow: <BoxShadow>[BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
      child: Icon(Icons.qr_code_scanner_rounded, color: scheme.onPrimary, size: 24),
    );
  }
}

/// Kept out of the shell's UObx so switching tabs doesn't rebuild the pages themselves.
class _ShellPages extends StatelessWidget {
  const _ShellPages();

  @override
  Widget build(BuildContext context) => UObx(
    () => IndexedStack(
      index: AppShell.tabIndex.value,
      children: <Widget>[
        const HomePage(),
        AppSignedIn(title: U.s.signInToSeeYourReservations, icon: Icons.confirmation_number_outlined, child: const ReservationsPage()),
        const SizedBox.shrink(),
        AppSignedIn(title: U.s.signInToSeeYourPayments, icon: Icons.receipt_long_outlined, child: const PaymentsPage()),
        const ProfilePage(),
      ],
    ),
  );
}
