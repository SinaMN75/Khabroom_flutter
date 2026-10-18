import "package:u/utilities.dart";

class WalletController extends UBaseController {
  final URxState walletState = URxState();
  final URxState txnState = URxState();

  double balance = 0;
  List<UWalletTxnResponse> txns = <UWalletTxnResponse>[];

  Future<void> init() async {
    await readWallet();
    await readTxns();
  }

  Future<void> readWallet() async {
    walletState.loading();
    await UServices.wallet.readByUserId(
      p: UIdParams(id: U.user.id),
      onOk: (UResponse<List<UWalletResponse>> response) {
        balance = response.result.primary().balance;
        walletState.loaded();
      },
      onError: (UEmptyResponse response) => walletState.error(),
      onException: (String exception) => walletState.error(),
    );
  }

  Future<void> readTxns() async {
    txnState.loading();
    await UServices.wallet.readTxn(
      p: UWalletTxnReadParams(userId: U.user.id, pageSize: 30),
      onOk: (UResponse<List<UWalletTxnResponse>> response) {
        txns = response.result ?? <UWalletTxnResponse>[];
        txns.isEmpty ? txnState.emptying() : txnState.loaded();
      },
      onError: (UEmptyResponse response) => txnState.error(),
      onException: (String exception) => txnState.error(),
    );
  }

  Future<void> topUp() async {
    final String? value = await UNavigator.inputDialog(title: U.s.topUpWallet, hint: "${U.s.amount} (${U.s.toman})", keyboardType: TextInputType.number, lines: 1);
    if (value == null || value.trim().isEmpty) return;
    final double toman = double.tryParse(value.toLatinNumber().replaceAll(",", "").replaceAll("٬", "").trim()) ?? 0;
    if (toman < 1000 || toman > 50000000) {
      UToast.error(message: U.s.topUpAmountRange);
      return;
    }
    final double amount = toman * 10;
    final bool paid = await UIpgFlow.pay(
      p: UIpgPayParams(amount: amount, tag: TagTxn.chargeWallet),
      receipt: UReceipt(
        title: U.s.topUpWallet,
        amount: amount.toInt(),
        icon: Icons.add_card_outlined,
        method: U.s.onlinePayment,
      ),
    );
    if (paid) await init();
  }

  Future<void> showReceipt(UWalletTxnResponse txn) => UReceiptSheet.show(
    UReceipt(
      title: txn.title(),
      amount: txn.amount.toInt(),
      icon: txn.icon,
      method: txn.isOutgoing() ? U.s.payWithWallet : U.s.chargeWallet,
      date: txn.createdAt,
      rows: txn.receiptRows,
    ),
  );
}
