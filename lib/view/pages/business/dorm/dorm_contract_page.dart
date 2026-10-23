import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/view/pages/business/team/customers_page.dart";
import "package:u/utilities.dart";

/// One resident's contract: their bed, dates and bills, and the things that happen to a stay — renew, move, check out.
class DormContractPage extends StatefulWidget {
  const DormContractPage({required this.contractId, super.key});

  final String contractId;

  @override
  State<DormContractPage> createState() => _DormContractPageState();
}

class _DormContractPageState extends State<DormContractPage> {
  final URxState state = URxState();
  UDormBedContractResponse? c;
  List<UDormBedInvoiceResponse> invoices = <UDormBedInvoiceResponse>[];

  String? get dormId => c?.bed?.room?.dormId;

  bool can(TagUser p) => AppWorkspace.can(p, placeId: dormId);

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
    c = (await UServices.dorm.readDormBedContract(
      p: UDormBedContractReadParams(ids: <String>[widget.contractId], pageSize: 1, pageNumber: 1, selectorArgs: const UDormBedContractSelectorArgs(user: UUserSelectorArgs(), bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs()))),
    )).$1?.result?.firstOrNull;
    if (c == null) {
      state.error();
      return;
    }
    invoices = ((await UServices.dorm.readDormBedInvoice(p: UDormBedInvoiceReadParams(contractId: c!.id, pageSize: 500, pageNumber: 1))).$1?.result ?? <UDormBedInvoiceResponse>[])
      ..sort((UDormBedInvoiceResponse a, UDormBedInvoiceResponse b) => b.dueDate.compareTo(a.dueDate));
    if (mounted) setState(() {});
    state.loaded();
  }

  bool get settled => c?.tags.contains(TagDormBedContract.settled.number) ?? false;

  Future<void> _renew() async {
    DateTime? end = c!.endDate.add(const Duration(days: 180));
    final TextEditingController rent = TextEditingController(text: rialToTomanText(c!.rent));
    if (await AppForm.show(
      title: U.s.renewContract,
      help: "app.contract.renew",
      submitTitle: U.s.renew,
      onSubmit: () => appSend(UServices.dorm.renewDormBedContract(p: UDormBedContractRenewParams(id: c!.id, endDate: end!, rent: tomanToRial(rent)))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextFieldDatePicker(labelText: U.s.newEndDate, jalali: true, initialDate: end, onChange: (DateTime d, _) => end = d),
        AppMoneyField(controller: rent, label: U.s.monthlyRent),
      ],
    )) await read();
    rent.dispose();
  }

  Future<void> _transfer() async {
    final List<UDormBedResponse> free = ((await UServices.dorm.readDormBeds(
      p: UDormBedReadParams(dormId: dormId, manage: true, pageSize: 300, pageNumber: 1, selectorArgs: const UDormBedSelectorArgs(room: UDormRoomSelectorArgs(), contract: UDormBedContractSelectorArgs())),
    )).$1?.result ?? <UDormBedResponse>[])
        .where((UDormBedResponse b) => b.id != c!.bedId && !(b.contracts ?? <UDormBedContractResponse>[]).any((UDormBedContractResponse x) => x.isActive))
        .toList();
    String? bedId = free.firstOrNull?.id;
    DateTime? date = DateTime.now();
    final TextEditingController rent = TextEditingController();
    if (await AppForm.show(
      title: U.s.moveToAnotherBed,
      help: "app.contract.transfer",
      submitTitle: U.s.move,
      onSubmit: () async {
        if (bedId == null) {
          UToast.error(message: U.s.thereIsNoFreeBed);
          return false;
        }
        return appSend(UServices.dorm.transferDormBedContract(p: UDormBedContractTransferParams(id: c!.id, bedId: bedId!, date: date, rent: rent.text.isEmpty ? null : tomanToRial(rent))));
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<String?>(
          labelText: U.s.newBed,
          initialValue: bedId,
          items: <DropdownMenuItem<String?>>[for (final UDormBedResponse b in free) DropdownMenuItem<String?>(value: b.id, child: Text("${b.room?.title ?? ""} · ${b.title}"))],
          onChanged: (String? v) => setState(() => bedId = v),
        ),
        UTextFieldDatePicker(labelText: U.s.fromDate, jalali: true, initialDate: date, onChange: (DateTime d, _) => date = d),
        AppMoneyField(controller: rent, label: U.s.newRentIfItChanges, required: false),
      ],
    )) await read();
    rent.dispose();
  }

  Future<void> _settle() async {
    DateTime? end = DateTime.now();
    final TextEditingController deductions = TextEditingController();
    final TextEditingController reason = TextEditingController();
    if (await AppForm.show(
      title: U.s.checkOut,
      help: "app.contract.settle",
      submitTitle: U.s.checkOutAndSettle,
      onSubmit: () => appSend(
        UServices.dorm.settleDormBedContract(p: UDormBedContractSettleParams(id: c!.id, endDate: end, deductions: tomanToRial(deductions), deductionReason: reason.valueOrNull())),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextBodySmall(U.s.checkOutExplanation, color: Theme.of(context).colorScheme.onSurfaceVariant),
        UTextFieldDatePicker(labelText: U.s.leavingDate, jalali: true, initialDate: end, onChange: (DateTime d, _) => end = d),
        AppMoneyField(controller: deductions, label: U.s.damagesToDeduct, required: false),
        UTextField(controller: reason, labelText: U.s.reason),
      ],
    )) await read();
    deductions.dispose();
    reason.dispose();
  }

  Future<void> _newBill() async {
    final TextEditingController amount = TextEditingController();
    final TextEditingController note = TextEditingController();
    TagDormBedInvoice type = TagDormBedInvoice.service;
    DateTime? due = DateTime.now().add(const Duration(days: 3));
    if (await AppForm.show(
      title: U.s.newBill,
      help: "app.contract.bill",
      onSubmit: () => appSend(
        UServices.dorm.createDormBedInvoice(
          p: UDormBedInvoiceCreateParams(
            tags: <int>[type.number, TagDormBedInvoice.notPaid.number],
            debtAmount: tomanToRial(amount),
            creditorAmount: 0,
            paidAmount: 0,
            penaltyAmount: 0,
            contractId: c!.id,
            dueDate: due ?? DateTime.now(),
            detail1: note.valueOrNull(),
          ),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[for (final TagDormBedInvoice t in <TagDormBedInvoice>[TagDormBedInvoice.service, TagDormBedInvoice.damage, TagDormBedInvoice.rent]) ChoiceChip(label: Text(t.localizedTitle), selected: type == t, onSelected: (_) => setState(() => type = t))],
        ),
        AppMoneyField(controller: amount, label: U.s.amount),
        UTextFieldDatePicker(labelText: U.s.dueDate, jalali: true, initialDate: due, onChange: (DateTime d, _) => due = d),
        UTextField(controller: note, labelText: U.s.whatIsItFor),
      ],
    )) await read();
    amount.dispose();
    note.dispose();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.contract).help("app.contract.page", inline: true),
      actions: <Widget>[
        if (c != null && CustomersPage.allowed)
          IconButton(
            icon: const Icon(Icons.how_to_reg_outlined),
            tooltip: U.s.vipAndBlacklist,
            onPressed: () => CustomersPage.markUser(c!.userId, "${c!.user?.firstName ?? ""} ${c!.user?.lastName ?? ""}".trim()),
          ).help("app.contract.customer"),
        const UHelpActions("app.contract."),
      ],
    ),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UDormBedContractResponse x = c!;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final String name = "${x.user?.firstName ?? ""} ${x.user?.lastName ?? ""}".trim();
        final double due = invoices.where((UDormBedInvoiceResponse i) => !i.isPaid).fold<double>(0, (double s, UDormBedInvoiceResponse i) => s + i.netDue);
        return AppPageBody(
          onRefresh: read,
          maxWidth: 860,
          children: <Widget>[
            AppCard(
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTile(
                    icon: Icons.person_outline_rounded,
                    title: name.isEmpty ? U.s.resident : name,
                    subtitle: x.user?.phoneNumber?.toPersianNumber(),
                    trailing: x.user?.phoneNumber == null ? null : IconButton(icon: const Icon(Icons.call_outlined), onPressed: () => ULaunch.call(x.user!.phoneNumber!)),
                  ),
                  const Divider(),
                  AppInfoRow(label: U.s.bed, value: "${x.bed?.room?.title ?? ""} · ${x.bed?.title ?? ""}"),
                  AppInfoRow(label: U.s.from, value: x.startDate.toJalaliDate().toPersianNumber()),
                  AppInfoRow(label: U.s.until, value: x.endDate.toJalaliDate().toPersianNumber()),
                  AppInfoRow(label: U.s.monthlyRent, value: money(x.rent)),
                  AppInfoRow(label: U.s.deposit, value: money(x.deposit)),
                  if (x.jsonData.guardianName != null) AppInfoRow(label: U.s.guardian, value: "${x.jsonData.guardianName} ${x.jsonData.guardianPhone ?? ""}".toPersianNumber()),
                  if (settled) AppChip(label: "${U.s.checkedOut} · ${U.s.depositReturned} ${money(x.jsonData.depositRefund)}").pOnly(top: 8),
                ],
              ),
            ).help("app.contract.summary"),
            const SizedBox(height: 12),
            if (!settled && can(TagUser.permissionManageContracts))
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  UButton(title: U.s.renew, icon: const Icon(Icons.autorenew_rounded), type: UButtonType.outlined, onTap: _renew),
                  UButton(title: U.s.moveToAnotherBed, icon: const Icon(Icons.swap_horiz_rounded), type: UButtonType.outlined, onTap: _transfer),
                  UButton(title: U.s.checkOut, icon: const Icon(Icons.logout_rounded), type: UButtonType.outlined, foregroundColor: scheme.error, onTap: _settle),
                ],
              ).help("app.contract.actions"),
            AppLabel(
              "${U.s.bills} · ${U.s.remaining} ${money(due)}",
              action: can(TagUser.permissionManageInvoices) && !settled ? U.s.newBill : null,
              onAction: _newBill,
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UColumn(
                children: <Widget>[
                  if (invoices.isEmpty) AppEmpty(title: U.s.noBillsYet, icon: Icons.receipt_long_outlined),
                  for (final UDormBedInvoiceResponse i in invoices)
                    AppTile(
                      icon: Icons.receipt_outlined,
                      title: "${TagDormBedInvoice.values.where((TagDormBedInvoice t) => t.number < 200 && i.tags.contains(t.number)).firstOrNull?.localizedTitle ?? U.s.invoice} · ${money(i.debtAmount + i.penaltyAmount)}",
                      subtitle: "${U.s.dueDate}: ${i.dueDate.toJalaliDate().toPersianNumber()}${i.paidAmount > 0 ? " · ${U.s.paid} ${money(i.paidAmount)}" : ""}",
                      trailing: AppStatusChip(status: AppStatus.dormInvoice(i.tags, i.dueDate)),
                    ),
                ],
              ),
            ).help("app.contract.bills"),
          ],
        );
      },
    ),
  );
}
