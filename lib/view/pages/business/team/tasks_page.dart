import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Things to do: repairs, cleaning, anything. Give it to someone, they mark it done.
class TasksPage extends StatefulWidget {
  const TasksPage({super.key, this.mine = false});

  final bool mine;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final URxState state = URxState();
  List<UStaffTaskResponse> list = <UStaffTaskResponse>[];
  List<UUserResponse> people = <UUserResponse>[];
  bool done = false;

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
    final UResponse<List<UStaffTaskResponse>>? r = (await UServices.organization.readTasks(
      p: UStaffTaskReadParams(organizationId: AppWorkspace.org.id, mine: widget.mine || !canManage, tags: <int>[done ? TagStaffTask.done.number : TagStaffTask.open.number], pageSize: 200, pageNumber: 1),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UStaffTaskResponse>[];
    if (people.isEmpty && canManage) {
      final UOrganizationResponse o = AppWorkspace.org;
      people = (await UServices.user.read(p: UUserReadParams(ids: <String>[o.ownerId, ...o.jsonData.members.map((UOrganizationMember m) => m.userId)], pageSize: 200, pageNumber: 1))).$1?.result ?? <UUserResponse>[];
    }
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _create() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController location = TextEditingController();
    final TextEditingController description = TextEditingController();
    String? assignee;
    String? placeId = AppWorkspace.myPlaces.firstOrNull?.id;
    TagStaffTask kind = TagStaffTask.maintenance;
    TagStaffTask priority = TagStaffTask.normal;
    DateTime? due;
    final bool ok = await AppForm.show(
      title: U.s.newTask,
      help: "app.tasks.form",
      onSubmit: () => appSend(
        UServices.organization.createTask(
          p: UStaffTaskCreateParams(
            title: title.text.trim(),
            organizationId: AppWorkspace.org.id,
            tags: <int>[kind.number, TagStaffTask.open.number, priority.number],
            placeId: placeId,
            assigneeId: assignee,
            dueDate: due,
            location: location.valueOrNull(),
            description: description.valueOrNull(),
          ),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(spacing: 8, children: <Widget>[for (final TagStaffTask t in <TagStaffTask>[TagStaffTask.maintenance, TagStaffTask.cleaning, TagStaffTask.task]) ChoiceChip(label: Text(t.localizedTitle), selected: kind == t, onSelected: (_) => setState(() => kind = t))]),
        UTextField(controller: title, labelText: U.s.whatNeedsDoing, validator: UValidators.required<String>()),
        UDropDownField<String?>(
          labelText: U.s.branch,
          initialValue: placeId,
          items: <DropdownMenuItem<String?>>[for (final AppPlace p in AppWorkspace.myPlaces) DropdownMenuItem<String?>(value: p.id, child: Text(p.title))],
          onChanged: (String? v) => setState(() => placeId = v),
        ),
        UTextField(controller: location, labelText: U.s.where, hintText: U.s.forExampleRoom204Bathroom),
        if (people.isNotEmpty)
          UDropDownField<String?>(
            labelText: U.s.giveItTo,
            initialValue: assignee,
            items: <DropdownMenuItem<String?>>[DropdownMenuItem<String?>(child: Text(U.s.nobodyYet)), for (final UUserResponse u in people) DropdownMenuItem<String?>(value: u.id, child: Text("${u.firstName ?? ""} ${u.lastName ?? ""}"))],
            onChanged: (String? v) => setState(() => assignee = v),
          ),
        Wrap(spacing: 8, children: <Widget>[for (final TagStaffTask t in <TagStaffTask>[TagStaffTask.low, TagStaffTask.normal, TagStaffTask.urgent]) ChoiceChip(label: Text(t.localizedTitle), selected: priority == t, onSelected: (_) => setState(() => priority = t))]),
        UTextFieldDatePicker(labelText: U.s.dueDate, jalali: true, onChange: (DateTime d, _) => due = d),
        UTextField(controller: description, labelText: U.s.details, lines: 2),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, location, description]) c.dispose();
    if (ok) await read();
  }

  Future<void> _done(UStaffTaskResponse t) async {
    final TextEditingController note = TextEditingController();
    final TextEditingController cost = TextEditingController();
    final bool ok = await AppForm.show(
      title: "${U.s.done} · ${t.title}",
      submitTitle: U.s.markAsDone,
      onSubmit: () => appSend(
        UServices.organization.updateTask(
          p: UStaffTaskUpdateParams(id: t.id, tags: <int>[...t.tags.where((int x) => x < 200 || x > 300), TagStaffTask.done.number], doneNote: note.valueOrNull(), cost: cost.text.isEmpty ? null : tomanToRial(cost)),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(controller: note, labelText: U.s.whatWasDone), AppMoneyField(controller: cost, label: U.s.costIfAny, required: false)],
    );
    note.dispose();
    cost.dispose();
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(widget.mine ? U.s.myTasks : U.s.tasks).help("app.tasks.page", inline: true), actions: const <Widget>[UHelpActions("app.tasks.")]),
    floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add_rounded)),
    body: UColumn(
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            ChoiceChip(label: Text(U.s.toDo), selected: !done, onSelected: (_) {
              setState(() => done = false);
              read();
            }),
            ChoiceChip(label: Text(U.s.done), selected: done, onSelected: (_) {
              setState(() => done = true);
              read();
            }),
          ],
        ).pSymmetric(horizontal: 16, vertical: 10),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: done ? U.s.nothingDoneYet : U.s.nothingToDo,
            emptyIcon: Icons.task_alt_rounded,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UStaffTaskResponse t in list)
                        AppTile(
                          icon: t.tags.contains(TagStaffTask.cleaning.number) ? Icons.cleaning_services_outlined : t.tags.contains(TagStaffTask.maintenance.number) ? Icons.build_outlined : Icons.task_alt_rounded,
                          iconColor: t.tags.contains(TagStaffTask.urgent.number) ? Theme.of(context).colorScheme.error : null,
                          title: t.title,
                          subtitle: <String>[?t.location, ?t.assigneeName, if (t.dueDate != null) t.dueDate!.toJalaliDate().toPersianNumber(), ?t.doneNote].join(" · "),
                          trailing: done ? null : IconButton(icon: const Icon(Icons.check_circle_outline_rounded), tooltip: U.s.markAsDone, onPressed: () => _done(t)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
