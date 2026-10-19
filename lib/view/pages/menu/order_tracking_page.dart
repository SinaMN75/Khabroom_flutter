import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Where an order is: paid, accepted, being made, ready, delivered. Refreshes itself while the order is open.
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final URxState state = URxState();
  UMenuOrderResponse? order;
  Timer? timer;

  static const List<TagMenuOrder> steps = <TagMenuOrder>[TagMenuOrder.paid, TagMenuOrder.accepted, TagMenuOrder.preparing, TagMenuOrder.ready, TagMenuOrder.completed];

  bool get open => order != null && steps.take(4).contains(order!.status);

  @override
  void initState() {
    read();
    timer = Timer.periodic(const Duration(seconds: 12), (_) => open ? read(silent: true) : null);
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    state.dispose();
    super.dispose();
  }

  Future<void> read({bool silent = false}) async {
    if (!silent) state.loading();
    final UMenuOrderResponse? o = (await UServices.cafe.readOrders(p: UMenuOrderReadParams(ids: <String>[widget.orderId], pageSize: 1, pageNumber: 1))).$1?.result?.firstOrNull;
    if (!mounted) return;
    if (o == null) {
      if (!silent) state.error();
      return;
    }
    setState(() => order = o);
    state.loaded();
  }

  Future<void> _cancel() async {
    final bool sure = await UNavigator.confirmAsync(title: U.s.cancelOrder, message: U.s.theMoneyGoesBackToYourWallet, destructive: true);
    if (!sure) return;
    if (await appSend(UServices.cafe.cancelOrder(p: UIdParams(id: widget.orderId)))) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(order == null ? U.s.yourOrder : "${U.s.orderNo} ${order!.number.toString().toPersianNumber()}").help("app.order.page", inline: true)),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UMenuOrderResponse o = order!;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final bool stopped = o.status == TagMenuOrder.rejected || o.status == TagMenuOrder.cancelled;
        return AppPageBody(
          onRefresh: read,
          maxWidth: 640,
          children: <Widget>[
            AppCard(
              child: UColumn(
                children: <Widget>[
                  UIconBackground(stopped ? Icons.cancel_outlined : o.status == TagMenuOrder.ready ? Icons.notifications_active_outlined : Icons.local_cafe_outlined, color: stopped ? scheme.error : scheme.primary, size: 56),
                  const SizedBox(height: 10),
                  UTextHeadlineSmall(o.status.localizedTitle, textAlign: TextAlign.center),
                  UTextBodySmall(o.menuTitle ?? "", color: scheme.onSurfaceVariant),
                  if (o.jsonData.reason != null) UTextBodyMedium(o.jsonData.reason!, color: scheme.error, textAlign: TextAlign.center).pOnly(top: 6),
                  if (o.jsonData.refunded > 0) AppChip(label: "${U.s.returnedToYourWallet}: ${money(o.jsonData.refunded)}", tone: AppTone.positive).pOnly(top: 8),
                ],
              ),
            ).help("app.order.status"),
            const SizedBox(height: 14),
            if (!stopped)
              AppCard(
                child: URow(
                  children: <Widget>[
                    for (int i = 0; i < steps.length; i++)
                      UColumn(
                        expanded: 1,
                        children: <Widget>[
                          UContainer(
                            width: 28,
                            height: 28,
                            radius: 14,
                            alignment: Alignment.center,
                            color: steps.indexOf(o.status) >= i ? scheme.primary : scheme.surfaceContainer,
                            child: Icon(Icons.check_rounded, size: 16, color: steps.indexOf(o.status) >= i ? scheme.onPrimary : scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          UTextLabelSmall(steps[i].localizedTitle, textAlign: TextAlign.center, maxLines: 2),
                        ],
                      ),
                  ],
                ),
              ).pOnly(bottom: 14),
            AppSectionCard(
              title: U.s.yourOrder,
              icon: Icons.receipt_long_outlined,
              child: UColumn(
                children: <Widget>[
                  for (final UMenuOrderLine l in o.jsonData.lines) AppInfoRow(label: "${l.quantity.toString().toPersianNumber()}× ${l.title}${l.choices.isEmpty ? "" : " (${l.choices.join("، ")})"}", value: money(l.price * l.quantity)),
                  const Divider(),
                  AppInfoRow(label: o.type.localizedTitle, value: o.type == TagMenuOrder.table ? "${U.s.tableNumber} ${o.jsonData.table.toString().toPersianNumber()}" : o.jsonData.room ?? "-"),
                  AppInfoRow(label: U.s.total, value: money(o.total), emphasize: true),
                ],
              ),
            ),
            if (o.status == TagMenuOrder.paid || o.status == TagMenuOrder.pending)
              UButton(title: U.s.cancelOrder, type: UButtonType.outlined, foregroundColor: Theme.of(context).colorScheme.error, onTap: _cancel).pOnly(top: 16).help("app.order.cancel"),
          ],
        );
      },
    ),
  );
}
