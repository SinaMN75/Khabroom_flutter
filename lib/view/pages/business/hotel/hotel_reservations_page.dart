import "package:khabroom/main.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/business/hotel/hotel_reservation_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

enum _BookingTab { upcoming, staying, past }

/// All bookings of the hotel: coming, staying now, and finished.
class HotelReservationsPage extends StatefulWidget {
  const HotelReservationsPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelReservationsPage> createState() => _HotelReservationsPageState();
}

class _HotelReservationsPageState extends State<HotelReservationsPage> {
  final URxState state = URxState();
  final TextEditingController search = TextEditingController();
  List<UHotelReservationResponse> list = <UHotelReservationResponse>[];
  _BookingTab tab = _BookingTab.upcoming;

  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    search.dispose();
    super.dispose();
  }

  String _title(_BookingTab t) => switch (t) {
    _BookingTab.upcoming => U.s.upcoming,
    _BookingTab.staying => U.s.staying,
    _BookingTab.past => U.s.past,
  };

  Future<void> read() async {
    state.loading();
    final UResponse<List<UHotelReservationResponse>>? r = (await UServices.hotel.readHotelReservations(
      p: UHotelReservationReadParams(
        hotelId: widget.hotelId,
        upcomingOnly: tab == _BookingTab.upcoming ? true : null,
        activeOnly: tab == _BookingTab.staying ? true : null,
        pastOnly: tab == _BookingTab.past ? true : null,
        userName: search.text.trim().isEmpty ? null : search.text.trim(),
        pageSize: 200,
        pageNumber: 1,
        selectorArgs: const UHotelReservationSelectorArgs(user: UUserSelectorArgs(), room: UHotelRoomSelectorArgs()),
      ),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = (r.result ?? <UHotelReservationResponse>[])..sort((UHotelReservationResponse a, UHotelReservationResponse b) => tab == _BookingTab.past ? b.checkInDate.compareTo(a.checkInDate) : a.checkInDate.compareTo(b.checkInDate));
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.bookings).help("app.bookings.page", inline: true), actions: const <Widget>[UHelpActions("app.bookings.")]),
    body: UColumn(
      children: <Widget>[
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            UTextField(controller: search, hintText: U.s.searchByName, prefix: const Icon(Icons.search_rounded), onFieldSubmitted: (_) => read()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final _BookingTab t in _BookingTab.values)
                  ChoiceChip(label: Text(_title(t)), selected: tab == t, onSelected: (_) {
                    setState(() => tab = t);
                    read();
                  }),
              ],
            ),
          ],
        ).pSymmetric(horizontal: 16, vertical: 10),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.noBookingsHere,
            emptyIcon: Icons.event_note_outlined,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UHotelReservationResponse r in list)
                        AppTile(
                          icon: Icons.person_outline_rounded,
                          title: r.jsonData.guestName ?? "${r.user?.firstName ?? ""} ${r.user?.lastName ?? ""}".trim(),
                          subtitle: "${r.room?.title ?? ""} · ${r.checkInDate.toJalaliDate().toPersianNumber()} → ${r.checkOutDate.toJalaliDate().toPersianNumber()} · ${money(r.totalPrice)}",
                          trailing: AppStatusChip(status: AppStatus.reservation(r.tags)),
                          onTap: () => UNavigator.push(HotelReservationPage(reservationId: r.id)).then((_) => read()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
