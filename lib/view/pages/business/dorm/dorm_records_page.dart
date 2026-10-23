import "package:khabroom/utils/app_people.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The dorm's notebook: visitors, nights away, notices for everyone, warnings and inspections.
class DormRecordsPage extends StatefulWidget {
  const DormRecordsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormRecordsPage> createState() => _DormRecordsPageState();
}

class _DormRecordsPageState extends State<DormRecordsPage> {
  final URxState state = URxState();
  List<UDormRecordResponse> list = <UDormRecordResponse>[];
  TagDormRecord? filter;

  static const List<TagDormRecord> kinds = <TagDormRecord>[
    TagDormRecord.visitor,
    TagDormRecord.nightLeave,
    TagDormRecord.announcement,
    TagDormRecord.warning,
    TagDormRecord.violation,
    TagDormRecord.inspection,
  ];

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
    final UResponse<List<UDormRecordResponse>>? r = (await UServices.dorm.readRecords(p: UDormRecordReadParams(dormId: widget.dormId, tags: filter == null ? null : <int>[filter!.number], pageSize: 200, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UDormRecordResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  static IconData iconOf(List<int> tags) {
    if (tags.contains(TagDormRecord.visitor.number)) return Icons.badge_outlined;
    if (tags.contains(TagDormRecord.nightLeave.number)) return Icons.nights_stay_outlined;
    if (tags.contains(TagDormRecord.announcement.number)) return Icons.campaign_outlined;
    if (tags.contains(TagDormRecord.inspection.number)) return Icons.fact_check_outlined;
    return Icons.report_gmailerrorred_outlined;
  }

  Future<void> _create() async {
    TagDormRecord kind = TagDormRecord.visitor;
    final TextEditingController title = TextEditingController();
    final TextEditingController body = TextEditingController();
    final TextEditingController residentPhone = TextEditingController();
    final TextEditingController visitorName = TextEditingController();
    final TextEditingController visitorPhone = TextEditingController();
    DateTime? date = DateTime.now();
    DateTime? endDate;
    final bool ok = await AppForm.show(
      title: U.s.newRecord,
      help: "app.records.form",
      onSubmit: () async {
        final String? userId = residentPhone.text.trim().isEmpty ? null : (await AppPeople.find(residentPhone.text))?.id;
        if (residentPhone.text.trim().isNotEmpty && userId == null) {
          UToast.error(message: U.s.noOneWithThisNumberLivesHere);
          return false;
        }
        return appSend(
          UServices.dorm.createRecord(
            p: UDormRecordCreateParams(
              dormId: widget.dormId,
              title: title.text.trim().isEmpty ? kind.localizedTitle : title.text.trim(),
              tags: <int>[kind.number],
              date: date,
              endDate: endDate,
              userId: userId,
              body: body.valueOrNull(),
              visitorName: visitorName.valueOrNull(),
              visitorPhone: visitorPhone.valueOrNull(),
            ),
          ),
        );
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(spacing: 8, runSpacing: 8, children: <Widget>[for (final TagDormRecord k in kinds) ChoiceChip(label: Text(k.localizedTitle), selected: kind == k, onSelected: (_) => setState(() => kind = k))]),
        UTextField(controller: title, labelText: U.s.title),
        if (kind != TagDormRecord.announcement) UTextField(controller: residentPhone, labelText: U.s.residentsPhoneNumber, keyboardType: TextInputType.phone).help("app.records.resident"),
        if (kind == TagDormRecord.visitor) ...<Widget>[
          UTextField(controller: visitorName, labelText: U.s.visitorName),
          UTextField(controller: visitorPhone, labelText: U.s.visitorPhone, keyboardType: TextInputType.phone),
        ],
        UTextFieldDatePicker(labelText: U.s.date, jalali: true, initialDate: date, onChange: (DateTime d, _) => date = d),
        if (kind == TagDormRecord.nightLeave) UTextFieldDatePicker(labelText: U.s.backOn, jalali: true, onChange: (DateTime d, _) => endDate = d),
        UTextField(controller: body, labelText: U.s.details, lines: 3),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, body, residentPhone, visitorName, visitorPhone]) c.dispose();
    if (ok) await read();
  }

  Future<void> _open(UDormRecordResponse r) async {
    final bool pending = r.tags.contains(TagDormRecord.pending.number);
    final int? action = await UNavigator.bottomSheet<int>(
      SafeArea(
        child: UColumn(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge(r.title).pAll(12),
            if (r.body != null) UTextBodySmall(r.body!).pSymmetric(horizontal: 12),
            if (pending) ...<Widget>[
              AppTile(icon: Icons.check_circle_outline_rounded, iconColor: AppTone.positive.foreground(context), title: U.s.approve, onTap: () => UNavigator.back(1)),
              AppTile(icon: Icons.cancel_outlined, iconColor: AppTone.danger.foreground(context), title: U.s.reject, onTap: () => UNavigator.back(2)),
            ],
            AppTile(icon: Icons.delete_outline_rounded, iconColor: Theme.of(context).colorScheme.error, title: U.s.delete, onTap: () => UNavigator.back(3)),
          ],
        ).pSymmetric(horizontal: 12),
      ),
    );
    final bool ok = switch (action) {
      1 => await appSend(UServices.dorm.updateRecord(p: UDormRecordUpdateParams(id: r.id, tags: <int>[TagDormRecord.approved.number]))),
      2 => await appSend(UServices.dorm.updateRecord(p: UDormRecordUpdateParams(id: r.id, tags: <int>[TagDormRecord.rejected.number]))),
      3 => await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.dorm.deleteRecord(p: UIdParams(id: r.id))),
      _ => false,
    };
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.records).help("app.records.page", inline: true), actions: const <Widget>[UHelpActions("app.records.")]),
    floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add_rounded)),
    body: UColumn(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              ChoiceChip(label: Text(U.s.all), selected: filter == null, onSelected: (_) {
                setState(() => filter = null);
                read();
              }).pOnly(left: 8),
              for (final TagDormRecord k in kinds)
                ChoiceChip(label: Text(k.localizedTitle), selected: filter == k, onSelected: (_) {
                  setState(() => filter = k);
                  read();
                }).pOnly(left: 8),
            ],
          ),
        ),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.nothingRecordedYet,
            emptyIcon: Icons.fact_check_outlined,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UDormRecordResponse r in list)
                        AppTile(
                          icon: iconOf(r.tags),
                          title: r.title,
                          subtitle: <String>[?r.userName, ?r.visitorName, r.date.toJalaliDate().toPersianNumber(), ?r.body].join(" · "),
                          trailing: r.tags.contains(TagDormRecord.pending.number)
                              ? AppChip(label: TagDormRecord.pending.localizedTitle, tone: AppTone.warning)
                              : r.tags.contains(TagDormRecord.approved.number)
                              ? AppChip(label: TagDormRecord.approved.localizedTitle, tone: AppTone.positive)
                              : r.tags.contains(TagDormRecord.rejected.number)
                              ? AppChip(label: TagDormRecord.rejected.localizedTitle, tone: AppTone.danger)
                              : null,
                          onTap: () => _open(r),
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
