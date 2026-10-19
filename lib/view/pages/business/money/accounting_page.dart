import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

enum AccountingTab { report, vouchers, checks, boxes }

/// The books, made simple: most entries are made automatically from bills, payments and payouts; here you see the result and add expenses and cheques.
class AccountingPage extends StatefulWidget {
  const AccountingPage({required this.tab, super.key});

  final AccountingTab tab;

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  final URxState state = URxState();
  late AccountingTab tab = widget.tab;
  DateTime from = DateTime.now().subtract(const Duration(days: 30));
  DateTime to = DateTime.now();
  ULedgerReportResponse? report;
  List<UVoucherResponse> vouchers = <UVoucherResponse>[];
  List<UCheckResponse> checks = <UCheckResponse>[];
  List<UAccountResponse> accounts = <UAccountResponse>[];

  String get orgId => AppWorkspace.org.id;

  bool get canWrite => AppWorkspace.can(TagUser.permissionManageAccounting);

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

  String _title(AccountingTab t) => switch (t) {
    AccountingTab.report => U.s.profitAndLoss,
    AccountingTab.vouchers => U.s.entries,
    AccountingTab.checks => U.s.cheques,
    AccountingTab.boxes => U.s.cashAndBank,
  };

  Future<void> read() async {
    state.loading();
    accounts = (await UServices.accounting.readAccounts(p: UAccountReadParams(organizationId: orgId))).$1?.result ?? accounts;
    switch (tab) {
      case AccountingTab.report:
      case AccountingTab.boxes:
        report = (await UServices.accounting.readLedgerReport(p: ULedgerReportParams(organizationId: orgId, fromDate: from, toDate: to))).$1?.result;
      case AccountingTab.vouchers:
        vouchers = (await UServices.accounting.readVouchers(p: UVoucherReadParams(organizationId: orgId, fromDate: from, toDate: to, pageSize: 200, pageNumber: 1))).$1?.result ?? <UVoucherResponse>[];
      case AccountingTab.checks:
        checks = (await UServices.accounting.readChecks(p: UCheckReadParams(organizationId: orgId, pageSize: 200, pageNumber: 1))).$1?.result ?? <UCheckResponse>[];
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  List<UAccountResponse> get _boxes => accounts.where((UAccountResponse a) => a.isMoneyBox).toList();

  List<UAccountResponse> get _expenseAccounts => accounts.where((UAccountResponse a) => a.tags.contains(TagAccount.expense.number) && !a.tags.contains(TagAccount.commissionExpense.number)).toList();

  Future<void> _expense() async {
    final TextEditingController amount = TextEditingController();
    final TextEditingController note = TextEditingController();
    String? expenseId = _expenseAccounts.firstOrNull?.id;
    String? boxId = _boxes.firstOrNull?.id;
    DateTime? date = DateTime.now();
    final bool ok = await AppForm.show(
      title: U.s.recordAnExpense,
      help: "app.accounting.expense",
      onSubmit: () async {
        if (expenseId == null || boxId == null) return false;
        final double value = tomanToRial(amount);
        return appSend(
          UServices.accounting.createVoucher(
            p: UVoucherCreateParams(
              organizationId: orgId,
              tags: <int>[TagVoucher.manual.number, TagVoucher.expense.number],
              date: date,
              detail1: note.valueOrNull(),
              lines: <UVoucherLineParams>[UVoucherLineParams(accountId: expenseId!, debit: value), UVoucherLineParams(accountId: boxId!, credit: value)],
            ),
          ),
        );
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<String?>(
          labelText: U.s.whatWasItFor,
          initialValue: expenseId,
          items: <DropdownMenuItem<String?>>[for (final UAccountResponse a in _expenseAccounts) DropdownMenuItem<String?>(value: a.id, child: Text(a.title))],
          onChanged: (String? v) => setState(() => expenseId = v),
        ),
        AppMoneyField(controller: amount, label: U.s.amount),
        UDropDownField<String?>(
          labelText: U.s.paidFrom,
          initialValue: boxId,
          items: <DropdownMenuItem<String?>>[for (final UAccountResponse a in _boxes) DropdownMenuItem<String?>(value: a.id, child: Text(a.title))],
          onChanged: (String? v) => setState(() => boxId = v),
        ),
        UTextFieldDatePicker(labelText: U.s.date, jalali: true, initialDate: date, onChange: (DateTime d, _) => date = d),
        UTextField(controller: note, labelText: U.s.description),
      ],
    );
    amount.dispose();
    note.dispose();
    if (ok) await read();
  }

  Future<void> _check() async {
    TagCheck kind = TagCheck.received;
    final TextEditingController amount = TextEditingController();
    final TextEditingController number = TextEditingController();
    final TextEditingController bank = TextEditingController();
    final TextEditingController drawer = TextEditingController();
    DateTime? due = DateTime.now().add(const Duration(days: 30));
    final bool ok = await AppForm.show(
      title: U.s.newCheque,
      help: "app.accounting.check",
      onSubmit: () => appSend(
        UServices.accounting.createCheck(
          p: UCheckCreateParams(organizationId: orgId, tags: <int>[kind.number, TagCheck.pending.number], amount: tomanToRial(amount), dueDate: due ?? DateTime.now(), number: number.text.trim(), bank: bank.valueOrNull(), drawer: drawer.valueOrNull()),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(spacing: 8, children: <Widget>[for (final TagCheck t in <TagCheck>[TagCheck.received, TagCheck.issued, TagCheck.guarantee]) ChoiceChip(label: Text(t.localizedTitle), selected: kind == t, onSelected: (_) => setState(() => kind = t))]),
        AppMoneyField(controller: amount, label: U.s.amount),
        UTextField(controller: number, labelText: U.s.chequeNumber, validator: UValidators.required<String>()),
        UTextFieldDatePicker(labelText: U.s.dueDate, jalali: true, initialDate: due, onChange: (DateTime d, _) => due = d),
        UTextField(controller: bank, labelText: U.s.bank),
        UTextField(controller: drawer, labelText: U.s.fromOrTo),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[amount, number, bank, drawer]) c.dispose();
    if (ok) await read();
  }

  Future<void> _checkStatus(UCheckResponse c) async {
    final TagCheck? s = await UNavigator.bottomSheet<TagCheck>(
      SafeArea(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[for (final TagCheck t in <TagCheck>[TagCheck.cleared, TagCheck.bounced, TagCheck.returned]) AppTile(title: t.localizedTitle, onTap: () => UNavigator.back(t))],
        ).pSymmetric(horizontal: 16),
      ),
      showDragHandle: true,
    );
    if (s != null && await appSend(UServices.accounting.setCheckStatus(p: UCheckStatusParams(id: c.id, status: s.number, accountId: _boxes.firstOrNull?.id)))) await read();
  }

  Widget _report(BuildContext context) {
    final ULedgerReportResponse? r = report;
    if (r == null) return AppEmpty(title: U.s.noData);
    final double income = r.income.fold<double>(0, (double s, ULedgerReportItem i) => s + i.amount);
    final double expense = r.expense.fold<double>(0, (double s, ULedgerReportItem i) => s + i.amount);
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppGrid(
          columns: 3,
          spacing: 10,
          children: <Widget>[
            AppStat(label: U.s.income, value: money(income), tone: AppTone.positive, icon: Icons.south_west_rounded),
            AppStat(label: U.s.expenses, value: money(expense), tone: AppTone.danger, icon: Icons.north_east_rounded),
            AppStat(label: U.s.netProfit, value: money(r.netProfit), icon: Icons.insights_outlined),
          ],
        ),
        AppLabel(U.s.income),
        AppCard(child: UColumn(children: <Widget>[for (final ULedgerReportItem i in r.income) AppInfoRow(label: i.title, value: money(i.amount))])),
        AppLabel(U.s.expenses),
        AppCard(child: UColumn(children: <Widget>[for (final ULedgerReportItem i in r.expense) AppInfoRow(label: i.title, value: money(i.amount))])),
        if (r.vatDue != 0) ...<Widget>[
          AppLabel(U.s.vat),
          AppCard(
            child: UColumn(
              children: <Widget>[
                AppInfoRow(label: U.s.vatOnSales, value: money(r.vatSales)),
                AppInfoRow(label: U.s.vatOnPurchases, value: money(r.vatPurchases)),
                AppInfoRow(label: U.s.vatToPay, value: money(r.vatDue), emphasize: true),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _boxesView(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: UColumn(
      children: <Widget>[
        for (final ULedgerMoneyBoxItem b in report?.moneyBoxes ?? <ULedgerMoneyBoxItem>[])
          AppTile(icon: Icons.savings_outlined, title: b.title, subtitle: "${U.s.moneyIn} ${money(b.inAmount)} · ${U.s.moneyOut} ${money(b.outAmount)}", trailing: UTextTitleSmall(money(b.closing))),
      ],
    ),
  );

  Widget _vouchersView(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: UColumn(
      children: <Widget>[
        if (vouchers.isEmpty) AppEmpty(title: U.s.noEntriesInThisPeriod),
        for (final UVoucherResponse v in vouchers)
          AppTile(
            icon: v.isManual ? Icons.edit_note_rounded : Icons.auto_mode_rounded,
            title: v.detail1 ?? TagVoucher.values.where((TagVoucher t) => t.number > 200 && v.tags.contains(t.number)).firstOrNull?.localizedTitle ?? U.s.entry,
            subtitle: "${v.number.toString().toPersianNumber()} · ${v.date.toJalaliDate().toPersianNumber()}",
            trailing: UTextTitleSmall(money(v.total)),
          ),
      ],
    ),
  );

  Widget _checksView(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: UColumn(
      children: <Widget>[
        if (checks.isEmpty) AppEmpty(title: U.s.noChequesYet),
        for (final UCheckResponse c in checks)
          AppTile(
            icon: Icons.request_page_outlined,
            title: "${money(c.amount)} · ${c.number.toPersianNumber()}",
            subtitle: "${TagCheck.values.where((TagCheck t) => t.number < 200 && c.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""} · ${c.dueDate.toJalaliDate().toPersianNumber()} · ${c.drawer ?? c.personName ?? ""}",
            trailing: AppChip(label: TagCheck.values.where((TagCheck t) => t.number > 200 && c.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""),
            onTap: canWrite && c.tags.contains(TagCheck.pending.number) ? () => _checkStatus(c) : null,
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(_title(tab)).help("app.accounting.page", inline: true), actions: const <Widget>[UHelpActions("app.accounting.")]),
    floatingActionButton: !canWrite
        ? null
        : tab == AccountingTab.vouchers
        ? FloatingActionButton.extended(onPressed: _expense, icon: const Icon(Icons.add_rounded), label: Text(U.s.recordAnExpense))
        : tab == AccountingTab.checks
        ? FloatingActionButton.extended(onPressed: _check, icon: const Icon(Icons.add_rounded), label: Text(U.s.newCheque))
        : null,
    body: UColumn(
      children: <Widget>[
        UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final AccountingTab t in AccountingTab.values)
                  ChoiceChip(label: Text(_title(t)), selected: tab == t, onSelected: (_) {
                    setState(() => tab = t);
                    read();
                  }),
              ],
            ),
            if (tab != AccountingTab.checks)
              URow(
                spacing: 10,
                children: <Widget>[
                  Expanded(child: UTextFieldDatePicker(labelText: U.s.from, jalali: true, initialDate: from, onChange: (DateTime d, _) {
                    from = d;
                    read();
                  })),
                  Expanded(child: UTextFieldDatePicker(labelText: U.s.until, jalali: true, initialDate: to, onChange: (DateTime d, _) {
                    to = d;
                    read();
                  })),
                ],
              ).pOnly(top: 8),
          ],
        ).pSymmetric(horizontal: 16, vertical: 10),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                switch (tab) {
                  AccountingTab.report => _report(context),
                  AccountingTab.vouchers => _vouchersView(context),
                  AccountingTab.checks => _checksView(context),
                  AccountingTab.boxes => _boxesView(context),
                },
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
