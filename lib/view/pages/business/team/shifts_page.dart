import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Who works when this week, and whether they clocked in.
class ShiftsPage extends StatefulWidget {
  const ShiftsPage({super.key});

  @override
  State<ShiftsPage> createState() => _ShiftsPageState();
}

class _ShiftsPageState extends State<ShiftsPage> {
  final URxState state = URxState();
  List<UStaffShiftResponse> list = <UStaffShiftResponse>[];
  List<UUserResponse> people = <UUserResponse>[];
  DateTime from = DateTime.now().copyWith(hour: 0, minute: 0, second: 0);

  bool get canManage => AppWorkspace.can(TagUser.permissionManageStaff);

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
    final UResponse<List<UStaffShiftResponse>>? r = (await UServices.organization.readShifts(
      p: UStaffShiftReadParams(organizationId: AppWorkspace.org.id, userId: canManage ? null : U.user.id, fromDate: from, toDate: from.add(const Duration(days: 7)), pageSize: 300, pageNumber: 1),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = (r.result ?? <UStaffShiftResponse>[])..sort((UStaffShiftResponse a, UStaffShiftResponse b) => a.startAt.compareTo(b.startAt));
    if (people.isEmpty && canManage) {
      final UOrganizationResponse o = AppWorkspace.org;
      people = (await UServices.user.read(p: UUserReadParams(ids: <String>[o.ownerId, ...o.jsonData.members.map((UOrganizationMember m) => m.userId)], pageSize: 200, pageNumber: 1))).$1?.result ?? <UUserResponse>[];
    }
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _create() async {
    String? userId = people.firstOrNull?.id;
    String? placeId = AppWorkspace.myPlaces.firstOrNull?.id;
    DateTime? day = DateTime.now();
    final TextEditingController start = TextEditingController(text: "08:00");
    final TextEditingController end = TextEditingController(text: "16:00");
    DateTime at(DateTime d, String hhmm) {
      final List<String> p = hhmm.toLatinNumber().split(":");
      return DateTime(d.year, d.month, d.day, int.tryParse(p.first) ?? 0, p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
    }

    final bool ok = await AppForm.show(
      title: U.s.newShift,
      help: "app.shifts.form",
      onSubmit: () async {
        if (userId == null || day == null) return false;
        DateTime s = at(day!, start.text);
        DateTime e = at(day!, end.text);
        if (!e.isAfter(s)) e = e.add(const Duration(days: 1));
        s = s.toUtc();
        e = e.toUtc();
        return appSend(UServices.organization.createShift(p: UStaffShiftCreateParams(organizationId: AppWorkspace.org.id, userId: userId!, startAt: s, endAt: e, placeId: placeId)));
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<String?>(
          labelText: U.s.who,
          initialValue: userId,
          items: <DropdownMenuItem<String?>>[for (final UUserResponse u in people) DropdownMenuItem<String?>(value: u.id, child: Text("${u.firstName ?? ""} ${u.lastName ?? ""}"))],
          onChanged: (String? v) => setState(() => userId = v),
        ),
        UDropDownField<String?>(
          labelText: U.s.branch,
          initialValue: placeId,
          items: <DropdownMenuItem<String?>>[for (final AppPlace p in AppWorkspace.myPlaces) DropdownMenuItem<String?>(value: p.id, child: Text(p.title))],
          onChanged: (String? v) => setState(() => placeId = v),
        ),
        UTextFieldDatePicker(labelText: U.s.date, jalali: true, initialDate: day, onChange: (DateTime d, _) => day = d),
        URow(
          spacing: 10,
          children: <Widget>[
            Expanded(child: UTextField(controller: start, labelText: U.s.from)),
            Expanded(child: UTextField(controller: end, labelText: U.s.until)),
          ],
        ),
      ],
    );
    start.dispose();
    end.dispose();
    if (ok) await read();
  }

  String _time(DateTime d) {
    final DateTime l = d.toLocal();
    return "${l.hour.toString().padLeft(2, "0")}:${l.minute.toString().padLeft(2, "0")}".toPersianNumber();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(U.s.shifts).help("app.shifts.page", inline: true),
      actions: <Widget>[
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () {
          from = from.subtract(const Duration(days: 7));
          read();
        }),
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () {
          from = from.add(const Duration(days: 7));
          read();
        }),
        const UHelpActions("app.shifts."),
      ],
    ),
    floatingActionButton: canManage ? FloatingActionButton(onPressed: _create, child: const Icon(Icons.add_rounded)) : null,
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.noShiftsThisWeek,
      emptyIcon: Icons.schedule_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UStaffShiftResponse s in list)
                  AppTile(
                    icon: Icons.schedule_outlined,
                    title: s.userName ?? "-",
                    subtitle: "${s.startAt.toLocal().toJalaliDate().toPersianNumber()} · ${_time(s.startAt)} - ${_time(s.endAt)} · ${AppWorkspace.places.where((AppPlace p) => p.id == s.placeId).firstOrNull?.title ?? ""}",
                    trailing: AppChip(
                      label: s.checkedOutAt != null ? U.s.shiftDone : s.checkedInAt != null ? U.s.atWork : U.s.notYet,
                      tone: s.checkedOutAt != null ? AppTone.neutral : s.checkedInAt != null ? AppTone.positive : AppTone.warning,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
