import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/money/settlement_page.dart";
import "package:khabroom/view/pages/business/places/place_home_page.dart";
import "package:khabroom/view/pages/business/team/tasks_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// What needs attention today: the shift, open tasks, money waiting for payout and each place at a glance.
class TodayPage extends StatefulWidget {
  const TodayPage({super.key});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  final URxState state = URxState();
  UStaffShiftResponse? shift;
  List<UStaffTaskResponse> tasks = <UStaffTaskResponse>[];
  UDormDashboardResponse? dorm;
  UHotelDashboardResponse? hotel;
  int newOrders = 0;

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
    final UOrganizationResponse o = AppWorkspace.org;
    final DateTime today = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    await AppWorkspace.loadPlaces();
    shift = (await UServices.organization.readShifts(p: UStaffShiftReadParams(organizationId: o.id, userId: U.user.id, fromDate: today, toDate: today.add(const Duration(days: 1)), pageSize: 1, pageNumber: 1))).$1?.result?.firstOrNull;
    tasks = ((await UServices.organization.readTasks(p: UStaffTaskReadParams(organizationId: o.id, mine: true, pageSize: 10, pageNumber: 1))).$1?.result ?? <UStaffTaskResponse>[])
        .where((UStaffTaskResponse t) => t.doneAt == null)
        .toList();
    final bool dashboard = AppWorkspace.can(TagUser.permissionViewDashboard);
    dorm = dashboard && AppWorkspace.placesOf(AppKind.dorm).isNotEmpty ? (await UServices.dorm.readDormDashboard(p: UDashboardRangeParams(organizationId: o.id))).$1?.result : null;
    hotel = dashboard && AppWorkspace.placesOf(AppKind.hotel).isNotEmpty ? (await UServices.hotel.readHotelDashboard(p: UDashboardRangeParams(organizationId: o.id))).$1?.result : null;
    newOrders = AppWorkspace.placesOf(AppKind.cafe).isEmpty
        ? 0
        : (await UServices.cafe.readOrders(p: UMenuOrderReadParams(manage: true, organizationId: o.id, tags: <int>[TagMenuOrder.paid.number], pageSize: 1, pageNumber: 1))).$1?.totalCount ?? 0;
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _clock() async {
    if (shift == null) return;
    if (await appSend(UServices.organization.clockShift(p: UIdParams(id: shift!.id)))) await read();
  }

  @override
  Widget build(BuildContext context) {
    final UOrganizationResponse o = AppWorkspace.org;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<AppPlace> places = AppWorkspace.myPlaces;
    return UScaffold(
      appBar: businessAppBar(context, o.title, help: "app.today.page"),
      body: AppStateView(
        state: state,
        onRetry: read,
        onLoaded: (BuildContext context) => AppPageBody(
          onRefresh: read,
          children: <Widget>[
            UTextBodySmall("${U.s.welcome} ${U.user.firstName ?? ""} · ${AppWorkspace.roleOf(o)}", color: scheme.onSurfaceVariant),
            UTextHeadlineMedium(U.s.whatsHappeningToday),
            const SizedBox(height: 16),
            if (o.subscriptionEndsAt != null && o.subscriptionEndsAt!.difference(DateTime.now()).inDays < 10)
              AppCard(
                child: AppTile(
                  icon: Icons.workspace_premium_outlined,
                  iconColor: AppColors.warning,
                  title: U.s.yourSubscriptionEndsSoon,
                  subtitle: "${U.s.endsOn} ${o.subscriptionEndsAt!.toJalaliDate().toPersianNumber()}",
                ),
              ).pOnly(bottom: 12).help("app.today.subscription"),
            if (shift != null) _shiftCard(context).pOnly(bottom: 12),
            AppGrid(
              columns: 2,
              spacing: 12,
              children: <Widget>[
                if (AppWorkspace.isOwner)
                  AppStat(label: U.s.waitingForPayout, value: money(o.balance), icon: Icons.account_balance_outlined, onTap: () => UNavigator.push(const SettlementPage())).help("app.today.payout"),
                if (dorm != null) AppStat(label: U.s.dormOccupancy, value: "${dorm!.dormOccupancyRate.round().toString().toPersianNumber()}٪", caption: "${dorm!.dormBedsAvailableCount.toString().toPersianNumber()} ${U.s.freeBeds}", icon: Icons.bed_outlined),
                if (dorm != null) AppStat(label: U.s.unpaidBills, value: dorm!.overdueInvoicesCount.toString().toPersianNumber(), caption: money(dorm!.totalOutstanding), icon: Icons.receipt_outlined, tone: AppTone.danger),
                if (hotel != null) AppStat(label: U.s.hotelOccupancy, value: "${hotel!.hotelOccupancyRate.round().toString().toPersianNumber()}٪", caption: "${hotel!.hotelRoomsAvailableCount.toString().toPersianNumber()} ${U.s.freeRooms}", icon: Icons.king_bed_outlined),
                if (AppWorkspace.placesOf(AppKind.cafe).isNotEmpty) AppStat(label: U.s.newOrders, value: newOrders.toString().toPersianNumber(), icon: Icons.notifications_active_outlined, tone: newOrders > 0 ? AppTone.warning : AppTone.brand),
              ],
            ),
            if (tasks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              AppLabel(U.s.myTasks, action: U.s.all, onAction: () => UNavigator.push(const TasksPage(mine: true))),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: UColumn(
                  children: <Widget>[
                    for (final UStaffTaskResponse t in tasks.take(5))
                      AppTile(
                        icon: Icons.task_alt_rounded,
                        title: t.title,
                        subtitle: <String>[?t.location, if (t.dueDate != null) t.dueDate!.toJalaliDate().toPersianNumber()].join(" · "),
                        onTap: () => UNavigator.push(const TasksPage(mine: true)).then((_) => read()),
                      ),
                  ],
                ),
              ).help("app.today.tasks"),
            ],
            const SizedBox(height: 8),
            AppLabel(U.s.myPlaces),
            if (places.isEmpty)
              AppCard(child: AppEmpty(title: U.s.noPlacesYet, subtitle: AppWorkspace.isOwner ? U.s.addYourFirstPlaceFromThePlacesTab : U.s.theOwnerHasNotGivenYouAccessToAnyPlaceYet, icon: Icons.storefront_outlined))
            else
              AppGrid(
                children: <Widget>[
                  for (final AppPlace p in places)
                    Theme(
                      data: p.kind.theme(context),
                      child: AppFeatureTile(
                        title: p.title,
                        subtitle: p.pending ? U.s.waitingForApproval : p.rejected ? U.s.notApproved : p.kind.title,
                        icon: p.kind.icon,
                        badge: p.pending ? U.s.inReview : null,
                        onTap: () => UNavigator.push(PlaceHomePage(place: p)),
                      ),
                    ),
                ],
              ).help("app.today.places"),
          ],
        ),
      ),
    );
  }

  Widget _shiftCard(BuildContext context) {
    final UStaffShiftResponse s = shift!;
    final bool inside = s.checkedInAt != null && s.checkedOutAt == null;
    final bool done = s.checkedOutAt != null;
    return AppCard(
      child: URow(
        children: <Widget>[
          UColumn(
            expanded: 1,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextTitleSmall(U.s.yourShiftToday),
              UTextBodySmall("${s.startAt.toLocal().toTimeString()} - ${s.endAt.toLocal().toTimeString()}".toPersianNumber(), color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
          if (!done) UButton(title: inside ? U.s.clockOut : U.s.clockIn, onTap: _clock) else AppChip(label: U.s.shiftDone, tone: AppTone.positive),
        ],
      ),
    ).help("app.today.shift");
  }
}

extension on DateTime {
  String toTimeString() => "${hour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}";
}
