import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// One staff member: who they are, what they may do for the whole business, and what they may do in each place.
class MemberPage extends StatefulWidget {
  const MemberPage({super.key, this.user});

  final UUserResponse? user;

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController phone = TextEditingController();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final Set<int> business = <int>{};
  final Map<String, Set<int>> places = <String, Set<int>>{};
  bool busy = false;

  @override
  void initState() {
    final UOrganizationMember? m = widget.user == null ? null : AppWorkspace.org.jsonData.members.where((UOrganizationMember x) => x.userId == widget.user!.id).firstOrNull;
    business.addAll(m?.permissions ?? <int>[]);
    for (final UOrganizationMemberPlace p in m?.places ?? <UOrganizationMemberPlace>[]) places[p.placeId] = p.permissions.toSet();
    super.initState();
  }

  @override
  void dispose() {
    phone.dispose();
    firstName.dispose();
    lastName.dispose();
    super.dispose();
  }

  String _label(TagUser p) => switch (p) {
    TagUser.permissionManageStaff => U.s.shiftsAndTasks,
    TagUser.permissionManageUsers => U.s.customersAndResidents,
    TagUser.permissionViewDashboard => U.s.seeTheNumbers,
    TagUser.permissionManageDorms || TagUser.permissionManageHotels => U.s.editRoomsAndDetails,
    TagUser.permissionManageContracts => U.s.contractsAndResidents,
    TagUser.permissionDeleteContracts => U.s.deleteContracts,
    TagUser.permissionManageInvoices => U.s.makeAndEditBills,
    TagUser.permissionDeleteInvoices => U.s.deleteBills,
    TagUser.permissionPayInvoices => U.s.receivePayments,
    TagUser.permissionManageReservations => U.s.bookingsAndCheckIn,
    TagUser.permissionDeleteReservations => U.s.deleteBookings,
    _ => p.localizedTitle,
  };

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final bool ok = await appSend(
      UServices.organization.setOrganizationMember(
        p: UOrganizationMemberParams(
          organizationId: AppWorkspace.org.id,
          userId: widget.user?.id,
          phoneNumber: widget.user == null ? phone.text.trim() : null,
          firstName: firstName.valueOrNull(),
          lastName: lastName.valueOrNull(),
          permissions: business.toList(),
          places: <UOrganizationMemberPlace>[for (final MapEntry<String, Set<int>> e in places.entries) if (e.value.isNotEmpty) UOrganizationMemberPlace(placeId: e.key, permissions: e.value.toList())],
        ),
      ),
    );
    if (ok) {
      await AppWorkspace.refresh();
      UNavigator.back(true);
      return;
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _remove() async {
    if (!await UNavigator.confirmAsync(title: U.s.removeFromTeam, message: U.s.theyWillNoLongerSeeThisBusiness, destructive: true)) return;
    if (await appSend(UServices.organization.removeOrganizationMember(p: UOrganizationMemberParams(organizationId: AppWorkspace.org.id, userId: widget.user!.id)))) {
      await AppWorkspace.refresh();
      UNavigator.back(true);
    }
  }

  Widget _chips(List<TagUser> options, Set<int> selected) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: <Widget>[
      for (final TagUser p in options) FilterChip(label: Text(_label(p)), selected: selected.contains(p.number), onSelected: (bool on) => setState(() => on ? selected.add(p.number) : selected.remove(p.number))),
    ],
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.user == null ? U.s.addStaff : "${widget.user!.firstName ?? ""} ${widget.user!.lastName ?? ""}").help("app.member.page", inline: true),
      actions: <Widget>[if (widget.user != null) IconButton(icon: const Icon(Icons.person_remove_outlined), onPressed: _remove), const UHelpActions("app.member.")],
    ),
    body: Form(
      key: formKey,
      child: AppPageBody(
        maxWidth: AppResponsive.readableMaxWidth,
        children: <Widget>[
          if (widget.user == null)
            AppSectionCard(
              title: U.s.whoIsIt,
              icon: Icons.person_outline_rounded,
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: <Widget>[
                  UTextField(controller: phone, labelText: U.s.phoneNumber, keyboardType: TextInputType.phone, validator: UValidators.iranianPhone()).help("app.member.phone"),
                  URow(
                    spacing: 10,
                    children: <Widget>[
                      Expanded(child: UTextField(controller: firstName, labelText: U.s.firstName)),
                      Expanded(child: UTextField(controller: lastName, labelText: U.s.lastName)),
                    ],
                  ),
                  UTextBodySmall(U.s.theySignInWithThisNumberAndSeeThisBusinessInTheirList, color: Theme.of(context).colorScheme.onSurfaceVariant, maxLines: 6),
                ],
              ),
            ).pOnly(bottom: 12),
          AppSectionCard(title: U.s.forTheWholeBusiness, icon: Icons.business_outlined, child: _chips(TagUser.organizationPermissions, business)).help("app.member.business").pOnly(bottom: 12),
          for (final AppPlace p in AppWorkspace.places)
            Theme(
              data: p.kind.theme(context),
              child: AppSectionCard(title: p.title, icon: p.kind.icon, child: _chips(p.kind.permissions, places.putIfAbsent(p.id, () => <int>{}))),
            ).pOnly(bottom: 12),
          if (AppWorkspace.places.isNotEmpty) UTextBodySmall(U.s.leaveAPlaceEmptyAndTheyWillNotSeeIt, color: Theme.of(context).colorScheme.onSurfaceVariant, textAlign: TextAlign.center, maxLines: 6),
          const SizedBox(height: 16),
          UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save),
        ],
      ),
    ),
  );
}
