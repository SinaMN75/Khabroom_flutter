import "package:khabroom/utils/app_pay.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/business/setup/plan_picker.dart";
import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// What the business has bought, until when, and renewing or adding a system.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final URxState state = URxState();
  List<USubscriptionPlanResponse> plans = <USubscriptionPlanResponse>[];
  USubscriptionPlanResponse? plan;
  USubscriptionQuoteResponse? quote;
  int months = 1;
  bool busy = false;

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
    await AppWorkspace.refresh();
    plans = (await UServices.organization.readPlans(p: USubscriptionPlanReadParams())).$1?.result ?? <USubscriptionPlanResponse>[];
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _quote() async {
    if (plan == null) return;
    quote = (await UServices.organization.quoteSubscription(p: USubscriptionQuoteParams(planId: plan!.id, months: months, organizationId: AppWorkspace.org.id))).$1?.result;
    if (mounted) setState(() {});
  }

  Future<void> _buy() async {
    if (plan == null) return;
    setState(() => busy = true);
    final (UResponse<USubscriptionBuyResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.organization.buySubscription(
      p: USubscriptionBuyParams(planId: plan!.id, months: months, organizationId: AppWorkspace.org.id),
    );
    final USubscriptionBuyResponse? r = ok?.result;
    if (r == null) {
      UToast.error(message: error?.message ?? exception ?? U.s.error);
    } else if (!r.active) {
      await AppPay.pay(
        title: "${U.s.subscription} ${plan!.title}",
        amount: r.payable,
        tag: TagTxn.subscription,
        invoiceId: r.organizationId,
        payFromWallet: () => UServices.organization.paySubscription(p: UIdParams(id: r.organizationId)),
      );
    } else {
      UToast.success(message: U.s.done);
    }
    if (mounted) setState(() => busy = false);
    await read();
  }

  @override
  Widget build(BuildContext context) {
    final UOrganizationResponse o = AppWorkspace.org;
    final List<UOrganizationSubscription> live = o.jsonData.subscriptions.where((UOrganizationSubscription s) => s.isLive).toList();
    return UScaffold(
      appBar: AppBar(title: Text(U.s.subscription).help("app.subscription.page", inline: true), actions: const <Widget>[UHelpActions("app.subscription.")]),
      body: AppStateView(
        state: state,
        onRetry: read,
        onLoaded: (BuildContext context) => AppPageBody(
          maxWidth: AppResponsive.readableMaxWidth,
          children: <Widget>[
            AppSectionCard(
              title: U.s.whatYouHave,
              icon: Icons.workspace_premium_outlined,
              child: UColumn(
                children: <Widget>[
                  if (live.isEmpty) UTextBodySmall(U.s.noActiveSubscription),
                  for (final UOrganizationSubscription s in live)
                    AppInfoRow(label: s.title, value: "${U.s.until} ${s.expiresAt!.toJalaliDate().toPersianNumber()}${s.trial ? " · ${U.s.trial}" : ""}"),
                ],
              ),
            ).help("app.subscription.current"),
            AppLabel(U.s.renewOrAddASystem),
            PlanPicker(
              plans: plans,
              selected: plan,
              months: months,
              onSelected: (USubscriptionPlanResponse p) {
                setState(() => plan = p);
                _quote();
              },
              onMonths: (int m) {
                setState(() => months = m);
                _quote();
              },
            ),
            if (quote != null)
              AppCard(
                child: UColumn(
                  children: <Widget>[
                    AppInfoRow(label: U.s.price, value: money(quote!.price)),
                    if (quote!.credit > 0) AppInfoRow(label: U.s.creditFromYourCurrentPlan, value: "− ${money(quote!.credit)}"),
                    AppInfoRow(label: U.s.toPay, value: money(quote!.payable), emphasize: true),
                    if (quote!.expiresAt != null) AppInfoRow(label: U.s.until, value: quote!.expiresAt!.toJalaliDate().toPersianNumber()),
                  ],
                ),
              ).help("app.subscription.quote").pOnly(bottom: 12),
            UButton(title: quote?.renewal ?? false ? U.s.renew : U.s.buy, isLoading: busy, onTap: plan == null || busy ? null : _buy),
          ],
        ),
      ),
    );
  }
}
