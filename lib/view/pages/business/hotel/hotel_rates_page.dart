import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Price rules on top of the normal room price: seasons, holidays, weekends, minimum nights and closed days.
class HotelRatesPage extends StatefulWidget {
  const HotelRatesPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelRatesPage> createState() => _HotelRatesPageState();
}

class _HotelRatesPageState extends State<HotelRatesPage> {
  final URxState state = URxState();
  List<UHotelRateResponse> list = <UHotelRateResponse>[];
  List<UHotelRoomResponse> rooms = <UHotelRoomResponse>[];

  static const List<String> _weekdays = <String>["ش", "ی", "د", "س", "چ", "پ", "ج"];

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
    final UResponse<List<UHotelRateResponse>>? r = (await UServices.hotel.readRates(p: UHotelRateReadParams(hotelId: widget.hotelId, fromDate: DateTime.now(), pageSize: 200, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UHotelRateResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  String _describe(UHotelRateResponse r) {
    if (r.tags.contains(TagHotelRate.closed.number)) return U.s.closedForBooking;
    final List<String> parts = <String>[
      if (r.price != null) money(r.price),
      if (r.percent != null) "${r.percent! > 0 ? "+" : ""}${r.percent!.round()}٪",
      if (r.weekdays.isNotEmpty) r.weekdays.map((int d) => d >= 0 && d < 7 ? _weekdays[(d + 1) % 7] : "").join("، "),
      if (r.minNights != null) "${U.s.atLeast} ${r.minNights} ${U.s.nights}",
    ];
    return parts.join(" · ").toPersianNumber();
  }

  Future<void> _form() async {
    TagHotelRate kind = TagHotelRate.seasonal;
    String? roomId;
    DateTime? start = DateTime.now();
    DateTime? end = DateTime.now().add(const Duration(days: 30));
    final TextEditingController percent = TextEditingController();
    final TextEditingController minNights = TextEditingController();
    final TextEditingController note = TextEditingController();
    final Set<int> weekdays = <int>{};
    final bool ok = await AppForm.show(
      title: U.s.newPriceRule,
      help: "app.rates.form",
      onSubmit: () => appSend(
        UServices.hotel.createRate(
          p: UHotelRateCreateParams(
            hotelId: widget.hotelId,
            startDate: start ?? DateTime.now(),
            endDate: end ?? DateTime.now(),
            tags: <int>[kind.number],
            roomId: roomId,
            percent: kind == TagHotelRate.closed ? null : double.tryParse(percent.numString().isEmpty ? "" : (percent.text.contains("-") ? "-" : "") + percent.numString()),
            weekdays: weekdays.isEmpty ? null : weekdays.toList(),
            minNights: int.tryParse(minNights.numString()),
            detail1: note.valueOrNull(),
          ),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final TagHotelRate t in <TagHotelRate>[TagHotelRate.seasonal, TagHotelRate.holiday, TagHotelRate.closed]) ChoiceChip(label: Text(t.localizedTitle), selected: kind == t, onSelected: (_) => setState(() => kind = t))]),
        UTextField(controller: note, labelText: U.s.name, hintText: U.s.forExampleNowruz),
        UDropDownField<String?>(
          labelText: U.s.room,
          initialValue: roomId,
          items: <DropdownMenuItem<String?>>[DropdownMenuItem<String?>(child: Text(U.s.allRooms)), for (final UHotelRoomResponse r in rooms) DropdownMenuItem<String?>(value: r.id, child: Text(r.title))],
          onChanged: (String? v) => setState(() => roomId = v),
        ),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextFieldDatePicker(labelText: U.s.from, jalali: true, initialDate: start, onChange: (DateTime d, _) => start = d)),
            Expanded(child: UTextFieldDatePicker(labelText: U.s.until, jalali: true, initialDate: end, onChange: (DateTime d, _) => end = d)),
          ],
        ),
        if (kind != TagHotelRate.closed) ...<Widget>[
          UTextField(controller: percent, labelText: U.s.priceChangePercent, hintText: U.s.forExample20OrMinus10).help("app.rates.percent"),
          UTextBodySmall(U.s.onlyOnTheseDays),
          Wrap(
            spacing: 6,
            children: <Widget>[
              for (int d = 0; d < 7; d++) FilterChip(label: Text(_weekdays[(d + 1) % 7]), selected: weekdays.contains(d), onSelected: (bool on) => setState(() => on ? weekdays.add(d) : weekdays.remove(d))),
            ],
          ),
          UTextField(controller: minNights, labelText: U.s.minimumNights, keyboardType: TextInputType.number),
        ],
      ],
    );
    for (final TextEditingController c in <TextEditingController>[percent, minNights, note]) c.dispose();
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.pricesAndClosedDays).help("app.rates.page", inline: true), actions: const <Widget>[UHelpActions("app.rates.")]),
    floatingActionButton: FloatingActionButton(onPressed: _form, child: const Icon(Icons.add_rounded)),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.noPriceRulesEveryNightUsesTheRoomPrice,
      emptyIcon: Icons.sell_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UHotelRateResponse r in list)
                  AppTile(
                    icon: r.tags.contains(TagHotelRate.closed.number) ? Icons.block : Icons.sell_outlined,
                    title: "${r.detail1 ?? TagHotelRate.values.where((TagHotelRate t) => r.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""} · ${r.roomTitle ?? U.s.allRooms}",
                    subtitle: "${r.startDate.toJalaliDate().toPersianNumber()} → ${r.endDate.toJalaliDate().toPersianNumber()} · ${_describe(r)}",
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () async {
                        if (await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.hotel.deleteRate(p: UIdParams(id: r.id)))) await read();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
