import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// End of the day: check the numbers, see who did not show up, and close the day so its revenue is posted to the books.
class HotelAuditPage extends StatefulWidget {
  const HotelAuditPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelAuditPage> createState() => _HotelAuditPageState();
}

class _HotelAuditPageState extends State<HotelAuditPage> {
  final URxState state = URxState();
  UHotelNightAuditResponse? audit;
  DateTime date = DateTime.now();
  bool busy = false;

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
    audit = (await UServices.hotel.readNightAudit(p: UHotelNightAuditParams(hotelId: widget.hotelId, date: date))).$1?.result;
    if (audit == null) {
      state.error();
      return;
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _close() async {
    if (!await UNavigator.confirmAsync(title: U.s.closeTheDay, message: U.s.closeTheDayExplanation)) return;
    setState(() => busy = true);
    final (UResponse<UHotelNightAuditResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.closeNightAudit(p: UHotelNightAuditParams(hotelId: widget.hotelId, date: date));
    if (ok == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
    if (ok != null) UToast.success(message: U.s.theDayWasClosed);
    if (mounted) setState(() => busy = false);
    await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.closeTheDay).help("app.audit.page", inline: true), actions: const <Widget>[UHelpActions("app.audit.")]),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UHotelNightAuditResponse a = audit!;
        return AppPageBody(
          onRefresh: read,
          maxWidth: 860,
          children: <Widget>[
            UTextFieldDatePicker(labelText: U.s.date, jalali: true, initialDate: date, onChange: (DateTime d, _) {
              date = d;
              read();
            }),
            const SizedBox(height: 12),
            AppGrid(
              columns: 3,
              spacing: 10,
              children: <Widget>[
                AppStat(label: U.s.occupiedRooms, value: "${a.occupiedRooms.toString().toPersianNumber()}/${a.totalRooms.toString().toPersianNumber()}", icon: Icons.king_bed_outlined),
                AppStat(label: U.s.roomRevenue, value: money(a.roomRevenue), icon: Icons.payments_outlined, tone: AppTone.positive),
                AppStat(label: U.s.openBalance, value: money(a.openBalance), icon: Icons.receipt_long_outlined, tone: a.openBalance > 0 ? AppTone.warning : AppTone.neutral),
              ],
            ).help("app.audit.stats"),
            if (a.lastAuditDate != null) UTextBodySmall("${U.s.lastClosedDay}: ${a.lastAuditDate!.toJalaliDate().toPersianNumber()}", color: Theme.of(context).colorScheme.onSurfaceVariant).pOnly(top: 10),
            if (a.noShows.isNotEmpty) ...<Widget>[
              AppLabel("${U.s.didNotShowUp} · ${a.noShows.length.toString().toPersianNumber()}"),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: UColumn(children: <Widget>[for (final UHotelAuditItem i in a.noShows) AppTile(icon: Icons.person_off_outlined, title: i.guestName ?? U.s.guest, subtitle: i.roomTitle)]),
              ),
            ],
            if (a.dirtyUnits.isNotEmpty) ...<Widget>[
              AppLabel("${U.s.toClean} · ${a.dirtyUnits.length.toString().toPersianNumber()}"),
              Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final UHotelRoomUnitItem u in a.dirtyUnits) AppChip(label: "${u.roomTitle ?? ""} ${u.number}".toPersianNumber(), tone: AppTone.danger)]),
            ],
            const SizedBox(height: 20),
            UButton(title: U.s.closeTheDay, icon: const Icon(Icons.nightlight_outlined), isLoading: busy, onTap: busy ? null : _close).help("app.audit.close"),
          ],
        );
      },
    ),
  );
}
