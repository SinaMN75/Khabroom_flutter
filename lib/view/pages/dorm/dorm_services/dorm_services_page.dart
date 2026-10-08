import "package:khabroom/main.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/dorm/dorm_services/dorm_services_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class DormServicesPage extends StatefulWidget {
  const DormServicesPage({required this.contract, super.key});

  final UDormBedContractResponse contract;

  @override
  State<DormServicesPage> createState() => _DormServicesPageState();
}

class _DormServicesPageState extends State<DormServicesPage> {
  final DormServicesController c = DormServicesController();

  @override
  void initState() {
    c.init(widget.contract);
    super.initState();
  }

  String _tabTitle(DormServicesTab t) => switch (t) {
    DormServicesTab.notices => U.s.noticesAndRequests,
    DormServicesTab.meals => U.s.mealMenu,
    DormServicesTab.laundry => TagDormBooking.laundry.localizedTitle,
    DormServicesTab.maintenance => TagStaffTask.maintenance.localizedTitle,
  };

  String _tags<T extends UNumericIdentifiable>(List<T> values, List<int> tags) => values.where((T t) => tags.contains(t.number)).map((T t) => t.localizedTitle).join("، ");

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text("${U.s.dormServices} · ${widget.contract.bed?.room?.dorm?.title ?? ""}")),
    floatingActionButton: switch (c.tab) {
      DormServicesTab.notices => FloatingActionButton.extended(onPressed: _requestSheet, icon: const Icon(Icons.add), label: Text(U.s.newRequest)),
      DormServicesTab.laundry => FloatingActionButton.extended(onPressed: _laundrySheet, icon: const Icon(Icons.add), label: Text(U.s.booking)),
      DormServicesTab.maintenance => FloatingActionButton.extended(onPressed: _maintenanceSheet, icon: const Icon(Icons.build_outlined), label: Text(U.s.newRequest)),
      _ => null,
    },
    body: RefreshIndicator(
      onRefresh: c.read,
      child: ListView(
        padding: AppResponsive.pagePadding(context),
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DormServicesTab.values
                .map((DormServicesTab t) => ChoiceChip(label: Text(_tabTitle(t)), selected: c.tab == t, onSelected: (_) => c.setTab(t).then((_) => setState(() {}))))
                .toList(),
          ).pOnly(bottom: 12),
          AppStateView(
            state: c.listState,
            onRetry: c.read,
            emptyTitle: U.s.noItemsFound(_tabTitle(c.tab)),
            onLoaded: (BuildContext context) => UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: switch (c.tab) {
                DormServicesTab.notices => c.records.map(_record).toList(),
                DormServicesTab.meals => c.meals.map(_meal).toList(),
                DormServicesTab.laundry => c.laundry.map(_laundry).toList(),
                DormServicesTab.maintenance => c.tasks.map(_task).toList(),
              },
            ),
          ),
        ],
      ),
    ),
  );

  Widget _record(UDormRecordResponse r) => AppCard(
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          children: <Widget>[
            UTextTitleSmall(r.title, expanded: 1),
            AppChip(label: _tags(TagDormRecord.values, r.tags)),
          ],
        ),
        UTextBodySmall(r.endDate == null ? r.date.toJalaliDateTime() : "${r.date.toJalaliDate()} — ${r.endDate!.toJalaliDate()}").pOnly(top: 6),
        if ((r.body ?? "").isNotEmpty) UTextBodyMedium(r.body!).pOnly(top: 6),
      ],
    ),
  ).pOnly(bottom: 10);

  Widget _meal(UDormMealResponse m) {
    final String? booking = c.mealBookings[m.id];
    final bool full = m.capacity != null && m.reservedCount >= m.capacity!;
    return AppCard(
      child: URow(
        children: <Widget>[
          UColumn(
            expanded: 1,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UTextTitleSmall("${_tags(TagDormMeal.values, m.tags)} · ${m.title}"),
              UTextBodySmall("${m.date.toJalaliDateTime()} · ${money(m.price)}").pOnly(top: 4),
            ],
          ),
          if (booking != null)
            UButton(title: U.s.cancel, type: UButtonType.outlined, onTap: () => c.cancelBooking(booking).then((_) => setState(() {})))
          else
            UButton(title: full ? U.s.capacityIsFull : U.s.reserve, onTap: full ? null : () => c.reserveMeal(m).then((_) => setState(() {}))),
        ],
      ),
    ).pOnly(bottom: 10);
  }

  Widget _laundry(UDormBookingResponse b) => AppCard(
    child: URow(
      children: <Widget>[
        UColumn(
          expanded: 1,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            UTextTitleSmall(b.resource ?? TagDormBooking.laundry.localizedTitle),
            UTextBodySmall("${b.startAt.toJalaliDateTime()} — ${b.endAt?.toJalaliDateTime() ?? ""}").pOnly(top: 4),
          ],
        ),
        if (b.tags.contains(TagDormBooking.reserved.number) && b.startAt.isAfter(DateTime.now()))
          UButton(title: U.s.cancel, type: UButtonType.outlined, onTap: () => c.cancelBooking(b.id).then((_) => setState(() {})))
        else
          AppChip(label: _tags(<TagDormBooking>[TagDormBooking.reserved, TagDormBooking.cancelled, TagDormBooking.used], b.tags)),
      ],
    ),
  ).pOnly(bottom: 10);

  Widget _task(UStaffTaskResponse t) => AppCard(
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        URow(
          children: <Widget>[
            UTextTitleSmall(t.title, expanded: 1),
            AppChip(label: _tags(TagStaffTask.statuses, t.tags)),
          ],
        ),
        UTextBodySmall(t.createdAt.toJalaliDateTime()).pOnly(top: 4),
        if ((t.description ?? "").isNotEmpty) UTextBodyMedium(t.description!).pOnly(top: 6),
        if ((t.doneNote ?? "").isNotEmpty) UTextBodySmall(t.doneNote!).pOnly(top: 6),
      ],
    ),
  ).pOnly(bottom: 10);

  Future<void> _requestSheet() async {
    TagDormRecord kind = TagDormRecord.nightLeave;
    DateTime? from = DateTime.now();
    DateTime? to;
    final TextEditingController fromC = TextEditingController(text: from.toJalaliDate());
    final TextEditingController toC = TextEditingController();
    final TextEditingController visitor = TextEditingController();
    final TextEditingController note = TextEditingController();
    await UFormDialog.show(
      title: U.s.newRequest,
      onSubmit: () async {
        await c.request(kind, kind.localizedTitle, from, to, visitor.text.trim().nullIfEmpty(), note.text.trim().nullIfEmpty());
        setState(() {});
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(
          spacing: 8,
          children: <TagDormRecord>[TagDormRecord.nightLeave, TagDormRecord.visitor]
              .map((TagDormRecord k) => ChoiceChip(label: Text(k.localizedTitle), selected: kind == k, onSelected: (_) => setState(() => kind = k)))
              .toList(),
        ),
        UTextFieldDatePicker(controller: fromC, labelText: U.s.date, jalali: true, initialDate: from, onChange: (DateTime d, UJalali j) {
          from = d;
          fromC.text = d.toJalaliDate();
        }).pSymmetric(vertical: 6),
        if (kind == TagDormRecord.nightLeave)
          UTextFieldDatePicker(controller: toC, labelText: U.s.returnDate, jalali: true, initialDate: to, onChange: (DateTime d, UJalali j) {
            to = d;
            toC.text = d.toJalaliDate();
          }).pSymmetric(vertical: 6),
        if (kind == TagDormRecord.visitor) UTextField(controller: visitor, labelText: U.s.visitorName).pSymmetric(vertical: 6),
        UTextField(controller: note, labelText: U.s.description, lines: 2).pSymmetric(vertical: 6),
      ],
    );
  }

  Future<void> _laundrySheet() async {
    String? machine = c.machines.firstOrNull;
    DateTime? day = DateTime.now();
    final TextEditingController dayC = TextEditingController(text: day.toJalaliDate());
    final TextEditingController time = TextEditingController(text: "${(DateTime.now().hour + 1) % 24}:00");
    await UFormDialog.show(
      title: TagDormBooking.laundry.localizedTitle,
      onSubmit: () async {
        final List<int> parts = time.text.trim().toLatinNumber().split(":").map((String x) => int.tryParse(x) ?? 0).toList();
        final DateTime at = DateTime(day!.year, day!.month, day!.day, parts.firstOrNull ?? 0, parts.length > 1 ? parts[1] : 0);
        await c.bookLaundry(machine, at);
        setState(() {});
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        if (c.machines.isNotEmpty)
          Wrap(
            spacing: 8,
            children: c.machines.map((String m) => ChoiceChip(label: Text(m), selected: machine == m, onSelected: (_) => setState(() => machine = m))).toList(),
          ),
        UTextFieldDatePicker(controller: dayC, labelText: U.s.date, jalali: true, initialDate: day, onChange: (DateTime d, UJalali j) {
          day = d;
          dayC.text = d.toJalaliDate();
        }).pSymmetric(vertical: 6),
        UTextField(controller: time, labelText: U.s.time).pSymmetric(vertical: 6),
      ],
    );
  }

  Future<void> _maintenanceSheet() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController description = TextEditingController();
    bool urgent = false;
    await UFormDialog.show(
      title: U.s.maintenanceRequest,
      onSubmit: () async {
        if (title.text.trim().isEmpty) return false;
        await c.maintenance(title.text.trim(), description.text.trim().nullIfEmpty(), urgent);
        setState(() {});
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.title).pSymmetric(vertical: 6),
        UTextField(controller: description, labelText: U.s.description, lines: 3).pSymmetric(vertical: 6),
        SwitchListTile(value: urgent, title: Text(TagStaffTask.urgent.localizedTitle), onChanged: (bool v) => setState(() => urgent = v)),
      ],
    );
  }
}
