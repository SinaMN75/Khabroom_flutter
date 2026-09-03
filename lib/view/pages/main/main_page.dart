import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/home/home_page.dart";
import "package:khabroom/view/pages/notifications/notification_page.dart";
import "package:khabroom/view/pages/profile/profile_page.dart";
import "package:khabroom/view/pages/reservations/reservations_page.dart";
import "package:khabroom/view/widgets/widgets.dart";
import "package:u/utilities.dart";

class MainPage extends StatefulWidget {
  const MainPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainPage> createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  final RxInt selectedIndex = 0.obs;

  @override
  void initState() {
    selectedIndex(widget.initialIndex);
    super.initState();
  }

  List<_NavDestination> get _destinations => <_NavDestination>[
    _NavDestination(icon: Icons.holiday_village_outlined, activeIcon: Icons.holiday_village_rounded, label: U.s.accommodation),
    _NavDestination(icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number_rounded, label: U.s.myReservations),
    _NavDestination(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: U.s.profile),
  ];

  @override
  Widget build(BuildContext context) {
    final bool compact = AppResponsive.isCompact(context);
    return Obx(
      () => UScaffold(
        appBar: compact ? null : _TopBar(destinations: _destinations, selectedIndex: selectedIndex.value, onSelect: selectedIndex.call),
        body: IndexedStack(
          index: selectedIndex.value,
          children: const <Widget>[
            HomePage(),
            ReservationsPage(),
            ProfilePage(),
          ],
        ),
        bottomNavigationBar: compact ? _BottomBar(destinations: _destinations, selectedIndex: selectedIndex.value, onSelect: selectedIndex.call) : null,
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({required this.icon, required this.activeIcon, required this.label});

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.destinations, required this.selectedIndex, required this.onSelect});

  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      color: scheme.surface,
      border: Border(top: BorderSide(color: scheme.outlineVariant)),
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: SafeArea(
        top: false,
        child: URow(
          children: <Widget>[
            for (int i = 0; i < destinations.length; i++)
              UColumn(
                expanded: 1,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(i == selectedIndex ? destinations[i].activeIcon : destinations[i].icon, size: 22, color: i == selectedIndex ? scheme.primary : scheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  UTextLabelSmall(destinations[i].label, color: i == selectedIndex ? scheme.primary : scheme.onSurfaceVariant, fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500),
                ],
              ).pSymmetric(vertical: 6).onTap(() => onSelect(i)),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget implements PreferredSizeWidget {
  const _TopBar({required this.destinations, required this.selectedIndex, required this.onSelect});

  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      height: 68,
      color: scheme.surface,
      border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      child: AppContent(
        child: URow(
          children: <Widget>[
            const AppBrandMark(size: 34),
            const SizedBox(width: 10),
            UTextTitleLarge(AppConstants.appName, color: scheme.onSurface),
            const SizedBox(width: 28),
            for (int i = 0; i < destinations.length; i++)
              UContainer(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                radius: 11,
                color: i == selectedIndex ? scheme.primaryContainer : null,
                onTap: () => onSelect(i),
                child: URow(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(i == selectedIndex ? destinations[i].activeIcon : destinations[i].icon, size: 17, color: i == selectedIndex ? scheme.primary : scheme.onSurfaceVariant),
                    const SizedBox(width: 7),
                    UTextLabelLarge(destinations[i].label, color: i == selectedIndex ? scheme.primary : scheme.onSurfaceVariant, fontWeight: i == selectedIndex ? FontWeight.w700 : FontWeight.w500),
                  ],
                ),
              ),
            const Spacer(),
            UButton(
              type: UButtonType.icon,
              icon: const Icon(Icons.notifications_none_rounded),
              onTap: () => UNavigator.push(const NotificationPage()),
            ),
          ],
        ).pSymmetric(horizontal: 20),
      ),
    );
  }
}
