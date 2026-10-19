import "package:khabroom/main.dart";
import "package:khabroom/view/pages/menu/order_tracking_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Every café order the user placed.
class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final URxState state = URxState();
  List<UMenuOrderResponse> list = <UMenuOrderResponse>[];

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
    final UResponse<List<UMenuOrderResponse>>? r = (await UServices.cafe.readOrders(p: UMenuOrderReadParams(pageSize: 50, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = (r.result ?? <UMenuOrderResponse>[]).where((UMenuOrderResponse o) => o.status != TagMenuOrder.pending).toList();
    list.isEmpty ? state.emptying() : state.loaded();
  }

  static AppTone toneOf(TagMenuOrder s) => switch (s) {
    TagMenuOrder.completed => AppTone.neutral,
    TagMenuOrder.ready => AppTone.positive,
    TagMenuOrder.rejected || TagMenuOrder.cancelled => AppTone.danger,
    _ => AppTone.warning,
  };

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.myOrders).help("app.orders.page", inline: true)),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.youHaveNotOrderedAnythingYet,
      emptyIcon: Icons.local_cafe_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        maxWidth: 720,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UMenuOrderResponse o in list)
                  AppTile(
                    icon: Icons.local_cafe_outlined,
                    title: "${o.menuTitle ?? U.s.yourOrder} · ${o.number.toString().toPersianNumber()}",
                    subtitle: "${o.createdAt.toLocal().toJalaliDateTime().toPersianNumber()} · ${money(o.total)}",
                    trailing: AppChip(label: o.status.localizedTitle, tone: toneOf(o.status)),
                    onTap: () => UNavigator.push(OrderTrackingPage(orderId: o.id)).then((_) => read()),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
