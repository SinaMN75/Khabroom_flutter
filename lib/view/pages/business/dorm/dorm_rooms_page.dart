import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/dorm/dorm_contract_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_new_contract_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// Every room with its beds: free beds in green, taken beds with the resident's name.
class DormRoomsPage extends StatefulWidget {
  const DormRoomsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormRoomsPage> createState() => _DormRoomsPageState();
}

class _DormRoomsPageState extends State<DormRoomsPage> {
  final URxState state = URxState();
  List<UDormRoomResponse> rooms = <UDormRoomResponse>[];

  bool get canEdit => AppWorkspace.can(TagUser.permissionManageDorms, placeId: widget.dormId);

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
    final UResponse<List<UDormRoomResponse>>? r = (await UServices.dorm.readDormRooms(
      p: UDormRoomReadParams(
        dormId: widget.dormId,
        manage: true,
        pageSize: 200,
        pageNumber: 1,
        selectorArgs: const UDormRoomSelectorArgs(beds: UDormBedSelectorArgs(contract: UDormBedContractSelectorArgs(user: UUserSelectorArgs()))),
      ),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    rooms = (r.result ?? <UDormRoomResponse>[])..sort((UDormRoomResponse a, UDormRoomResponse b) => a.title.compareTo(b.title));
    if (mounted) setState(() {});
    rooms.isEmpty ? state.emptying() : state.loaded();
  }

  static UDormBedContractResponse? activeOf(UDormBedResponse b) => b.contracts?.where((UDormBedContractResponse c) => c.isActive && !c.tags.contains(TagDormBedContract.settled.number)).firstOrNull;

  Future<void> _roomForm([UDormRoomResponse? room]) async {
    final TextEditingController title = TextEditingController(text: room?.title);
    final TextEditingController floor = TextEditingController(text: room?.jsonData.floor?.toString());
    final TextEditingController size = TextEditingController(text: room?.jsonData.sizeSquareMeters?.toInt().toString());
    final TextEditingController beds = TextEditingController(text: room == null ? "2" : "");
    final TextEditingController rent = TextEditingController();
    final TextEditingController deposit = TextEditingController();
    final bool ok = await AppForm.show(
      title: room == null ? U.s.newRoom : "${U.s.edit} · ${room.title}",
      help: "app.dormRooms.form",
      onSubmit: () async {
        if (room != null) {
          return appSend(
            UServices.dorm.updateDormRoom(p: UDormRoomUpdateParams(id: room.id, title: title.text.trim(), floor: int.tryParse(floor.numString()), sizeSquareMeters: double.tryParse(size.numString()))),
          );
        }
        final (UResponse<String>? ok, UEmptyResponse? error, String? exception) = await UServices.dorm.createDormRoom(
          p: UDormRoomCreateParams(tags: <int>[], title: title.text.trim(), dormId: widget.dormId, capacity: int.tryParse(beds.numString()) ?? 0, floor: int.tryParse(floor.numString()), sizeSquareMeters: double.tryParse(size.numString())),
        );
        if (ok?.result == null) {
          UToast.error(message: error?.message ?? exception ?? U.s.error);
          return false;
        }
        for (int i = 1; i <= (int.tryParse(beds.numString()) ?? 0); i++) {
          await UServices.dorm.createDormBed(
            p: UDormBedCreateParams(tags: <int>[TagDormBed.single.number], title: "${U.s.bed} ${i.toString().toPersianNumber()}", deposit: tomanToRial(deposit), monthlyRent: tomanToRial(rent), roomId: ok!.result!),
          );
        }
        UToast.success(message: U.s.done);
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.roomName, hintText: U.s.forExampleRoom102, validator: UValidators.required<String>()),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: floor, labelText: U.s.floor, keyboardType: TextInputType.number)),
            Expanded(child: UTextField(controller: size, labelText: U.s.sizeInSquareMeters, keyboardType: TextInputType.number)),
          ],
        ),
        if (room == null) ...<Widget>[
          UTextField(controller: beds, labelText: U.s.numberOfBeds, keyboardType: TextInputType.number).help("app.dormRooms.beds"),
          AppMoneyField(controller: rent, label: U.s.monthlyRentPerBed),
          AppMoneyField(controller: deposit, label: U.s.depositPerBed, required: false),
        ],
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, floor, size, beds, rent, deposit]) c.dispose();
    if (ok) await read();
  }

  Future<void> _bedForm(UDormRoomResponse room, [UDormBedResponse? bed]) async {
    final TextEditingController title = TextEditingController(text: bed?.title ?? "${U.s.bed} ${((room.beds?.length ?? 0) + 1).toString().toPersianNumber()}");
    final TextEditingController rent = TextEditingController(text: rialToTomanText(bed?.monthlyRent ?? room.beds?.firstOrNull?.monthlyRent));
    final TextEditingController deposit = TextEditingController(text: rialToTomanText(bed?.deposit ?? room.beds?.firstOrNull?.deposit));
    final bool ok = await AppForm.show(
      title: bed == null ? "${U.s.newBed} · ${room.title}" : "${U.s.edit} · ${bed.title}",
      onSubmit: () => appSend(
        bed == null
            ? UServices.dorm.createDormBed(p: UDormBedCreateParams(tags: <int>[TagDormBed.single.number], title: title.text.trim(), deposit: tomanToRial(deposit), monthlyRent: tomanToRial(rent), roomId: room.id))
            : UServices.dorm.updateDormBed(p: UDormBedUpdateParams(id: bed.id, title: title.text.trim(), deposit: tomanToRial(deposit), monthlyRent: tomanToRial(rent))),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.bedName, validator: UValidators.required<String>()),
        AppMoneyField(controller: rent, label: U.s.monthlyRent),
        AppMoneyField(controller: deposit, label: U.s.deposit, required: false),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, rent, deposit]) c.dispose();
    if (ok) await read();
  }

  void _openBed(UDormRoomResponse room, UDormBedResponse bed) {
    final UDormBedContractResponse? c = activeOf(bed);
    if (c != null) {
      UNavigator.push(DormContractPage(contractId: c.id)).then((_) => read());
      return;
    }
    UNavigator.bottomSheet<void>(
      SafeArea(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge("${room.title} · ${bed.title}").pAll(12),
            AppTile(icon: Icons.person_add_alt_1_outlined, title: U.s.newResidentForThisBed, onTap: () {
              UNavigator.back();
              UNavigator.push(DormNewContractPage(dormId: widget.dormId, bed: bed)).then((_) => read());
            }),
            if (canEdit) ...<Widget>[
              AppTile(icon: Icons.edit_outlined, title: U.s.editBed, onTap: () {
                UNavigator.back();
                _bedForm(room, bed);
              }),
              AppTile(icon: Icons.delete_outline_rounded, iconColor: Theme.of(context).colorScheme.error, title: U.s.deleteBed, onTap: () async {
                UNavigator.back();
                if (await UNavigator.confirmAsync(title: U.s.deleteBed, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.dorm.deleteDormBed(p: UIdParams(id: bed.id)))) await read();
              }),
            ],
          ],
        ).pSymmetric(horizontal: 12),
      ),
      showDragHandle: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.roomsAndBeds).help("app.dormRooms.page", inline: true), actions: const <Widget>[UHelpActions("app.dormRooms.")]),
      floatingActionButton: canEdit ? FloatingActionButton.extended(onPressed: _roomForm, icon: const Icon(Icons.add_rounded), label: Text(U.s.newRoom)) : null,
      body: AppStateView(
        state: state,
        onRetry: read,
        emptyTitle: U.s.addYourRoomsAndBedsFirst,
        emptyIcon: Icons.meeting_room_outlined,
        onLoaded: (BuildContext context) => AppPageBody(
          onRefresh: read,
          children: <Widget>[
            AppGrid(
              children: <Widget>[
                for (final UDormRoomResponse room in rooms)
                  AppCard(
                    child: UColumn(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        URow(
                          children: <Widget>[
                            UTextTitleMedium(room.title, expanded: 1),
                            if (room.jsonData.floor != null) AppChip(label: "${U.s.floor} ${room.jsonData.floor.toString().toPersianNumber()}"),
                            if (canEdit) PopupMenuButton<int>(
                              onSelected: (int v) async {
                                if (v == 0) await _roomForm(room);
                                if (v == 1) await _bedForm(room);
                                if (v == 2 && await UNavigator.confirmAsync(title: U.s.deleteRoom, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.dorm.deleteDormRoom(p: UIdParams(id: room.id)))) await read();
                              },
                              itemBuilder: (_) => <PopupMenuEntry<int>>[
                                PopupMenuItem<int>(value: 0, child: Text(U.s.editRoom)),
                                PopupMenuItem<int>(value: 1, child: Text(U.s.addBed)),
                                PopupMenuItem<int>(value: 2, child: Text(U.s.deleteRoom)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            for (final UDormBedResponse bed in room.beds ?? <UDormBedResponse>[])
                              Builder(
                                builder: (BuildContext context) {
                                  final UDormBedContractResponse? c = activeOf(bed);
                                  final Color color = c == null ? AppColors.success : scheme.primary;
                                  return UContainer(
                                    radius: 12,
                                    color: color.withValues(alpha: 0.1),
                                    border: Border.all(color: color.withValues(alpha: 0.4)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    onTap: () => _openBed(room, bed),
                                    child: UColumn(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        UTextLabelLarge(bed.title, color: color),
                                        UTextLabelSmall(c == null ? U.s.free : "${c.user?.firstName ?? ""} ${c.user?.lastName ?? ""}".trim(), color: scheme.onSurfaceVariant),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
