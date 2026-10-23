import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/setup/create_business_page.dart";
import "package:khabroom/view/pages/workspace/workspace_sheet.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The way into the business side: every business this person owns or works in, and starting a new one.
class MyBusinessesCard extends StatefulWidget {
  const MyBusinessesCard({super.key});

  @override
  State<MyBusinessesCard> createState() => _MyBusinessesCardState();
}

class _MyBusinessesCardState extends State<MyBusinessesCard> {
  bool loading = false;

  @override
  void initState() {
    read();
    super.initState();
  }

  Future<void> read() async {
    if (AppSession.isGuest) return;
    setState(() => loading = true);
    await AppWorkspace.load();
    if (mounted) setState(() => loading = false);
  }

  static void create() => AppSession.require(() => UNavigator.push(const CreateBusinessPage()));

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<UOrganizationResponse> list = AppSession.isGuest ? <UOrganizationResponse>[] : AppWorkspace.organizations;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          URow(
            children: <Widget>[
              UTextTitleMedium(U.s.myBusinesses, expanded: 1),
              if (loading) const UProgressCircular(size: 16, strokeWidth: 2),
            ],
          ).pSymmetric(horizontal: 4, vertical: 6),
          for (final UOrganizationResponse o in list)
            AppTile(
              icon: AppWorkspace.kindOf(o).icon,
              iconColor: AppWorkspace.kindOf(o).color,
              title: o.title,
              subtitle: AppWorkspace.roleOf(o),
              onTap: () => WorkspaceSheet.enter(o),
            ),
          if (list.isEmpty && !loading)
            UTextBodySmall(U.s.doYouRunAHotelOrADormManageItHereReservationsResidentsBillsAndPayouts, color: scheme.onSurfaceVariant, maxLines: 3).pSymmetric(horizontal: 4, vertical: 4),
          AppTile(
            icon: Icons.add_business_outlined,
            iconColor: scheme.onSurfaceVariant,
            title: list.isEmpty ? U.s.registerYourBusiness : U.s.newBusiness,
            subtitle: U.s.dormOrHotelStartWithAFreeTrial,
            onTap: create,
          ),
        ],
      ),
    ).help("app.profile.businesses");
  }
}
