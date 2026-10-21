import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The business's name and contact details, the bank account payouts go to, and tax details for invoices.
class BusinessSettingsPage extends StatefulWidget {
  const BusinessSettingsPage({super.key});

  @override
  State<BusinessSettingsPage> createState() => _BusinessSettingsPageState();
}

class _BusinessSettingsPageState extends State<BusinessSettingsPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final UOrganizationResponse o = AppWorkspace.org;
  late final TextEditingController title = TextEditingController(text: o.title);
  late final TextEditingController phone = TextEditingController(text: o.jsonData.phoneNumber);
  late final TextEditingController address = TextEditingController(text: o.jsonData.address);
  late final TextEditingController card = TextEditingController(text: o.bankAccount?.cardNumber);
  late final TextEditingController account = TextEditingController(text: o.bankAccount?.accountNumber);
  late final TextEditingController iban = TextEditingController(text: o.bankAccount?.iBanNumber);
  late final TextEditingController nationalId = TextEditingController(text: o.jsonData.nationalId);
  late final TextEditingController economicCode = TextEditingController(text: o.jsonData.economicCode);
  bool busy = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[title, phone, address, card, account, iban, nationalId, economicCode]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final bool ok = await appSend(
      UServices.organization.updateOrganization(
        p: UOrganizationUpdateParams(
          id: o.id,
          title: title.text.trim(),
          phoneNumber: phone.text.trim(),
          address: address.text.trim(),
          cardNumber: card.valueOrNull(),
          accountNumber: account.valueOrNull(),
          iBanNumber: iban.valueOrNull(),
          nationalId: nationalId.text.trim(),
          economicCode: economicCode.text.trim(),
        ),
      ),
    );
    if (ok) await AppWorkspace.refresh();
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.businessDetails).help("app.businessSettings.page", inline: true), actions: const <Widget>[UHelpActions("app.businessSettings.")]),
    body: Form(
      key: formKey,
      child: AppPageBody(
        maxWidth: AppResponsive.readableMaxWidth,
        children: <Widget>[
          AppSectionCard(
            title: U.s.business,
            icon: Icons.storefront_outlined,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: <Widget>[
                UTextField(controller: title, labelText: U.s.name, validator: UValidators.required<String>()),
                UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone),
                UTextField(controller: address, labelText: U.s.address, lines: 2),
              ],
            ),
          ).pOnly(bottom: 12),
          AppSectionCard(
            title: U.s.bankAccountForPayouts,
            icon: Icons.account_balance_outlined,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: <Widget>[
                UTextField(controller: iban, labelText: U.s.iban, validator: UValidators.iban(isRequired: false)),
                UTextField(controller: card, labelText: U.s.cardNumber, keyboardType: TextInputType.number),
                UTextField(controller: account, labelText: U.s.accountNumber, keyboardType: TextInputType.number),
              ],
            ),
          ).help("app.businessSettings.bank").pOnly(bottom: 12),
          AppSectionCard(
            title: U.s.taxDetails,
            icon: Icons.receipt_long_outlined,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: <Widget>[
                UTextField(controller: nationalId, labelText: U.s.nationalId, keyboardType: TextInputType.number),
                UTextField(controller: economicCode, labelText: U.s.economicCode, keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(height: 16),
          UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save),
        ],
      ),
    ),
  );
}
