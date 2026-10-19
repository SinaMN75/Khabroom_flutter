import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Who changed what, and when, across the business.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final URxState state = URxState();
  List<UActivityLogResponse> list = <UActivityLogResponse>[];

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
    final UResponse<List<UActivityLogResponse>>? r = (await UServices.organization.readActivityLogs(p: UActivityLogReadParams(organizationId: AppWorkspace.org.id, pageSize: 100, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UActivityLogResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  static String action(String path) {
    final String p = path.toLowerCase();
    if (p.contains("delete")) return U.s.deleted;
    if (p.contains("create") || p.contains("book")) return U.s.created;
    if (p.contains("receive") || p.contains("pay")) return U.s.recordedAPayment;
    if (p.contains("settle")) return U.s.checkedSomeoneOut;
    return U.s.changed;
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.activity).help("app.activity.page", inline: true)),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.nothingHappenedYet,
      emptyIcon: Icons.history_rounded,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UActivityLogResponse a in list)
                  AppTile(
                    dense: true,
                    icon: Icons.history_rounded,
                    title: "${a.userName ?? "-"} · ${action(a.path)}",
                    subtitle: "${a.path.split("/").where((String s) => s.isNotEmpty).take(2).join(" › ")} · ${a.createdAt.toLocal().toJalaliDateTime().toPersianNumber()}",
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
