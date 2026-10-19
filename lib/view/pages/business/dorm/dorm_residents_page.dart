import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/dorm/dorm_contract_page.dart";
import "package:khabroom/view/pages/business/dorm/dorm_new_contract_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

enum _ResidentTab { current, upcoming, ending, past }

/// The people living in the dorm, the ones about to arrive or leave, and those who left.
class DormResidentsPage extends StatefulWidget {
  const DormResidentsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormResidentsPage> createState() => _DormResidentsPageState();
}

class _DormResidentsPageState extends State<DormResidentsPage> {
  final URxState state = URxState();
  final TextEditingController search = TextEditingController();
  List<UDormBedContractResponse> list = <UDormBedContractResponse>[];
  _ResidentTab tab = _ResidentTab.current;

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

  String _title(_ResidentTab t) => switch (t) {
    _ResidentTab.current => U.s.livingHere,
    _ResidentTab.upcoming => U.s.arriving,
    _ResidentTab.ending => U.s.leavingSoon,
    _ResidentTab.past => U.s.past,
  };

  Future<void> read() async {
    state.loading();
    final UResponse<List<UDormBedContractResponse>>? r = (await UServices.dorm.readDormBedContract(
      p: UDormBedContractReadParams(
        dormId: widget.dormId,
        pageSize: 300,
        pageNumber: 1,
        userName: search.text.trim().isEmpty ? null : search.text.trim(),
        activeOnly: tab == _ResidentTab.current ? true : null,
        upcomingOnly: tab == _ResidentTab.upcoming ? true : null,
        expiredOnly: tab == _ResidentTab.past ? true : null,
        expiringWithinDays: tab == _ResidentTab.ending ? 30 : null,
        selectorArgs: const UDormBedContractSelectorArgs(user: UUserSelectorArgs(), bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs())),
      ),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UDormBedContractResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.residents).help("app.residents.page", inline: true), actions: const <Widget>[UHelpActions("app.residents.")]),
    floatingActionButton: AppWorkspace.can(TagUser.permissionManageContracts, placeId: widget.dormId)
        ? FloatingActionButton(onPressed: () => UNavigator.push(DormNewContractPage(dormId: widget.dormId)).then((_) => read()), child: const Icon(Icons.person_add_alt_1_outlined))
        : null,
    body: UColumn(
      children: <Widget>[
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            UTextField(controller: search, hintText: U.s.searchByName, prefix: const Icon(Icons.search_rounded), onFieldSubmitted: (_) => read()),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final _ResidentTab t in _ResidentTab.values)
                    ChoiceChip(label: Text(_title(t)), selected: tab == t, onSelected: (_) {
                      setState(() => tab = t);
                      read();
                    }).pOnly(left: 8),
                ],
              ),
            ).help("app.residents.tabs"),
          ],
        ).pSymmetric(horizontal: 16, vertical: 10),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.noOneHere,
            emptyIcon: Icons.people_outline_rounded,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UDormBedContractResponse c in list)
                        AppTile(
                          icon: Icons.person_outline_rounded,
                          title: "${c.user?.firstName ?? ""} ${c.user?.lastName ?? ""}".trim().isEmpty ? (c.user?.phoneNumber ?? U.s.resident) : "${c.user?.firstName ?? ""} ${c.user?.lastName ?? ""}".trim(),
                          subtitle: "${c.bed?.room?.title ?? ""} · ${c.bed?.title ?? ""} · ${U.s.until} ${c.endDate.toJalaliDate().toPersianNumber()}",
                          onTap: () => UNavigator.push(DormContractPage(contractId: c.id)).then((_) => read()),
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
