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
    final List<UOrganizationSubscription> live = AppWorkspace.liveSubscriptions(o);
    final List<UOrganizationSubscription> upcoming = o.jsonData.subscriptions.where((UOrganizationSubscription s) => s.status == TagSubscription.active.number && (s.startsAt?.isAfter(DateTime.now()) ?? false)).toList();
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
                  if (live.isEmpty) UTextBodySmall(AppWorkspace.subscriptionEnded(o) ? U.s.yourSubscriptionHasEnded : U.s.noActiveSubscription),
                  for (final UOrganizationSubscription s in live) ...<Widget>[
                    AppInfoRow(label: s.title, value: "${U.s.until} ${s.expiresAt!.toJalaliDate().toPersianNumber()}${s.trial ? " · ${U.s.trial}" : ""}"),
                    if (s.limits.isNotEmpty) PlanLimits(limits: s.limits).pOnly(bottom: 8),
                  ],
                  for (final UOrganizationSubscription s in upcoming) AppInfoRow(label: s.title, value: "${U.s.startsOn} ${s.startsAt!.toJalaliDate().toPersianNumber()}"),
                ],
              ),
            ).help("app.subscription.current"),
            AppLabel(U.s.renewOrAddASystem),
            PlanPicker(
              trial: false,
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

/// The business's plan at a glance: ended, on a free trial, or ending soon. The owner taps it to renew.
class SubscriptionBanner extends StatelessWidget {
  const SubscriptionBanner({super.key, this.onReturn});

  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    final UOrganizationResponse o = AppWorkspace.org;
    final bool ended = AppWorkspace.subscriptionEnded(o);
    final List<UOrganizationSubscription> live = AppWorkspace.liveSubscriptions(o);
    final DateTime? endsAt = o.subscriptionEndsAt;
    final int daysLeft = endsAt == null ? 0 : endsAt.difference(DateTime.now()).inDays;
    final bool trial = live.isNotEmpty && live.every((UOrganizationSubscription s) => s.trial);
    if (!ended && !trial && (endsAt == null || daysLeft >= 10)) return const SizedBox.shrink();
    final AppTone tone = ended ? AppTone.danger : trial ? AppTone.positive : AppTone.warning;
    final String title = ended ? U.s.yourSubscriptionHasEnded : trial ? U.s.youAreOnTheFreeTrial : U.s.yourSubscriptionEndsSoon;
    final String subtitle = ended
        ? AppWorkspace.isOwner
              ? U.s.renewItToKeepUsingReservationsResidentsAndYourPlaces
              : U.s.askTheOwnerToRenewTheSubscription
        : "${U.s.endsOn} ${endsAt!.toJalaliDate().toPersianNumber()} · ${daysLeft.toString().toPersianNumber()} ${U.s.daysLeft}";
    return AppCard(
      onTap: AppWorkspace.isOwner ? () => UNavigator.push(const SubscriptionPage()).then((_) => onReturn?.call()) : null,
      child: AppTile(
        icon: ended ? Icons.lock_clock_outlined : Icons.workspace_premium_outlined,
        iconColor: tone.foreground(context),
        title: title,
        subtitle: subtitle,
        trailing: AppWorkspace.isOwner ? AppChip(label: ended ? U.s.renew : U.s.subscription, tone: tone) : null,
      ),
    ).pOnly(bottom: 12).help("app.today.subscription");
  }
}
