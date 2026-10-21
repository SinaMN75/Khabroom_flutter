import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/money/settlement_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The business's money: what Khabroom pays out.
class MoneyPage extends StatelessWidget {
  const MoneyPage({super.key});

  static bool get allowed => AppWorkspace.isOwner;

  @override
  Widget build(BuildContext context) {
    final UOrganizationResponse o = AppWorkspace.org;
    return UScaffold(
      appBar: businessAppBar(context, U.s.money, help: "app.money.page"),
      body: AppPageBody(
        children: <Widget>[
          AppCard(
            onTap: () => UNavigator.push(const SettlementPage()),
            child: AppTile(icon: Icons.account_balance_outlined, title: U.s.payoutsFromKhabroom, subtitle: "${U.s.waitingForPayout}: ${money(o.balance)}"),
          ).help("app.money.settlement"),
        ],
      ),
    );
  }
}
