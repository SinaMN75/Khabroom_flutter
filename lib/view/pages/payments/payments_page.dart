import "package:khabroom/main.dart";
import "package:khabroom/utils/app_pay.dart";
import "package:khabroom/utils/status_helpers.dart";
import "package:khabroom/view/pages/contracts/my_contracts_page.dart";
import "package:khabroom/view/pages/menu/my_orders_page.dart";
import "package:khabroom/view/pages/wallet/wallet_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Everything the user has to pay, from every place, in one list.
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _Bill {
  _Bill({required this.title, required this.place, required this.amount, required this.dueDate, required this.status, required this.icon, required this.onPay});

  final String title;
  final String place;
  final double amount;
  final DateTime dueDate;
  final (String, AppTone) status;
  final IconData icon;
  final Future<bool> Function() onPay;
}

class _PaymentsPageState extends State<PaymentsPage> {
  final URxState state = URxState();
  List<_Bill> bills = <_Bill>[];
  double balance = 0;

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

  static double _due(double debt, double penalty, double creditor, double paid) => debt + penalty - creditor - paid;

  Future<void> read() async {
    state.loading();
    final List<UDormBedInvoiceResponse>? dorm = (await UServices.dorm.readDormBedInvoice(
      p: UDormBedInvoiceReadParams(
        userId: U.user.id,
        isPaid: false,
        pageSize: 50,
        selectorArgs: const UDormBedInvoiceSelectorArgs(contract: UDormBedContractSelectorArgs(bed: UDormBedSelectorArgs(room: UDormRoomSelectorArgs(dorm: UDormSelectorArgs())))),
      ),
    )).$1?.result;
    final List<UHotelInvoiceResponse>? hotel = (await UServices.hotel.readHotelInvoices(
      p: UHotelInvoiceReadParams(userId: U.user.id, isPaid: false, pageSize: 50, selectorArgs: const UHotelInvoiceSelectorArgs(reservation: UHotelReservationSelectorArgs(hotel: UHotelSelectorArgs()))),
    )).$1?.result;
    balance = await AppPay.walletBalance();
    if (dorm == null || hotel == null) {
      state.error();
      return;
    }
    bills = <_Bill>[
      for (final UDormBedInvoiceResponse i in dorm.where((UDormBedInvoiceResponse i) => i.tags.contains(TagDormBedInvoice.notPaid.number)))
        _Bill(
          title: TagDormBedInvoice.values.where((TagDormBedInvoice t) => t.number < 200 && i.tags.contains(t.number)).firstOrNull?.localizedTitle ?? U.s.invoice,
          place: i.contract?.bed?.room?.dorm?.title ?? U.s.dorm,
          amount: _due(i.debtAmount, i.penaltyAmount, i.creditorAmount, i.paidAmount),
          dueDate: i.dueDate,
          status: AppStatus.dormInvoice(i.tags, i.dueDate),
          icon: Icons.bedroom_parent_outlined,
          onPay: () => AppPay.pay(
            title: U.s.payInvoice,
            amount: _due(i.debtAmount, i.penaltyAmount, i.creditorAmount, i.paidAmount),
            tag: TagTxn.dormInvoice,
            invoiceId: i.id,
            payFromWallet: () => UServices.dorm.payDormBedInvoice(p: UIdParams(id: i.id)),
          ),
        ),
      for (final UHotelInvoiceResponse i in hotel.where((UHotelInvoiceResponse i) => i.tags.contains(TagHotelInvoice.notPaid.number)))
        _Bill(
          title: U.s.hotelReservation,
          place: i.reservation?.hotel?.title ?? U.s.hotel,
          amount: _due(i.debtAmount, i.penaltyAmount, i.creditorAmount, i.paidAmount),
          dueDate: i.dueDate,
          status: AppStatus.hotelInvoice(i.tags, i.dueDate),
          icon: Icons.apartment_outlined,
          onPay: () => AppPay.pay(
            title: U.s.payInvoice,
            amount: _due(i.debtAmount, i.penaltyAmount, i.creditorAmount, i.paidAmount),
            tag: TagTxn.hotelInvoice,
            invoiceId: i.id,
            payFromWallet: () => UServices.hotel.payHotelInvoice(p: UIdParams(id: i.id)),
          ),
        ),
    ]..sort((_Bill a, _Bill b) => a.dueDate.compareTo(b.dueDate));
    if (mounted) setState(() {});
    state.loaded();
  }

  double get total => bills.fold<double>(0, (double s, _Bill b) => s + b.amount);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.myPayments).help("app.payments.page", inline: true), actions: const <Widget>[UHelpActions("app.payments.")]),
      body: AppStateView(
        state: state,
        onRetry: read,
        onLoaded: (BuildContext context) => AppPageBody(
          onRefresh: read,
          maxWidth: 760,
          children: <Widget>[
            UContainer(
              radius: 22,
              padding: const EdgeInsets.all(18),
              gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  UTextLabelMedium(bills.isEmpty ? U.s.youHaveNothingToPay : U.s.totalToPay, color: AppColors.onGradient.withValues(alpha: 0.85)),
                  const SizedBox(height: 6),
                  UTextDisplaySmall(money(total), color: AppColors.onGradient),
                  const SizedBox(height: 10),
                  URow(
                    children: <Widget>[
                      const Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.onGradient),
                      const SizedBox(width: 6),
                      UTextBodySmall("${U.s.walletBalance}: ${money(balance)}", color: AppColors.onGradient, expanded: 1),
                      UButton(title: U.s.wallet, type: UButtonType.text, foregroundColor: AppColors.onGradient, onTap: () => UNavigator.push(const WalletPage())),
                    ],
                  ),
                ],
              ),
            ).help("app.payments.total"),
            const SizedBox(height: 18),
            if (bills.isNotEmpty) ...<Widget>[
              AppLabel(U.s.waitingForPayment),
              for (final _Bill b in bills)
                AppCard(
                  padding: const EdgeInsets.all(14),
                  child: URow(
                    children: <Widget>[
                      UContainer(width: 42, height: 42, radius: 13, color: scheme.primaryContainer, alignment: Alignment.center, child: Icon(b.icon, color: scheme.primary, size: 20)),
                      const SizedBox(width: 12),
                      UColumn(
                        expanded: 1,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          UTextTitleSmall("${b.title} · ${b.place}", maxLines: 1),
                          URow(children: <Widget>[UTextBodySmall("${U.s.dueDate}: ${b.dueDate.toJalaliDate().toPersianNumber()}", color: scheme.onSurfaceVariant), const SizedBox(width: 8), AppStatusChip(status: b.status)]),
                        ],
                      ),
                      UColumn(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          UTextTitleSmall(money(b.amount)),
                          UButton(title: U.s.pay, size: UButtonSize.small, onTap: () async {
                            if (await b.onPay()) await read();
                          }),
                        ],
                      ),
                    ],
                  ),
                ).pOnly(bottom: 10),
            ],
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UColumn(
                children: <Widget>[
                  AppTile(icon: Icons.assignment_outlined, title: U.s.dormContracts, subtitle: U.s.contractsAndAllDormInvoices, onTap: () => UNavigator.push(const MyContractsPage())),
                  AppTile(icon: Icons.local_cafe_outlined, title: U.s.myOrders, subtitle: U.s.yourCafeOrdersAndTheirStatus, onTap: () => UNavigator.push(const MyOrdersPage())),
                  AppTile(icon: Icons.account_balance_wallet_outlined, title: U.s.wallet, subtitle: U.s.topUpAndTransactions, onTap: () => UNavigator.push(const WalletPage())),
                ],
              ),
            ).help("app.payments.links"),
          ],
        ),
      ),
    );
  }
}
