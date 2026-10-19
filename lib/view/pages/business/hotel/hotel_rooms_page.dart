import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The hotel's room types: how many of each, for how many people, and the price per night.
class HotelRoomsPage extends StatefulWidget {
  const HotelRoomsPage({required this.hotelId, super.key});

  final String hotelId;

  @override
  State<HotelRoomsPage> createState() => _HotelRoomsPageState();
}

class _HotelRoomsPageState extends State<HotelRoomsPage> {
  final URxState state = URxState();
  List<UHotelRoomResponse> list = <UHotelRoomResponse>[];

  bool get canEdit => AppWorkspace.can(TagUser.permissionManageHotels, placeId: widget.hotelId);

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
    final UResponse<List<UHotelRoomResponse>>? r = (await UServices.hotel.readHotelRooms(p: UHotelRoomReadParams(hotelId: widget.hotelId, manage: true, pageSize: 100, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UHotelRoomResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _form([UHotelRoomResponse? room]) async {
    final TextEditingController title = TextEditingController(text: room?.title);
    final TextEditingController capacity = TextEditingController(text: room?.capacity.toString() ?? "2");
    final TextEditingController quantity = TextEditingController(text: room?.quantity.toString() ?? "1");
    final TextEditingController price = TextEditingController(text: rialToTomanText(room?.pricePerNight));
    final TextEditingController numbers = TextEditingController(text: room?.roomNumber);
    final TextEditingController bed = TextEditingController(text: room?.jsonData.bedType);
    bool available = room?.isAvailable ?? true;
    final bool ok = await AppForm.show(
      title: room == null ? U.s.newRoomType : "${U.s.edit} · ${room.title}",
      help: "app.hotelRooms.form",
      onSubmit: () => appSend(
        room == null
            ? UServices.hotel.createHotelRoom(
                p: UHotelRoomCreateParams(
                  tags: <int>[TagRoom.available.number],
                  title: title.text.trim(),
                  capacity: int.tryParse(capacity.numString()) ?? 2,
                  pricePerNight: tomanToRial(price),
                  hotelId: widget.hotelId,
                  quantity: int.tryParse(quantity.numString()) ?? 1,
                  isAvailable: available,
                  roomNumber: numbers.valueOrNull(),
                  bedType: bed.valueOrNull(),
                ),
              )
            : UServices.hotel.updateHotelRoom(
                p: UHotelRoomUpdateParams(
                  id: room.id,
                  title: title.text.trim(),
                  capacity: int.tryParse(capacity.numString()),
                  pricePerNight: tomanToRial(price),
                  quantity: int.tryParse(quantity.numString()),
                  isAvailable: available,
                  roomNumber: numbers.text.trim(),
                  bedType: bed.text.trim(),
                ),
              ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.roomTypeName, hintText: U.s.forExampleDoubleRoom, validator: UValidators.required<String>()),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: capacity, labelText: U.s.peoplePerRoom, keyboardType: TextInputType.number)),
            Expanded(child: UTextField(controller: quantity, labelText: U.s.howManyRooms, keyboardType: TextInputType.number)),
          ],
        ),
        AppMoneyField(controller: price, label: U.s.pricePerNight),
        UTextField(controller: numbers, labelText: U.s.roomNumbers, hintText: U.s.forExample101To104).help("app.hotelRooms.numbers"),
        UTextField(controller: bed, labelText: U.s.bedType),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: available, onChanged: (bool v) => setState(() => available = v), title: Text(U.s.openForBooking)),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, capacity, quantity, price, numbers, bed]) c.dispose();
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.rooms).help("app.hotelRooms.page", inline: true), actions: const <Widget>[UHelpActions("app.hotelRooms.")]),
    floatingActionButton: canEdit ? FloatingActionButton.extended(onPressed: _form, icon: const Icon(Icons.add_rounded), label: Text(U.s.newRoomType)) : null,
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.addYourRoomTypesFirst,
      emptyIcon: Icons.meeting_room_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UHotelRoomResponse r in list)
                  AppTile(
                    icon: Icons.king_bed_outlined,
                    title: "${r.title} × ${r.quantity.toString().toPersianNumber()}",
                    subtitle: "${r.capacity.toString().toPersianNumber()} ${U.s.people} · ${money(r.pricePerNight)} ${U.s.perNight}",
                    trailing: r.isAvailable ? null : AppChip(label: U.s.closed),
                    onTap: canEdit ? () => _form(r) : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
