import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/contracts/my_contracts_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class MyContractsPage extends StatefulWidget {
  const MyContractsPage({super.key});

  @override
  State<MyContractsPage> createState() => _MyContractsPageState();
}

class _MyContractsPageState extends State<MyContractsPage> {
  final MyContractsController c = MyContractsController();

  @override
  void initState() {
    c.read();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.dormContracts)),
    body: RefreshIndicator(
      onRefresh: c.read,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth + 160,
          child: AppStateView(
            state: c.contractState,
            onRetry: c.read,
            emptyTitle: U.s.youHaveNoContracts,
            emptyIcon: Icons.assignment_outlined,
            onLoaded: (BuildContext context) => UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final UDormBedContractResponse contract in c.contracts) _contractCard(context, contract).pOnly(bottom: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _contractCard(BuildContext context, UDormBedContractResponse contract) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<UDormBedInvoiceResponse> invoices = c.invoicesByContract[contract.id] ?? <UDormBedInvoiceResponse>[];
    final String dormTitle = contract.bed?.room?.dorm?.title ?? U.s.dormTitle;

    return AppCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UColumn(
                expanded: 1,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  UTextTitleMedium(dormTitle, color: scheme.onSurface),
                  const SizedBox(height: 5),
                  UTextBodySmall(
                    "${contract.bed?.room?.title ?? U.s.roomTitle} · ${U.s.bedTitle} ${contract.bed?.title.toPersianNumber() ?? ""}",
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              AppChip(label: contract.isActive ? U.s.active : U.s.past, tone: contract.isActive ? AppTone.positive : AppTone.neutral),
            ],
          ),
          const SizedBox(height: 12),
          AppInfoRow(label: U.s.contractPeriod, value: "${contract.startDate.toJalaliDate()} — ${contract.endDate.toJalaliDate()}"),
          AppInfoRow(label: U.s.deposit, value: money(contract.deposit)),
          AppInfoRow(label: U.s.rent, value: money(contract.rent)),
          const Divider(height: 24),
          UTextTitleSmall(U.s.monthlyInvoices, color: scheme.onSurface),
          const SizedBox(height: 10),
          if (invoices.isEmpty)
            UTextBodySmall(U.s.youHaveNoInvoices, color: scheme.onSurfaceVariant)
          else
            for (final UDormBedInvoiceResponse invoice in invoices) _invoiceRow(context, invoice),
        ],
      ),
    );
  }

  Widget _invoiceRow(BuildContext context, UDormBedInvoiceResponse invoice) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool unpaid = invoice.tags.contains(TagDormBedInvoice.notPaid.number);
    final bool isDeposit = invoice.tags.contains(TagDormBedInvoice.deposit.number);
    final double payable = invoice.debtAmount + invoice.penaltyAmount - invoice.creditorAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: UContainer(
        radius: 13,
        padding: const EdgeInsets.all(13),
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outlineVariant),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            URow(
              children: <Widget>[
                UColumn(
                  expanded: 1,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextTitleSmall(isDeposit ? U.s.deposit : U.s.rent, color: scheme.onSurface),
                    const SizedBox(height: 4),
                    UTextBodySmall("${U.s.dueDate}: ${invoice.dueDate.toJalaliDate()}", color: scheme.onSurfaceVariant),
                  ],
                ),
                AppStatusChip(status: AppStatus.dormInvoice(invoice.tags, invoice.dueDate)),
              ],
            ),
            const SizedBox(height: 10),
            URow(
              children: <Widget>[
                AppPrice(amount: payable).expanded(),
                if (invoice.penaltyAmount > 0) AppChip(label: "${U.s.penaltyAmount}: ${money(invoice.penaltyAmount)}", tone: AppTone.danger),
              ],
            ),
            if (unpaid) ...<Widget>[
              const SizedBox(height: 12),
              URow(
                children: <Widget>[
                  UButton(expanded: 1, title: U.s.payFromWallet, type: UButtonType.outlined, onTap: () => c.payFromWallet(invoice)),
                  const SizedBox(width: 10),
                  UButton(expanded: 1, title: U.s.payWithGateway, onTap: () => c.payWithGateway(invoice)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
