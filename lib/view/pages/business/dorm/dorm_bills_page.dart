import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/business/dorm/dorm_contract_page.dart";
import "package:khabroom/view/pages/business/shared/receive_sheet.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

enum _BillTab { overdue, unpaid, paid }

/// Every bill of the dorm. Residents pay in the app; money paid in person is recorded here.
class DormBillsPage extends StatefulWidget {
  const DormBillsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormBillsPage> createState() => _DormBillsPageState();
}

class _DormBillsPageState extends State<DormBillsPage> {
  final URxState state = URxState();
  List<UDormBedInvoiceResponse> list = <UDormBedInvoiceResponse>[];
  _BillTab tab = _BillTab.overdue;

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

  String _title(_BillTab t) => switch (t) {
    _BillTab.overdue => U.s.overdue,
    _BillTab.unpaid => U.s.unpaid,
    _BillTab.paid => U.s.paid,
  };

  Future<void> read() async {
    state.loading();
    final UResponse<List<UDormBedInvoiceResponse>>? r = (await UServices.dorm.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        dormId: widget.dormId,
        isPaid: tab == _BillTab.paid,
        isOverdue: tab == _BillTab.overdue ? true : null,
        pageSize: 300,
        pageNumber: 1,
        selectorArgs: const UDormBedInvoiceSelectorArgs(contract: UDormBedContractSelectorArgs(user: UUserSelectorArgs(), bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs()))),
      ),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = (r.result ?? <UDormBedInvoiceResponse>[])..sort((UDormBedInvoiceResponse a, UDormBedInvoiceResponse b) => tab == _BillTab.paid ? b.dueDate.compareTo(a.dueDate) : a.dueDate.compareTo(b.dueDate));
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  double get total => list.fold<double>(0, (double s, UDormBedInvoiceResponse i) => s + (tab == _BillTab.paid ? i.paidAmount : i.netDue));

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.bills).help("app.bills.page", inline: true), actions: const <Widget>[UHelpActions("app.bills.")]),
    body: UColumn(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              for (final _BillTab t in _BillTab.values)
                ChoiceChip(label: Text(_title(t)), selected: tab == t, onSelected: (_) {
                  setState(() => tab = t);
                  read();
                }).pOnly(left: 8),
            ],
          ),
        ),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.noBillsHere,
            emptyIcon: Icons.receipt_long_outlined,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppStat(label: tab == _BillTab.paid ? U.s.collected : U.s.toCollect, value: money(total), icon: Icons.payments_outlined),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UDormBedInvoiceResponse i in list)
                        AppTile(
                          icon: Icons.receipt_outlined,
                          title: "${i.contract?.user?.firstName ?? ""} ${i.contract?.user?.lastName ?? ""}".trim().isEmpty ? U.s.resident : "${i.contract?.user?.firstName ?? ""} ${i.contract?.user?.lastName ?? ""}",
                          subtitle: "${i.contract?.bed?.room?.title ?? ""} · ${money(tab == _BillTab.paid ? i.paidAmount : i.netDue)} · ${i.dueDate.toJalaliDate().toPersianNumber()}",
                          onTap: i.contract == null ? null : () => UNavigator.push(DormContractPage(contractId: i.contract!.id)).then((_) => read()),
                          trailing: i.isPaid || !AppWorkspace.can(TagUser.permissionPayInvoices, placeId: widget.dormId)
                              ? AppStatusChip(status: AppStatus.dormInvoice(i.tags, i.dueDate))
                              : UButton(
                                  title: U.s.receive,
                                  size: UButtonSize.small,
                                  onTap: () async {
                                    if (await ReceiveSheet.show(title: U.s.receivePayment, due: i.netDue, id: i.id, receive: (UInvoiceReceiveParams p) => UServices.dorm.receiveDormBedInvoice(p: p))) await read();
                                  },
                                ),
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
