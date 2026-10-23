import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/team/customers_page.dart";
import "package:khabroom/view/pages/business/team/member_page.dart";
import "package:khabroom/view/pages/business/team/shifts_page.dart";
import "package:khabroom/view/pages/business/team/tasks_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// The people who work here and what each may do; shifts and tasks are one tap away.
class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  static bool get allowed => AppWorkspace.isOwner || AppWorkspace.can(TagUser.permissionManageStaff);

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final URxState state = URxState();
  List<UUserResponse> people = <UUserResponse>[];

  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  Future<void> read() async {
    state.loading();
    await AppWorkspace.refresh();
    final UOrganizationResponse o = AppWorkspace.org;
    final List<String> ids = <String>[o.ownerId, ...o.jsonData.members.map((UOrganizationMember m) => m.userId)];
    people = (await UServices.user.read(p: UUserReadParams(ids: ids, pageSize: 200, pageNumber: 1))).$1?.result ?? <UUserResponse>[];
    people.sort((UUserResponse a, UUserResponse b) => a.id == o.ownerId ? -1 : b.id == o.ownerId ? 1 : 0);
    if (mounted) setState(() {});
    state.loaded();
  }

  String _summary(UUserResponse u) {
    final UOrganizationResponse o = AppWorkspace.org;
    if (u.id == o.ownerId) return U.s.ownerEverything;
    final UOrganizationMember? m = o.jsonData.members.where((UOrganizationMember x) => x.userId == u.id).firstOrNull;
    if (m == null) return "";
    final List<String> places = m.places.map((UOrganizationMemberPlace p) => AppWorkspace.places.where((AppPlace x) => x.id == p.placeId).firstOrNull?.title).whereType<String>().toList();
    return <String>[AppWorkspace.roleOfMember(m), if (places.isNotEmpty) places.join("، ")].join(" · ");
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: businessAppBar(context, U.s.team, help: "app.team.page"),
    floatingActionButton: AppWorkspace.isOwner ? FloatingActionButton.extended(onPressed: () => UNavigator.push(const MemberPage()).then((_) => read()), icon: const Icon(Icons.person_add_alt_1_outlined), label: Text(U.s.addStaff)).help("app.team.add") : null,
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppGrid(
            columns: 2,
            spacing: 12,
            children: <Widget>[
              AppFeatureTile(title: U.s.shifts, subtitle: U.s.whoWorksWhen, icon: Icons.schedule_outlined, onTap: () => UNavigator.push(const ShiftsPage())),
              AppFeatureTile(title: U.s.tasks, subtitle: U.s.repairsCleaningAndToDos, icon: Icons.task_alt_rounded, onTap: () => UNavigator.push(const TasksPage())),
              if (CustomersPage.allowed) AppFeatureTile(title: U.s.customers, subtitle: U.s.vipAndBlacklist, icon: Icons.people_outline_rounded, onTap: () => UNavigator.push(const CustomersPage())),
            ],
          ),
          AppLabel("${U.s.people} · ${people.length.toString().toPersianNumber()}"),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UUserResponse u in people)
                  AppTile(
                    icon: u.id == AppWorkspace.org.ownerId ? Icons.workspace_premium_outlined : Icons.badge_outlined,
                    title: "${u.firstName ?? ""} ${u.lastName ?? ""}".trim().isEmpty ? (u.phoneNumber ?? "-").toPersianNumber() : "${u.firstName ?? ""} ${u.lastName ?? ""}",
                    subtitle: _summary(u),
                    onTap: AppWorkspace.isOwner && u.id != AppWorkspace.org.ownerId ? () => UNavigator.push(MemberPage(user: u)).then((_) => read()) : null,
                  ),
              ],
            ),
          ).help("app.team.people"),
        ],
      ),
    ),
  );
}
