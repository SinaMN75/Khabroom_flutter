import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Money customers paid that Khabroom holds for the business, and every payout Khabroom made to its bank account.
class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key});

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  final URxState state = URxState();
  UOrganizationResponse? org;
  List<UWalletTxnResponse> txns = <UWalletTxnResponse>[];
  bool payouts = false;

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

  DateTime? get lastPayout => org?.jsonData.settlements.where((UOrganizationSettlement s) => s.approved == true).map((UOrganizationSettlement s) => s.processedAt ?? s.createdAt).fold<DateTime?>(null, (DateTime? a, DateTime b) => a == null || b.isAfter(a) ? b : a);

  Future<void> read() async {
    state.loading();
    final DateTime month = DateTime.now().subtract(const Duration(days: 30));
    org = (await UServices.organization.readOrganizations(p: UOrganizationReadParams(ids: <String>[AppWorkspace.org.id], fromDate: month, toDate: DateTime.now(), mine: true))).$1?.result?.firstOrNull;
    if (org == null) {
      state.error();
      return;
    }
    txns = (await UServices.wallet.readTxn(p: UWalletTxnReadParams(userId: org!.id, fromCreatedAt: lastPayout, pageSize: 200, pageNumber: 1, orderBy: TagOrderBy.createdAtDescending.number))).$1?.result ?? <UWalletTxnResponse>[];
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _requestEarly() async {
    final TextEditingController amount = TextEditingController(text: rialToTomanText(org!.balance));
    final TextEditingController note = TextEditingController();
    if (await AppForm.show(
      title: U.s.askForAnEarlyPayout,
      help: "app.settlement.early",
      submitTitle: U.s.sendRequest,
      onSubmit: () => appSend(UServices.organization.requestSettlement(p: UOrganizationSettlementRequestParams(organizationId: org!.id, amount: tomanToRial(amount), note: note.valueOrNull()))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextBodySmall(U.s.earlyPayoutExplanation),
        AppMoneyField(controller: amount, label: U.s.amount),
        UTextField(controller: note, labelText: U.s.note),
      ],
    )) await read();
    amount.dispose();
    note.dispose();
  }

  void _detail(UOrganizationSettlement s) => UNavigator.bottomSheet<void>(
    SafeArea(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextDisplaySmall(money(s.amount), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          AppInfoRow(label: U.s.status, value: s.approved == true ? U.s.depositedToYourAccount : s.approved == false ? U.s.notPaid : U.s.inProgress),
          AppInfoRow(label: U.s.date, value: (s.processedAt ?? s.createdAt).toJalaliDate().toPersianNumber()),
          AppInfoRow(label: U.s.iban, value: s.iban),
          if (s.trackingCode != null) AppInfoRow(label: U.s.trackingCode, value: s.trackingCode!.toPersianNumber(), emphasize: true),
          if (s.note != null) AppInfoRow(label: U.s.note, value: s.note!),
        ],
      ).pSymmetric(horizontal: 20, vertical: 8),
    ),
  );

  static String _txnTitle(UWalletTxnResponse t) => t.tag?.localizedTitle ?? t.jsonData.detail1 ?? U.s.payment;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.payoutsFromKhabroom).help("app.settlement.page", inline: true), actions: const <Widget>[UHelpActions("app.settlement.")]),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UOrganizationResponse o = org!;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final List<UOrganizationSettlement> list = o.jsonData.settlements.reversed.toList();
        return AppPageBody(
          onRefresh: read,
          maxWidth: AppResponsive.readableMaxWidth + 120,
          children: <Widget>[
            UContainer(
              radius: 24,
              padding: const EdgeInsets.all(20),
              color: scheme.onSurface,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextBodySmall(U.s.moneyYourCustomersPaidThatIsNotInYourAccountYet, color: scheme.surface.withValues(alpha: 0.75)),
                  const SizedBox(height: 6),
                  UTextDisplaySmall(money(o.balance), color: scheme.surface),
                  const SizedBox(height: 10),
                  UTextBodySmall(
                    "${U.s.paidOutDaily} · ${o.bankAccount?.iBanNumber == null ? U.s.addYourBankAccountInSettings : "${U.s.to} ${o.bankAccount!.iBanNumber!.substring(0, 4)} •••• ${o.bankAccount!.iBanNumber!.substring(o.bankAccount!.iBanNumber!.length - 4)}"}",
                    color: scheme.surface.withValues(alpha: 0.85),
                  ),
                ],
              ),
            ).help("app.settlement.balance"),
            const SizedBox(height: 12),
            if (o.payments != null)
              AppGrid(
                columns: 3,
                spacing: 10,
                children: <Widget>[
                  AppStat(label: U.s.receivedThisMonth, value: money(o.payments!.received), icon: Icons.south_west_rounded, tone: AppTone.positive),
                  AppStat(label: U.s.khabroomFee, value: money(o.payments!.commission), icon: Icons.percent_rounded, tone: AppTone.warning),
                  AppStat(label: U.s.paidOut, value: money(o.payments!.settled), icon: Icons.account_balance_outlined),
                ],
              ).help("app.settlement.month"),
            const SizedBox(height: 14),
            SegmentedButton<bool>(
              segments: <ButtonSegment<bool>>[ButtonSegment<bool>(value: false, label: Text(U.s.waitingForPayout)), ButtonSegment<bool>(value: true, label: Text(U.s.payouts))],
              selected: <bool>{payouts},
              onSelectionChanged: (Set<bool> v) => setState(() => payouts = v.first),
            ),
            const SizedBox(height: 12),
            if (!payouts) ...<Widget>[
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: UColumn(
                  children: <Widget>[
                    if (txns.isEmpty) AppEmpty(title: U.s.nothingNewSinceTheLastPayout),
                    for (final UWalletTxnResponse t in txns)
                      AppTile(
                        icon: t.receiverId == o.id ? Icons.south_west_rounded : Icons.north_east_rounded,
                        iconColor: t.receiverId == o.id ? AppColors.success : scheme.error,
                        title: _txnTitle(t),
                        subtitle: t.createdAt.toLocal().toJalaliDateTime().toPersianNumber(),
                        trailing: UTextTitleSmall("${t.receiverId == o.id ? "" : "−"}${money(t.amount)}"),
                      ),
                  ],
                ),
              ).help("app.settlement.pending"),
              const SizedBox(height: 12),
              if (AppWorkspace.isOwner && o.balance > 0) UButton(title: U.s.askForAnEarlyPayout, type: UButtonType.outlined, onTap: _requestEarly),
            ] else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: UColumn(
                  children: <Widget>[
                    if (list.isEmpty) AppEmpty(title: U.s.noPayoutsYet, icon: Icons.account_balance_outlined),
                    for (final UOrganizationSettlement s in list)
                      AppTile(
                        icon: Icons.account_balance_outlined,
                        iconColor: s.approved == false ? scheme.error : null,
                        title: money(s.amount),
                        subtitle: "${(s.processedAt ?? s.createdAt).toJalaliDate().toPersianNumber()}${s.trackingCode == null ? "" : " · ${U.s.trackingCode} ${s.trackingCode!.toPersianNumber()}"}",
                        trailing: AppChip(
                          label: s.approved == true ? U.s.deposited : s.approved == false ? U.s.notPaid : U.s.inProgress,
                          tone: s.approved == true ? AppTone.positive : s.approved == false ? AppTone.danger : AppTone.warning,
                        ),
                        onTap: () => _detail(s),
                      ),
                  ],
                ),
              ).help("app.settlement.payouts"),
          ],
        );
      },
    ),
  );
}
