import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/wallet/wallet_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final WalletController c = WalletController();

  @override
  void initState() {
    c.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.wallet)),
    body: RefreshIndicator(
      onRefresh: c.init,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth,
          child: UColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              UContainer(
                radius: 18,
                padding: const EdgeInsets.all(20),
                gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    UTextLabelMedium(U.s.walletBalance, color: AppColors.onGradient.withValues(alpha: 0.85)),
                    const SizedBox(height: 10),
                    Obx(
                      () => c.walletState.isLoaded()
                          ? UTextDisplaySmall(money(c.balance), color: AppColors.onGradient)
                          : const UProgressCircular(size: 26, strokeWidth: 2, progressColor: AppColors.onGradient),
                    ),
                    const SizedBox(height: 16),
                    UButton(
                      title: U.s.topUpWallet,
                      icon: const Icon(Icons.add_rounded),
                      backgroundColor: AppColors.onGradient,
                      foregroundColor: AppColors.brand,
                      onTap: c.topUp,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppSectionHeader(title: U.s.transactions),
              const SizedBox(height: 12),
              AppStateView(
                state: c.txnState,
                onRetry: c.readTxns,
                emptyTitle: U.s.noTransactions,
                emptyIcon: Icons.receipt_long_outlined,
                onLoaded: (BuildContext context) => AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: UColumn(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (final UWalletTxnResponse txn in c.txns) _TxnRow(txn: txn),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TxnRow extends StatelessWidget {
  const _TxnRow({required this.txn});

  final UWalletTxnResponse txn;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool incoming = txn.receiverId == U.user.id;
    final String title = TagWalletTxn.values.firstWhereOrNull((TagWalletTxn t) => txn.tags.contains(t.number))?.titleFa ?? U.s.transactions;

    return URow(
      children: <Widget>[
        UIconBackground(
          incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: incoming ? AppColors.success : scheme.onSurfaceVariant,
          size: 36,
        ),
        const SizedBox(width: 12),
        UColumn(
          expanded: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleSmall(title, color: scheme.onSurface),
            const SizedBox(height: 3),
            UTextLabelSmall(txn.createdAt.toJalaliDateTime(), color: scheme.onSurfaceVariant),
          ],
        ),
        UTextTitleSmall(money(txn.amount), color: incoming ? AppColors.success : scheme.onSurface),
      ],
    ).pSymmetric(horizontal: 14, vertical: 12);
  }
}
