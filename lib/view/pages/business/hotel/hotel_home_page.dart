import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/hotel/hotel_audit_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_board_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_housekeeping_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_new_reservation_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_rates_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_reservation_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_reservations_page.dart";
import "package:khabroom/view/pages/business/hotel/hotel_rooms_page.dart";
import "package:khabroom/view/pages/business/places/place_form.dart";
import "package:khabroom/view/pages/business/places/place_photos_page.dart";
import "package:khabroom/view/pages/business/shared/reviews_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// Today at the hotel: who arrives, who leaves, who is staying and which rooms need cleaning.
class HotelHomePage extends StatefulWidget {
  const HotelHomePage({required this.place, super.key});

  final AppPlace place;

  @override
  State<HotelHomePage> createState() => _HotelHomePageState();
}

class _HotelHomePageState extends State<HotelHomePage> {
  final URxState state = URxState();
  UHotelNightAuditResponse? today;

  String get id => widget.place.id;

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
    today = (await UServices.hotel.readNightAudit(p: UHotelNightAuditParams(hotelId: id, date: DateTime.now()))).$1?.result;
    if (mounted) setState(() {});
    state.loaded();
  }

  Widget _list(BuildContext context, String title, IconData icon, List<UHotelAuditItem> items) => items.isEmpty
      ? const SizedBox.shrink()
      : UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppLabel("$title · ${items.length.toString().toPersianNumber()}"),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UColumn(
                children: <Widget>[
                  for (final UHotelAuditItem i in items)
                    AppTile(
                      icon: icon,
                      title: i.guestName ?? U.s.guest,
                      subtitle: <String>[?i.roomTitle, ?i.roomNumber, if (i.balance > 0) "${U.s.remaining} ${money(i.balance)}"].join(" · "),
                      onTap: () => UNavigator.push(HotelReservationPage(reservationId: i.reservationId)).then((_) => read()),
                    ),
                ],
              ),
            ),
          ],
        );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.place.title).help("app.hotel.page", inline: true),
      actions: <Widget>[
        if (AppWorkspace.can(TagUser.permissionManageHotels, placeId: widget.place.id)) IconButton(icon: const Icon(Icons.edit_outlined), tooltip: U.s.edit, onPressed: () => PlaceForm.show(AppKind.hotel, place: widget.place).then((bool ok) => ok ? read() : null)),
        const UHelpActions("app.hotel."),
      ],
    ),
    floatingActionButton: AppWorkspace.can(TagUser.permissionManageReservations, placeId: id)
        ? FloatingActionButton.extended(onPressed: () => UNavigator.push(HotelNewReservationPage(hotelId: id)).then((_) => read()), icon: const Icon(Icons.add_rounded), label: Text(U.s.newBooking)).help("app.hotel.new")
        : null,
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UHotelNightAuditResponse? t = today;
        return AppPageBody(
          onRefresh: read,
          children: <Widget>[
            if (widget.place.pending) AppCard(child: AppTile(icon: Icons.hourglass_top_rounded, title: U.s.waitingForApproval, subtitle: U.s.newPlacesAreShownToCustomersAfterKhabroomApprovesThem)).pOnly(bottom: 12),
            if (t != null)
              AppGrid(
                columns: 4,
                spacing: 10,
                children: <Widget>[
                  AppStat(label: U.s.occupancy, value: "${(t.occupancy * (t.occupancy <= 1 ? 100 : 1)).round().toString().toPersianNumber()}٪", icon: Icons.king_bed_outlined),
                  AppStat(label: U.s.arrivals, value: t.arrivals.length.toString().toPersianNumber(), icon: Icons.login_rounded, tone: AppTone.positive),
                  AppStat(label: U.s.departures, value: t.departures.length.toString().toPersianNumber(), icon: Icons.logout_rounded, tone: AppTone.warning),
                  AppStat(label: U.s.toClean, value: t.dirtyUnits.length.toString().toPersianNumber(), icon: Icons.cleaning_services_outlined, tone: t.dirtyUnits.isEmpty ? AppTone.neutral : AppTone.danger),
                ],
              ).help("app.hotel.stats"),
            const SizedBox(height: 16),
            AppGrid(
              columns: 3,
              spacing: 10,
              children: <Widget>[
                AppFeatureTile(title: U.s.bookings, icon: Icons.event_note_outlined, onTap: () => UNavigator.push(HotelReservationsPage(hotelId: id)).then((_) => read())),
                AppFeatureTile(title: U.s.board, icon: Icons.calendar_view_week_outlined, onTap: () => UNavigator.push(HotelBoardPage(hotelId: id))),
                AppFeatureTile(title: U.s.housekeeping, icon: Icons.cleaning_services_outlined, onTap: () => UNavigator.push(HotelHousekeepingPage(hotelId: id)).then((_) => read())),
                AppFeatureTile(title: U.s.rooms, icon: Icons.meeting_room_outlined, onTap: () => UNavigator.push(HotelRoomsPage(hotelId: id))),
                AppFeatureTile(title: U.s.pricesAndClosedDays, icon: Icons.sell_outlined, onTap: () => UNavigator.push(HotelRatesPage(hotelId: id))),
                AppFeatureTile(title: U.s.closeTheDay, icon: Icons.nightlight_outlined, onTap: () => UNavigator.push(HotelAuditPage(hotelId: id)).then((_) => read())),
                AppFeatureTile(title: U.s.photos, icon: Icons.photo_library_outlined, onTap: () => UNavigator.push(PlacePhotosPage(place: widget.place))),
                AppFeatureTile(title: U.s.reviews, icon: Icons.rate_review_outlined, onTap: () => UNavigator.push(ReviewsPage(place: widget.place))),
              ],
            ).help("app.hotel.tiles"),
            if (t != null) ...<Widget>[
              _list(context, U.s.arrivingToday, Icons.login_rounded, t.arrivals),
              _list(context, U.s.leavingToday, Icons.logout_rounded, t.departures),
              _list(context, U.s.staying, Icons.hotel_outlined, t.inHouse),
            ],
            const SizedBox(height: 80),
          ],
        );
      },
    ),
  );
}
