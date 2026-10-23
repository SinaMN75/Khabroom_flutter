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

  bool get canDelete => AppWorkspace.can(TagUser.permissionDeleteHotels, placeId: widget.hotelId);

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
    final UResponse<List<UHotelRoomResponse>>? r = (await UServices.hotel.readHotelRooms(p: UHotelRoomReadParams(hotelId: widget.hotelId, manage: true, pageSize: 100, pageNumber: 1, selectorArgs: const UHotelRoomSelectorArgs(media: UMediaSelectorArgs())))).$1;
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
    final TextEditingController description = TextEditingController(text: room?.jsonData.description);
    final TextEditingController size = TextEditingController(text: room?.jsonData.sizeSquareMeters?.toInt().toString());
    final TextEditingController floor = TextEditingController(text: room?.jsonData.floor?.toString());
    final TextEditingController extraGuests = TextEditingController(text: room?.jsonData.extraGuestCapacity?.toString());
    final TextEditingController extraPrice = TextEditingController(text: rialToTomanText(room?.jsonData.extraGuestPrice));
    final List<int> tags = List<int>.from(room?.tags ?? <int>[TagRoom.double_.number, TagRoom.available.number]);
    final List<UMediaResponse> media = (room?.media ?? <UMediaResponse>[]).sortedForGallery();
    final UFilePickerController photos = UFilePickerController.fromMedia(media);
    bool available = room?.isAvailable ?? true;
    final bool ok = await AppForm.show(
      title: room == null ? U.s.newRoomType : "${U.s.edit} · ${room.title}",
      help: "app.hotelRooms.form",
      onSubmit: () async {
        final UHotelRoomUpdateParams p = UHotelRoomUpdateParams(
          id: room?.id ?? "",
          tags: tags,
          title: title.text.trim(),
          capacity: int.tryParse(capacity.numString()) ?? 2,
          pricePerNight: tomanToRial(price),
          hotelId: widget.hotelId,
          quantity: int.tryParse(quantity.numString()) ?? 1,
          isAvailable: available,
          roomNumber: numbers.text.trim(),
          bedType: bed.text.trim(),
          description: description.text.trim(),
          sizeSquareMeters: double.tryParse(size.numString()),
          floor: int.tryParse(floor.numString()),
          extraGuestCapacity: int.tryParse(extraGuests.numString()),
          extraGuestPrice: extraPrice.text.isEmpty ? null : tomanToRial(extraPrice),
        );
        String? id = room?.id;
        if (room == null) {
          final (UResponse<String>? ok, UEmptyResponse? error, String? exception) = await UServices.hotel.createHotelRoom(p: UHotelRoomCreateParams.fromMap(p.toMap()..remove("id")));
          id = ok?.result;
          if (id == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
        } else if (!await appSend(UServices.hotel.updateHotelRoom(p: p), toast: false)) {
          id = null;
        }
        if (id == null) return false;
        await UServices.media.syncGallery(photos, existing: media, hotelRoomId: id);
        UToast.success(message: U.s.done);
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.roomTypeName, hintText: U.s.forExampleDoubleRoom, validator: UValidators.required<String>()),
        UTagChips<TagRoom>(title: U.s.type, options: TagRoom.values.group(100), tags: tags, single: true),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: capacity, labelText: U.s.peoplePerRoom, keyboardType: TextInputType.number)),
            Expanded(child: UTextField(controller: quantity, labelText: U.s.howManyRooms, keyboardType: TextInputType.number)),
          ],
        ),
        AppMoneyField(controller: price, label: U.s.pricePerNight),
        UTextField(controller: numbers, labelText: U.s.roomNumbers, hintText: U.s.forExample101To104).help("app.hotelRooms.numbers"),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: bed, labelText: U.s.bedType)),
            Expanded(child: UTextField(controller: size, labelText: U.s.sizeInSquareMeters, keyboardType: TextInputType.number)),
            Expanded(child: UTextField(controller: floor, labelText: U.s.floor, keyboardType: TextInputType.number)),
          ],
        ),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: extraGuests, labelText: U.s.extraGuestCapacity, keyboardType: TextInputType.number)),
            Expanded(child: AppMoneyField(controller: extraPrice, label: U.s.extraGuestPrice, required: false)),
          ],
        ).help("app.hotelRooms.extra"),
        UTextField(controller: description, labelText: U.s.description, lines: 3),
        UTagChips<TagRoom>(title: U.s.roomView, options: TagRoom.values.group(400), tags: tags),
        UTagChips<TagRoom>(title: U.s.amenities, options: TagRoom.values.group(500), tags: tags),
        UTagChips<TagRoom>(title: U.s.policies, options: TagRoom.values.group(300), tags: tags),
        UTextBodySmall(U.s.photos),
        UFilePicker.gallery(photos),
        SwitchListTile(contentPadding: EdgeInsets.zero, value: available, onChanged: (bool v) => setState(() => available = v), title: Text(U.s.openForBooking)),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, capacity, quantity, price, numbers, bed, description, size, floor, extraGuests, extraPrice]) c.dispose();
    photos.dispose();
    if (ok) await read();
  }

  Future<void> _delete(UHotelRoomResponse room) async {
    if (await UNavigator.confirmAsync(title: "${U.s.delete} ${room.title}", message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.hotel.deleteHotelRoom(p: UIdParams(id: room.id)))) await read();
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
                    trailing: URow(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (!r.isAvailable) AppChip(label: U.s.closed),
                        if (canDelete) IconButton(icon: const Icon(Icons.delete_outline_rounded), tooltip: U.s.delete, onPressed: () => _delete(r)),
                      ],
                    ),
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
