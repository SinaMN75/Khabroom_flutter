import "dart:math" as math;

import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// One payment screen for every bill: the wallet pays first and only the rest goes to the card.
/// The server takes the wallet part only after the card payment succeeds, so a failed card never costs the wallet anything.
abstract class AppPay {
  static Future<double> walletBalance() async {
    final (UResponse<UUserResponse>? ok, _, _) = await UServices.user.readById(p: UIdParams(id: U.user.id, selectorArgs: const UUserSelectorArgs(wallet: UWalletSelectorArgs())));
    if (ok?.result != null) U.user = ok!.result!;
    return (U.user.wallets ?? <UWalletResponse>[]).fold<double>(0, (double sum, UWalletResponse w) => sum + w.balance);
  }

  static Future<bool> pay({
    required String title,
    required double amount,
    required TagTxn tag,
    required String invoiceId,
    required Future<(dynamic, dynamic, String?)> Function() payFromWallet,
    List<(String, String)> lines = const <(String, String)>[],
  }) async {
    ULoading.show();
    final double balance = await walletBalance();
    ULoading.dismiss();
    return await UNavigator.bottomSheet<bool>(
          _PaySheet(title: title, amount: amount, balance: balance, tag: tag, invoiceId: invoiceId, payFromWallet: payFromWallet, lines: lines),
          showDragHandle: true,
        ) ??
        false;
  }
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.title, required this.amount, required this.balance, required this.tag, required this.invoiceId, required this.payFromWallet, required this.lines});

  final String title;
  final double amount;
  final double balance;
  final TagTxn tag;
  final String invoiceId;
  final Future<(dynamic, dynamic, String?)> Function() payFromWallet;
  final List<(String, String)> lines;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  bool useWallet = true;
  bool busy = false;

  double get fromWallet => useWallet ? math.min(widget.balance, widget.amount) : 0;

  double get fromCard => widget.amount - fromWallet;

  Future<void> _pay() async {
    setState(() => busy = true);
    final bool paid;
    if (fromCard <= 0) {
      final (dynamic ok, dynamic error, String? exception) = await widget.payFromWallet();
      paid = ok != null;
      if (!paid) UToast.error(message: (error is UEmptyResponse ? error.message : error is UResponse ? error.message : null) ?? exception ?? U.s.error);
      if (paid) {
        UNavigator.back(true);
        await UReceiptSheet.show(UReceipt(title: widget.title, amount: widget.amount.toInt(), method: U.s.payWithWallet, rows: await UReceiptKeyValues.latestWalletTxnRows()));
        return;
      }
    } else {
      paid = await UIpgFlow.pay(
        p: UIpgPayParams(amount: fromCard.ceilToDouble(), tag: widget.tag, invoiceId: widget.invoiceId),
        receipt: UReceipt(title: widget.title, amount: widget.amount.toInt(), method: fromWallet > 0 ? U.s.walletAndCard : U.s.onlinePayment),
      );
      if (paid) {
        UNavigator.back(true);
        return;
      }
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextBodySmall(widget.title, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          UTextDisplaySmall(money(widget.amount), textAlign: TextAlign.center).help("app.pay.amount"),
          const SizedBox(height: 16),
          if (widget.lines.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: UColumn(mainAxisSize: MainAxisSize.min, children: <Widget>[for (final (String, String) l in widget.lines) AppInfoRow(label: l.$1, value: l.$2)]),
            ).pOnly(bottom: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: UColumn(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: useWallet && widget.balance > 0,
                  onChanged: widget.balance <= 0 ? null : (bool v) => setState(() => useWallet = v),
                  secondary: Icon(Icons.account_balance_wallet_outlined, color: scheme.primary),
                  title: UTextTitleSmall(U.s.payFromWalletFirst),
                  subtitle: UTextBodySmall("${U.s.walletBalance}: ${money(widget.balance)}", color: scheme.onSurfaceVariant),
                ).help("app.pay.wallet"),
                const Divider(),
                AppInfoRow(label: U.s.fromWallet, value: money(fromWallet)),
                AppInfoRow(label: U.s.byCard, value: money(fromCard), emphasize: true),
              ],
            ),
          ),
          const SizedBox(height: 18),
          UButton(title: "${U.s.pay} ${money(widget.amount)}", isLoading: busy, onTap: busy ? null : _pay).help("app.pay.button"),
          const SizedBox(height: 8),
          UTextBodySmall(fromCard > 0 ? U.s.yourWalletIsChargedOnlyAfterTheCardPaymentSucceeds : U.s.paidFullyFromYourWallet, color: scheme.onSurfaceVariant, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
