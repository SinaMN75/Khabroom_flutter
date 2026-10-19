import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/business/money/money_page.dart";
import "package:khabroom/view/pages/business/more/more_page.dart";
import "package:khabroom/view/pages/business/places/places_page.dart";
import "package:khabroom/view/pages/business/team/team_page.dart";
import "package:khabroom/view/pages/business/today/today_page.dart";
import "package:khabroom/view/pages/main/main_page.dart";
import "package:khabroom/view/pages/workspace/workspace_sheet.dart";
import "package:u/utilities.dart";

/// The business side of the app: one shell per business, coloured by its kind, showing only what this person may do.
class BusinessPage extends StatefulWidget {
  const BusinessPage({super.key});

  @override
  State<BusinessPage> createState() => _BusinessPageState();
}

class _BusinessPageState extends State<BusinessPage> {
  int index = 0;
  late final USideMenuController menu = USideMenuController(selectedId: "today");

  List<AppDestination> get _destinations => <AppDestination>[
    AppDestination(id: "today", title: U.s.today, icon: Icons.wb_sunny_outlined, activeIcon: Icons.wb_sunny_rounded),
    AppDestination(id: "places", title: U.s.places, icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded),
    if (MoneyPage.allowed) AppDestination(id: "money", title: U.s.money, icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded),
    if (TeamPage.allowed) AppDestination(id: "team", title: U.s.team, icon: Icons.groups_outlined, activeIcon: Icons.groups_rounded),
    AppDestination(id: "more", title: U.s.more, icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view_rounded),
  ];

  Widget _page(String id) => switch (id) {
    "places" => const PlacesPage(),
    "money" => const MoneyPage(),
    "team" => const TeamPage(),
    "more" => const MorePage(),
    _ => const TodayPage(),
  };

  @override
  void initState() {
    if (!AppWorkspace.isBusiness) delay(10, () => UNavigator.offAll(const MainPage()));
    super.initState();
  }

  @override
  void dispose() {
    menu.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => index = i);
    menu.select(_destinations[i].id);
  }

  @override
  Widget build(BuildContext context) {
    if (!AppWorkspace.isBusiness) return const UScaffold(body: SizedBox.shrink());
    final List<AppDestination> destinations = _destinations;
    if (index >= destinations.length) index = 0;
    final bool compact = AppResponsive.isCompact(context);
    final AppKind kind = AppWorkspace.kindOf(AppWorkspace.org);
    return Theme(
      data: kind.theme(context),
      child: Builder(
        builder: (BuildContext context) => UScaffold(
          safeArea: false,
          body: URow(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!compact)
                USideMenu(
                  controller: menu,
                  enableSearch: false,
                  enablePinning: false,
                  header: URow(
                    children: <Widget>[
                      UContainer(width: 36, height: 36, radius: 12, color: kind.color, alignment: Alignment.center, child: Icon(kind.icon, color: Colors.white, size: 20)),
                      const SizedBox(width: 10),
                      UTextTitleMedium(AppWorkspace.org.title, color: Theme.of(context).colorScheme.onPrimary, expanded: 1, maxLines: 1),
                    ],
                  ),
                  profileName: "${U.user.firstName ?? ""} ${U.user.lastName ?? ""}".trim(),
                  profileSubtitle: AppWorkspace.roleOf(AppWorkspace.org),
                  isDarkMode: UApp.isDarkTheme(),
                  onToggleTheme: (bool dark) {
                    dark ? UApp.toDarkMode() : UApp.toLightMode();
                    setState(() {});
                  },
                  profileMenuItems: <UMenuItem>[UMenuItem(id: "switch", title: U.s.whereDoYouWantToWork, icon: Icons.swap_horiz_rounded)],
                  onProfileMenuSelected: (_) => WorkspaceSheet.show(),
                  items: <UMenuEntry>[
                    for (int i = 0; i < destinations.length; i++)
                      UMenuItem(id: destinations[i].id, title: destinations[i].title, icon: destinations[i].icon, selectedIcon: destinations[i].activeIcon, pinnable: false, onTap: () => _select(i)),
                  ],
                ),
              Expanded(child: KeyedSubtree(key: ValueKey<String>(destinations[index].id), child: _page(destinations[index].id))),
            ],
          ),
          bottomNavigationBar: compact
              ? BottomNavigationBar(
                  currentIndex: index,
                  onTap: _select,
                  items: <BottomNavigationBarItem>[
                    for (final AppDestination d in destinations)
                      BottomNavigationBarItem(
                        icon: Icon(d.icon, size: 21).help("app.business.nav.${d.id}", inline: true),
                        activeIcon: Icon(d.activeIcon, size: 21),
                        label: d.title,
                      ),
                  ],
                )
              : null,
        ),
      ),
    );
  }
}

/// App bar every business page uses: the business name, and a quick way back to choosing a workspace.
AppBar businessAppBar(BuildContext context, String title, {List<Widget> actions = const <Widget>[], String? help}) => AppBar(
  title: help == null ? Text(title) : Text(title).help(help, inline: true),
  actions: <Widget>[
    ...actions,
    IconButton(icon: const Icon(Icons.swap_horiz_rounded), tooltip: U.s.whereDoYouWantToWork, onPressed: WorkspaceSheet.show),
    if (help != null) UHelpActions("${help.substring(0, help.lastIndexOf("."))}."),
    const SizedBox(width: 4),
  ],
);
