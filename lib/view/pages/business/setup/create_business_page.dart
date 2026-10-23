import "package:khabroom/utils/app_pay.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/setup/plan_picker.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Start a business in three steps: its name, the bank account for payouts, and a plan (with a free trial when the plan has one).
class CreateBusinessPage extends StatefulWidget {
  const CreateBusinessPage({super.key});

  @override
  State<CreateBusinessPage> createState() => _CreateBusinessPageState();
}

class _CreateBusinessPageState extends State<CreateBusinessPage> {
  final List<GlobalKey<FormState>> keys = <GlobalKey<FormState>>[GlobalKey<FormState>(), GlobalKey<FormState>()];
  final TextEditingController title = TextEditingController();
  final TextEditingController firstName = TextEditingController(text: AppSession.isGuest ? "" : U.user.firstName);
  final TextEditingController lastName = TextEditingController(text: AppSession.isGuest ? "" : U.user.lastName);
  final TextEditingController iban = TextEditingController();
  final TextEditingController card = TextEditingController();
  final TextEditingController account = TextEditingController();
  List<USubscriptionPlanResponse> plans = <USubscriptionPlanResponse>[];
  USubscriptionPlanResponse? plan;
  int months = 1;
  int step = 0;
  bool busy = false;
  bool trialAvailable = true;

  @override
  void initState() {
    readPlans();
    super.initState();
  }

  /// Plans, and whether this person still has a free trial: it is given once per owner, not per business.
  Future<void> readPlans() async {
    plans = (await UServices.organization.readPlans(p: USubscriptionPlanReadParams())).$1?.result ?? <USubscriptionPlanResponse>[];
    final USubscriptionPlanResponse? withTrial = plans.where((USubscriptionPlanResponse p) => p.trialDays > 0).firstOrNull;
    if (withTrial != null && !AppSession.isGuest) {
      trialAvailable = (await UServices.organization.quoteSubscription(p: USubscriptionQuoteParams(planId: withTrial.id, months: 0, trial: true))).$1 != null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[title, firstName, lastName, iban, card, account]) c.dispose();
    super.dispose();
  }

  void _next() {
    if (step < 2 && !(keys[step].currentState?.validate() ?? false)) return;
    if (step < 2) {
      setState(() => step++);
      return;
    }
    AppSession.require(_create);
  }

  Future<void> _create() async {
    if (plan == null) {
      UToast.error(message: U.s.pickAPlan);
      return;
    }
    setState(() => busy = true);
    if ((U.user.firstName ?? "").isEmpty || (U.user.lastName ?? "").isEmpty) {
      await UServices.user.update(p: UUserUpdateParams(id: U.user.id, firstName: firstName.text.trim(), lastName: lastName.text.trim()));
      await AppSession.load();
    }
    final bool trial = trialAvailable && plan!.trialDays > 0;
    final (UResponse<USubscriptionBuyResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.organization.buySubscription(
      p: USubscriptionBuyParams(planId: plan!.id, months: trial ? 0 : months, trial: trial, title: title.text.trim(), iBanNumber: iban.text.trim(), cardNumber: card.text.trim(), accountNumber: account.text.trim()),
    );
    final USubscriptionBuyResponse? r = ok?.result;
    if (r == null) {
      UToast.error(message: error?.message ?? exception ?? U.s.error);
      if (mounted) setState(() => busy = false);
      return;
    }
    if (!r.active) {
      await AppPay.pay(
        title: "${U.s.subscription} ${plan!.title}",
        amount: r.payable,
        tag: TagTxn.subscription,
        invoiceId: r.organizationId,
        payFromWallet: () => UServices.organization.paySubscription(p: UIdParams(id: r.organizationId)),
      );
    }
    await AppWorkspace.load();
    final UOrganizationResponse? created = AppWorkspace.organizations.where((UOrganizationResponse o) => o.id == r.organizationId).firstOrNull;
    await AppWorkspace.open(created);
    if (created != null) await UNavigator.offAll(const BusinessPage());
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(title: Text(U.s.newBusiness).help("app.create.page", inline: true), actions: const <Widget>[UHelpActions("app.create.")]),
      body: AppPageBody(
        maxWidth: AppResponsive.readableMaxWidth,
        children: <Widget>[
          URow(
            spacing: 6,
            children: <Widget>[for (int i = 0; i < 3; i++) Expanded(child: UContainer(height: 5, radius: 3, color: i <= step ? scheme.primary : scheme.outlineVariant))],
          ),
          const SizedBox(height: 16),
          if (step == 0)
            Form(
              key: keys[0],
              child: AppSectionCard(
                title: U.s.aboutYourBusiness,
                icon: Icons.storefront_outlined,
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: <Widget>[
                    UTextField(controller: title, labelText: U.s.businessName, hintText: U.s.forExampleYasGroup, validator: UValidators.required<String>()),
                    UTextBodySmall(U.s.youCanAddDormsAndHotelsToItLater, color: scheme.onSurfaceVariant, maxLines: 6),
                    URow(
                      spacing: 10,
                      children: <Widget>[
                        Expanded(child: UTextField(controller: firstName, labelText: U.s.yourFirstName, validator: UValidators.required<String>())),
                        Expanded(child: UTextField(controller: lastName, labelText: U.s.yourLastName, validator: UValidators.required<String>())),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          if (step == 1)
            Form(
              key: keys[1],
              child: AppSectionCard(
                title: U.s.whereShouldWePayYou,
                icon: Icons.account_balance_outlined,
                child: UColumn(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: <Widget>[
                    UTextBodySmall(U.s.customersPayInTheAppKhabroomDepositsToThisAccountDaily, color: scheme.onSurfaceVariant, maxLines: 6),
                    UTextField(controller: iban, labelText: U.s.iban, validator: UValidators.iban()),
                    UTextField(controller: card, labelText: U.s.cardNumber, keyboardType: TextInputType.number, validator: UValidators.cardNumber()),
                    UTextField(controller: account, labelText: U.s.accountNumber, keyboardType: TextInputType.number, validator: UValidators.required<String>()),
                  ],
                ),
              ).help("app.create.bank"),
            ),
          if (step == 2) ...<Widget>[
            AppLabel(U.s.pickAPlan),
            PlanPicker(trial: trialAvailable, plans: plans, selected: plan, months: months, onSelected: (USubscriptionPlanResponse p) => setState(() => plan = p), onMonths: (int m) => setState(() => months = m)),
            if (trialAvailable && plan != null && plan!.trialDays > 0) UTextBodySmall(U.s.youStartWithTheFreeTrialAndPayWhenItEnds, color: scheme.onSurfaceVariant, textAlign: TextAlign.center, maxLines: 6),
          ],
          const SizedBox(height: 16),
          URow(
            spacing: 10,
            children: <Widget>[
              if (step > 0) Expanded(child: UButton(title: U.s.back, type: UButtonType.outlined, onTap: () => setState(() => step--))),
              Expanded(flex: 2, child: UButton(title: step < 2 ? U.s.next : U.s.startMyBusiness, isLoading: busy, onTap: busy ? null : _next)),
            ],
          ),
        ],
      ),
    );
  }
}
