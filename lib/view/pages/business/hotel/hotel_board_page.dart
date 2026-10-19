import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The next two weeks for every room type: how many are booked each night, what is still free, and the night's price.
class HotelBoardPage extends StatefulWidget {
  const HotelBoardPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelBoardPage> createState() => _HotelBoardPageState();
}

class _HotelBoardPageState extends State<HotelBoardPage> {
  final URxState state = URxState();
  List<UHotelRoomResponse> rooms = <UHotelRoomResponse>[];
  final Map<String, List<UHotelCalendarDay>> days = <String, List<UHotelCalendarDay>>{};
  DateTime from = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);
  static const int count = 14;

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
    rooms = (await UServices.hotel.readHotelRooms(p: UHotelRoomReadParams(hotelId: widget.hotelId, manage: true, pageSize: 100, pageNumber: 1))).$1?.result ?? <UHotelRoomResponse>[];
    for (final UHotelRoomResponse r in rooms) days[r.id] = (await UServices.hotel.readRoomCalendar(p: UHotelRoomCalendarParams(roomId: r.id, fromDate: from, days: count))).$1?.result ?? <UHotelCalendarDay>[];
    if (mounted) setState(() {});
    rooms.isEmpty ? state.emptying() : state.loaded();
  }

  void _move(int d) {
    from = from.add(Duration(days: d));
    read();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(
        title: Text(U.s.board).help("app.board.page", inline: true),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => _move(-count)),
          IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => _move(count)),
          const UHelpActions("app.board."),
        ],
      ),
      body: AppStateView(
        state: state,
        onRetry: read,
        emptyTitle: U.s.addYourRoomTypesFirst,
        onLoaded: (BuildContext context) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(64),
              columnWidths: const <int, TableColumnWidth>{0: FixedColumnWidth(130)},
              border: TableBorder.all(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(12)),
              children: <TableRow>[
                TableRow(
                  decoration: BoxDecoration(color: scheme.surfaceContainer),
                  children: <Widget>[
                    UTextLabelLarge(U.s.room).pAll(8),
                    for (int i = 0; i < count; i++) UTextLabelSmall(from.add(Duration(days: i)).toJalaliDate().substring(5).toPersianNumber(), textAlign: TextAlign.center).pSymmetric(vertical: 10),
                  ],
                ),
                for (final UHotelRoomResponse r in rooms)
                  TableRow(
                    children: <Widget>[
                      UColumn(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[UTextLabelLarge(r.title, maxLines: 1), UTextLabelSmall("× ${r.quantity.toString().toPersianNumber()}", color: scheme.onSurfaceVariant)]).pAll(8),
                      for (final UHotelCalendarDay d in days[r.id] ?? <UHotelCalendarDay>[])
                        UContainer(
                          height: 54,
                          alignment: Alignment.center,
                          color: d.closed ? scheme.surfaceContainer : d.available == 0 ? scheme.primary.withValues(alpha: 0.85) : d.booked > 0 ? scheme.primary.withValues(alpha: 0.25) : null,
                          child: UColumn(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              UTextLabelLarge(d.closed ? "—" : "${d.booked.toString().toPersianNumber()}/${r.quantity.toString().toPersianNumber()}", color: d.available == 0 && !d.closed ? scheme.onPrimary : null),
                              UTextLabelSmall(money(d.price).split(" ").first, color: d.available == 0 && !d.closed ? scheme.onPrimary : scheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ).help("app.board.table"),
        ),
      ),
    );
  }
}
