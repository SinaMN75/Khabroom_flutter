import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/contracts/my_contracts_page.dart";
import "package:khabroom/view/pages/home/home_page.dart";
import "package:khabroom/view/pages/profile/profile_page.dart";
import "package:khabroom/view/pages/reservations/reservations_page.dart";
import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:khabroom/view/pages/wallet/wallet_page.dart";
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
    AppDestination(id: "contracts", title: U.s.dormContracts, icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded),
    AppDestination(id: "wallet", title: U.s.wallet, icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded),
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
    AppShell.go(index);
    menu.select(_destinations[index].id);
  }

  @override
  Widget build(BuildContext context) {
    final bool compact = AppResponsive.isCompact(context);
    return Obx(
      () => UScaffold(
        safeArea: false,
        body: URow(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!compact) _sideMenu(context),
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
      showRailOnMobile: false,
      header: URow(
        children: <Widget>[
          const AppBrandMark(size: 36),
          const SizedBox(width: 10),
          UTextTitleLarge(AppConstants.appName, color: scheme.onPrimary, expanded: 1),
        ],
      ),
      profileName: "${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim(),
      profileSubtitle: U.user.phoneNumber,
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
        await ULocalStorage.clear();
        await UFileStorage.clear();
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
        BottomNavigationBarItem(
          icon: Icon(destination.icon, size: 21),
          activeIcon: Icon(destination.activeIcon, size: 21),
          label: destination.title,
        ),
    ],
  );
}

/// Kept out of the shell's Obx so switching tabs doesn't rebuild the pages themselves.
class _ShellPages extends StatelessWidget {
  const _ShellPages();

  @override
  Widget build(BuildContext context) => Obx(
    () => IndexedStack(
      index: AppShell.tabIndex.value,
      children: const <Widget>[
        HomePage(),
        ReservationsPage(),
        MyContractsPage(),
        WalletPage(),
        ProfilePage(),
      ],
    ),
  );
}
