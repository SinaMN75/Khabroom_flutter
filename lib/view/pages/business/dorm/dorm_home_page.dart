import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/dorm/dorm_applications_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_bills_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_meals_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_new_contract_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_records_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_residents_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_rooms_page.dart";
import "package:khabroom/view/pages/business/places/place_form.dart";
import "package:khabroom/view/pages/business/places/place_photos_page.dart";
import "package:khabroom/view/pages/business/shared/reviews_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// A dorm at a glance: beds, residents, bills, and a tile for each part of running it.
class DormHomePage extends StatefulWidget {
  const DormHomePage({required this.place, super.key});

  final AppPlace place;

  @override
  State<DormHomePage> createState() => _DormHomePageState();
}

class _DormHomePageState extends State<DormHomePage> {
  final URxState state = URxState();
  UDormResponse? dorm;
  int pendingApplications = 0;
  int unpaid = 0;

  String get id => widget.place.id;

  bool can(TagUser p) => AppWorkspace.can(p, placeId: id);

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
    dorm = (await UServices.dorm.readDormById(p: UIdParams(id: id))).$1?.result;
    pendingApplications = ((await UServices.dorm.readApplications(p: UDormApplicationReadParams(dormId: id, tags: <int>[TagDormApplication.pending.number], pageSize: 100, pageNumber: 1))).$1?.result ?? <UDormApplicationResponse>[]).length;
    unpaid = (await UServices.dorm.readDormBedInvoice(p: UDormBedInvoiceReadParams(dormId: id, isPaid: false, isOverdue: true, pageSize: 1, pageNumber: 1))).$1?.totalCount ?? 0;
    if (dorm == null) {
      state.error();
      return;
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.place.title).help("app.dorm.page", inline: true),
      actions: <Widget>[
        if (AppWorkspace.isOwner) IconButton(icon: const Icon(Icons.edit_outlined), tooltip: U.s.edit, onPressed: () => PlaceForm.show(AppKind.dorm, place: widget.place).then((bool ok) => ok ? read() : null)).help("app.dorm.edit"),
        const UHelpActions("app.dorm."),
      ],
    ),
    floatingActionButton: can(TagUser.permissionManageContracts)
        ? FloatingActionButton.extended(onPressed: () => UNavigator.push(DormNewContractPage(dormId: id)).then((_) => read()), icon: const Icon(Icons.person_add_alt_1_outlined), label: Text(U.s.newResident)).help("app.dorm.newResident")
        : null,
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UDormResponse d = dorm!;
        final int occupied = d.bedCount - d.availableBedCount;
        return AppPageBody(
          onRefresh: read,
          children: <Widget>[
            if (widget.place.pending) AppCard(child: AppTile(icon: Icons.hourglass_top_rounded, title: U.s.waitingForApproval, subtitle: U.s.newPlacesAreShownToCustomersAfterKhabroomApprovesThem)).pOnly(bottom: 12),
            AppGrid(
              columns: 3,
              spacing: 10,
              children: <Widget>[
                AppStat(label: U.s.occupiedBeds, value: "${occupied.toString().toPersianNumber()}/${d.bedCount.toString().toPersianNumber()}", icon: Icons.bed_outlined),
                AppStat(label: U.s.freeBeds, value: d.availableBedCount.toString().toPersianNumber(), icon: Icons.event_available_outlined, tone: AppTone.positive),
                AppStat(label: U.s.overdueBills, value: unpaid.toString().toPersianNumber(), icon: Icons.receipt_long_outlined, tone: unpaid > 0 ? AppTone.danger : AppTone.neutral),
              ],
            ).help("app.dorm.stats"),
            const SizedBox(height: 18),
            AppGrid(
              columns: 2,
              spacing: 12,
              children: <Widget>[
                AppFeatureTile(title: U.s.roomsAndBeds, subtitle: U.s.whoSleepsWhere, icon: Icons.meeting_room_outlined, onTap: () => UNavigator.push(DormRoomsPage(dormId: id)).then((_) => read())),
                AppFeatureTile(title: U.s.residents, subtitle: U.s.contractsAndCheckOut, icon: Icons.people_outline_rounded, onTap: () => UNavigator.push(DormResidentsPage(dormId: id)).then((_) => read())),
                AppFeatureTile(
                  title: U.s.applications,
                  subtitle: U.s.peopleWhoWantToStay,
                  icon: Icons.how_to_reg_outlined,
                  badge: pendingApplications > 0 ? pendingApplications.toString().toPersianNumber() : null,
                  onTap: () => UNavigator.push(DormApplicationsPage(dormId: id)).then((_) => read()),
                ),
                AppFeatureTile(title: U.s.bills, subtitle: U.s.rentAndPayments, icon: Icons.receipt_long_outlined, onTap: () => UNavigator.push(DormBillsPage(dormId: id)).then((_) => read())),
                AppFeatureTile(title: U.s.records, subtitle: U.s.visitorsLeavesAndNotices, icon: Icons.fact_check_outlined, onTap: () => UNavigator.push(DormRecordsPage(dormId: id))),
                AppFeatureTile(title: U.s.meals, subtitle: U.s.menuAndReservations, icon: Icons.restaurant_outlined, onTap: () => UNavigator.push(DormMealsPage(dormId: id))),
                AppFeatureTile(title: U.s.photos, subtitle: U.s.whatCustomersSee, icon: Icons.photo_library_outlined, onTap: () => UNavigator.push(PlacePhotosPage(place: widget.place))),
                AppFeatureTile(title: U.s.reviews, subtitle: U.s.whatResidentsSay, icon: Icons.rate_review_outlined, onTap: () => UNavigator.push(ReviewsPage(place: widget.place))),
              ],
            ).help("app.dorm.tiles"),
          ],
        );
      },
    ),
  );
}
