import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/dorm/dorm_new_contract_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// People who asked to live in the dorm from the app. Approve, put on the waiting list or decline; an approved one becomes a resident in one tap.
class DormApplicationsPage extends StatefulWidget {
  const DormApplicationsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormApplicationsPage> createState() => _DormApplicationsPageState();
}

class _DormApplicationsPageState extends State<DormApplicationsPage> {
  final URxState state = URxState();
  List<UDormApplicationResponse> list = <UDormApplicationResponse>[];
  TagDormApplication tab = TagDormApplication.pending;

  static const List<TagDormApplication> tabs = <TagDormApplication>[TagDormApplication.pending, TagDormApplication.waitlisted, TagDormApplication.approved, TagDormApplication.rejected];

  bool get canReview => AppWorkspace.can(TagUser.permissionManageContracts, placeId: widget.dormId);

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
    final UResponse<List<UDormApplicationResponse>>? r = (await UServices.dorm.readApplications(p: UDormApplicationReadParams(dormId: widget.dormId, tags: <int>[tab.number], pageSize: 200, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UDormApplicationResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _review(UDormApplicationResponse a, TagDormApplication status) async {
    final TextEditingController note = TextEditingController();
    final bool ok = await AppForm.show(
      title: status.localizedTitle,
      help: "app.applications.review",
      submitTitle: status.localizedTitle,
      onSubmit: () => appSend(UServices.dorm.reviewApplication(p: UDormApplicationReviewParams(id: a.id, status: status.number, reviewNote: note.valueOrNull()))),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(controller: note, labelText: U.s.messageToTheApplicant, lines: 2)],
    );
    note.dispose();
    if (ok) await read();
  }

  Future<void> _sheet(UDormApplicationResponse a) => UNavigator.bottomSheet<void>(
    SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge(a.userName ?? U.s.applicant),
            AppInfoRow(label: U.s.phoneNumber, value: (a.phoneNumber ?? "-").toPersianNumber()),
            AppInfoRow(label: U.s.wantsToComeFrom, value: a.desiredStartDate.toJalaliDate().toPersianNumber()),
            if (a.desiredEndDate != null) AppInfoRow(label: U.s.until, value: a.desiredEndDate!.toJalaliDate().toPersianNumber()),
            if (a.detail1 != null) UTextBodyMedium(a.detail1!).pOnly(top: 6),
            for (final UDormApplicationDocument d in a.documents) AppTile(icon: Icons.description_outlined, title: d.title, dense: true, onTap: d.url == null ? null : () => ULaunch.url(d.url!)),
            const SizedBox(height: 10),
            if (canReview && a.tags.contains(TagDormApplication.approved.number) && a.contractId == null)
              UButton(title: U.s.makeResident, icon: const Icon(Icons.person_add_alt_1_outlined), onTap: () {
                UNavigator.back();
                UNavigator.push(DormNewContractPage(dormId: widget.dormId, userId: a.userId, applicationId: a.id, start: a.desiredStartDate)).then((_) => read());
              }),
            if (canReview && (a.tags.contains(TagDormApplication.pending.number) || a.tags.contains(TagDormApplication.waitlisted.number)))
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  UButton(title: TagDormApplication.approved.localizedTitle, onTap: () {
                    UNavigator.back();
                    _review(a, TagDormApplication.approved);
                  }),
                  if (!a.tags.contains(TagDormApplication.waitlisted.number))
                    UButton(title: TagDormApplication.waitlisted.localizedTitle, type: UButtonType.outlined, onTap: () {
                      UNavigator.back();
                      _review(a, TagDormApplication.waitlisted);
                    }),
                  UButton(title: TagDormApplication.rejected.localizedTitle, type: UButtonType.outlined, foregroundColor: Theme.of(context).colorScheme.error, onTap: () {
                    UNavigator.back();
                    _review(a, TagDormApplication.rejected);
                  }),
                ],
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.applications).help("app.applications.page", inline: true), actions: const <Widget>[UHelpActions("app.applications.")]),
    body: UColumn(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: <Widget>[
              for (final TagDormApplication t in tabs)
                ChoiceChip(label: Text(t.localizedTitle), selected: tab == t, onSelected: (_) {
                  setState(() => tab = t);
                  read();
                }).pOnly(left: 8),
            ],
          ),
        ),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            emptyTitle: U.s.noApplicationsHere,
            emptyIcon: Icons.how_to_reg_outlined,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: UColumn(
                    children: <Widget>[
                      for (final UDormApplicationResponse a in list)
                        AppTile(
                          icon: Icons.person_outline_rounded,
                          title: a.userName ?? U.s.applicant,
                          subtitle: "${U.s.from} ${a.desiredStartDate.toJalaliDate().toPersianNumber()}${a.waitlistPosition == null ? "" : " · ${U.s.positionInLine} ${a.waitlistPosition.toString().toPersianNumber()}"}",
                          onTap: () => _sheet(a),
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
