import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/money/accounting_page.dart";
import "package:khabroom/view/pages/business/money/settlement_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// The business's money in one place: what Khabroom pays out, and the books.
class MoneyPage extends StatelessWidget {
  const MoneyPage({super.key});

  static bool get allowed => AppWorkspace.isOwner || AppWorkspace.canAny(<TagUser>[TagUser.permissionManageAccounting, TagUser.permissionViewAccounting]);

  @override
  Widget build(BuildContext context) {
    final UOrganizationResponse o = AppWorkspace.org;
    final bool books = AppWorkspace.hasModule(TagModule.accounting) && AppWorkspace.canAny(<TagUser>[TagUser.permissionManageAccounting, TagUser.permissionViewAccounting]);
    return UScaffold(
      appBar: businessAppBar(context, U.s.money, help: "app.money.page"),
      body: AppPageBody(
        children: <Widget>[
          if (AppWorkspace.isOwner)
            AppCard(
              onTap: () => UNavigator.push(const SettlementPage()),
              child: AppTile(icon: Icons.account_balance_outlined, title: U.s.payoutsFromKhabroom, subtitle: "${U.s.waitingForPayout}: ${money(o.balance)}"),
            ).help("app.money.settlement").pOnly(bottom: 12),
          if (books) ...<Widget>[
            AppLabel(U.s.books),
            AppGrid(
              columns: 2,
              spacing: 12,
              children: <Widget>[
                AppFeatureTile(title: U.s.profitAndLoss, subtitle: U.s.incomeExpensesAndVat, icon: Icons.insights_outlined, onTap: () => UNavigator.push(const AccountingPage(tab: AccountingTab.report))),
                AppFeatureTile(title: U.s.expenses, subtitle: U.s.recordWhatYouSpent, icon: Icons.shopping_cart_checkout_outlined, onTap: () => UNavigator.push(const AccountingPage(tab: AccountingTab.vouchers))),
                AppFeatureTile(title: U.s.cheques, subtitle: U.s.chequesYouReceivedOrIssued, icon: Icons.request_page_outlined, onTap: () => UNavigator.push(const AccountingPage(tab: AccountingTab.checks))),
                AppFeatureTile(title: U.s.cashAndBank, subtitle: U.s.balanceOfEachBox, icon: Icons.savings_outlined, onTap: () => UNavigator.push(const AccountingPage(tab: AccountingTab.boxes))),
              ],
            ).help("app.money.books"),
          ] else if (!AppWorkspace.hasModule(TagModule.accounting))
            AppCard(child: AppTile(icon: Icons.lock_outline_rounded, title: U.s.booksAreNotInYourPlan, subtitle: U.s.addAccountingToYourSubscriptionToKeepBooks)),
        ],
      ),
    );
  }
}
