import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Every room by number: clean, needs cleaning, checked, or out of order. Tap a room to change it.
class HotelHousekeepingPage extends StatefulWidget {
  const HotelHousekeepingPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelHousekeepingPage> createState() => _HotelHousekeepingPageState();
}

class _HotelHousekeepingPageState extends State<HotelHousekeepingPage> {
  final URxState state = URxState();
  List<UHotelRoomResponse> rooms = <UHotelRoomResponse>[];

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
    if (mounted) setState(() {});
    rooms.any((UHotelRoomResponse r) => r.jsonData.units.isNotEmpty) ? state.loaded() : state.emptying();
  }

  static Color colorOf(int status) => switch (status) {
    101 => AppColors.success,
    102 => AppColors.danger,
    103 => const Color(0xFF2F5A86),
    _ => AppColors.muted,
  };

  Future<void> _set(UHotelRoomResponse r, UHotelRoomUnit u) async {
    final TagHousekeeping? s = await UNavigator.bottomSheet<TagHousekeeping>(
      SafeArea(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge("${r.title} · ${u.number.toPersianNumber()}").pAll(12),
            for (final TagHousekeeping t in TagHousekeeping.values) AppTile(icon: Icons.circle, iconColor: colorOf(t.number), title: t.localizedTitle, onTap: () => UNavigator.back(t)),
          ],
        ).pSymmetric(horizontal: 12),
      ),
      showDragHandle: true,
    );
    if (s == null) return;
    if (await appSend(UServices.hotel.setHousekeeping(p: UHotelHousekeepingParams(roomId: r.id, number: u.number, status: s.number)), toast: false)) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.housekeeping).help("app.housekeeping.page", inline: true), actions: const <Widget>[UHelpActions("app.housekeeping.")]),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.addRoomNumbersToYourRoomTypesFirst,
      emptyIcon: Icons.cleaning_services_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: <Widget>[for (final TagHousekeeping t in TagHousekeeping.values) AppChip(label: t.localizedTitle, icon: Icons.circle, filled: false)],
          ).pOnly(bottom: 12),
          for (final UHotelRoomResponse r in rooms.where((UHotelRoomResponse r) => r.jsonData.units.isNotEmpty)) ...<Widget>[
            AppLabel(r.title),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final UHotelRoomUnit u in r.jsonData.units)
                  UContainer(
                    width: 72,
                    height: 60,
                    radius: 14,
                    alignment: Alignment.center,
                    color: colorOf(u.status).withValues(alpha: 0.14),
                    border: Border.all(color: colorOf(u.status)),
                    onTap: () => _set(r, u),
                    child: UColumn(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        UTextTitleSmall(u.number.toPersianNumber(), color: colorOf(u.status)),
                        UTextLabelSmall(TagHousekeeping.values.where((TagHousekeeping t) => t.number == u.status).firstOrNull?.localizedTitle ?? "", maxLines: 1),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}
