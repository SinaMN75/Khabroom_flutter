import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The business's own list of guests and residents: regulars, VIPs and people it does not accept again.
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  static bool get allowed => AppWorkspace.can(TagUser.permissionManageUsers) || AppWorkspace.can(TagUser.permissionManageStaff);

  /// Marks one person (from a booking or a contract) as regular, VIP or blacklisted.
  static Future<bool> mark({required String userId, required String name, UOrganizationCustomerResponse? current}) async {
    final List<int> tags = List<int>.from(current?.tags ?? <int>[TagOrganizationCustomer.regular.number]);
    final TextEditingController note = TextEditingController(text: current?.note);
    final bool ok = await AppForm.show(
      title: name,
      help: "app.customers.form",
      onSubmit: () => appSend(UServices.organization.setCustomer(p: UOrganizationCustomerSetParams(organizationId: AppWorkspace.org.id, userId: userId, tags: tags, note: note.valueOrNull()))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTagChips<TagOrganizationCustomer>(title: U.s.status, options: TagOrganizationCustomer.values, tags: tags, single: true),
        UTextField(controller: note, labelText: U.s.note, lines: 3),
      ],
    );
    note.dispose();
    return ok;
  }

  /// Finds this person's current entry, then opens [mark].
  static Future<bool> markUser(String userId, String name) async {
    ULoading.show();
    final UOrganizationCustomerResponse? current = (await UServices.organization.readCustomers(p: UOrganizationCustomerReadParams(organizationId: AppWorkspace.org.id, userId: userId, pageSize: 1, pageNumber: 1))).$1?.result?.firstOrNull;
    ULoading.dismiss();
    return mark(userId: userId, name: name, current: current);
  }

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final URxState state = URxState();
  List<UOrganizationCustomerResponse> list = <UOrganizationCustomerResponse>[];
  TagOrganizationCustomer? filter;

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
    final UResponse<List<UOrganizationCustomerResponse>>? r = (await UServices.organization.readCustomers(
      p: UOrganizationCustomerReadParams(organizationId: AppWorkspace.org.id, tags: filter == null ? null : <int>[filter!.number], pageSize: 200, pageNumber: 1),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UOrganizationCustomerResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _add() async {
    final TextEditingController phone = TextEditingController();
    UUserResponse? found;
    final bool picked = await AppForm.show(
      title: U.s.addCustomer,
      submitTitle: U.s.next,
      onSubmit: () async {
        final String q = phone.text.trim().toLatinNumber();
        found = (await UServices.user.read(p: UUserReadParams(phoneNumber: q, pageSize: 1, pageNumber: 1))).$1?.result?.firstOrNull;
        if (found == null) UToast.error(message: U.s.noAccountWithThisPhoneNumber);
        return found != null;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextBodySmall(U.s.customersAreFoundByTheirPhoneNumberTheyNeedAnAccountInTheApp, color: Theme.of(context).colorScheme.onSurfaceVariant, maxLines: 6),
        UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, validator: UValidators.iranianPhone()),
      ],
    );
    phone.dispose();
    if (!picked || found == null) return;
    final String name = "${found!.firstName ?? ""} ${found!.lastName ?? ""}".trim();
    if (await CustomersPage.markUser(found!.id, name.isEmpty ? (found!.phoneNumber ?? "") : name)) await read();
  }

  AppTone _tone(UOrganizationCustomerResponse c) => c.tags.contains(TagOrganizationCustomer.blacklisted.number)
      ? AppTone.danger
      : c.tags.contains(TagOrganizationCustomer.vip.number)
      ? AppTone.warning
      : AppTone.neutral;

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.customers).help("app.customers.page", inline: true), actions: const <Widget>[UHelpActions("app.customers.")]),
    floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt_outlined), label: Text(U.s.addCustomer)),
    body: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(
              label: Text(U.s.all),
              selected: filter == null,
              onSelected: (_) {
                filter = null;
                read();
              },
            ),
            for (final TagOrganizationCustomer t in TagOrganizationCustomer.values)
              ChoiceChip(
                label: Text(t.localizedTitle),
                selected: filter == t,
                onSelected: (_) {
                  filter = t;
                  read();
                },
              ),
          ],
        ).pSymmetric(horizontal: 16, vertical: 8).help("app.customers.filter"),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.noCustomersYetMarkGuestsFromTheirBookingOrContract,
            emptyIcon: Icons.people_outline_rounded,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UOrganizationCustomerResponse c in list)
                        AppTile(
                          icon: Icons.person_outline_rounded,
                          iconColor: _tone(c).foreground(context),
                          title: (c.userName ?? "").trim().isEmpty ? (c.phoneNumber ?? "-").toPersianNumber() : c.userName!,
                          subtitle: <String>[?c.phoneNumber?.toPersianNumber(), ?c.note].join(" · "),
                          trailing: URow(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              for (final TagOrganizationCustomer t in TagOrganizationCustomer.values.where((TagOrganizationCustomer t) => c.tags.contains(t.number))) AppChip(label: t.localizedTitle, tone: _tone(c)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                tooltip: U.s.delete,
                                onPressed: () async {
                                  if (await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.organization.deleteCustomer(p: UIdParams(id: c.id)))) await read();
                                },
                              ),
                            ],
                          ),
                          onTap: () async {
                            if (await CustomersPage.mark(userId: c.userId, name: c.userName ?? "", current: c)) await read();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
