import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/cafe/cafe_look_page.dart";
import "package:khabroom/view/pages/business/cafe/cafe_menu_page.dart";
import "package:khabroom/view/pages/business/cafe/cafe_tables_page.dart";
import "package:khabroom/view/pages/business/places/place_form.dart";
import "package:khabroom/view/pages/business/places/place_photos_page.dart";
import "package:khabroom/view/pages/business/shared/reviews_page.dart";
import "package:khabroom/view/pages/menu/public_menu_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// The café counter: new orders appear by themselves; move each one along until it is delivered.
class CafeHomePage extends StatefulWidget {
  const CafeHomePage({required this.place, super.key});

  final AppPlace place;

  @override
  State<CafeHomePage> createState() => _CafeHomePageState();
}

class _CafeHomePageState extends State<CafeHomePage> {
  final URxState state = URxState();
  List<UMenuOrderResponse> orders = <UMenuOrderResponse>[];
  UMenuResponse? menu;
  Timer? timer;
  int lastNew = 0;

  static const List<TagMenuOrder> open = <TagMenuOrder>[TagMenuOrder.paid, TagMenuOrder.accepted, TagMenuOrder.preparing, TagMenuOrder.ready];

  bool get canOrders => AppWorkspace.can(TagUser.permissionManageOrders, placeId: widget.place.id);

  @override
  void initState() {
    read();
    timer = Timer.periodic(const Duration(seconds: 15), (_) => read(silent: true));
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
    final String? menuId = widget.place.menuId;
    if (menuId != null && menu == null) menu = (await UServices.cafe.openMenu(p: UMenuOpenParams(id: menuId, manage: true))).$1?.result;
    if (canOrders) {
      final DateTime today = DateTime.now().copyWith(hour: 0, minute: 0);
      orders = (await UServices.cafe.readOrders(
        p: UMenuOrderReadParams(manage: true, placeId: widget.place.id, fromDate: today.subtract(const Duration(hours: 6)), tags: open.map((TagMenuOrder t) => t.number).toList(), pageSize: 200, pageNumber: 1),
      )).$1?.result ?? orders;
      final int newCount = orders.where((UMenuOrderResponse o) => o.status == TagMenuOrder.paid).length;
      if (silent && newCount > lastNew) UToast.snackBar(message: U.s.youHaveANewOrder);
      lastNew = newCount;
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _move(UMenuOrderResponse o, TagMenuOrder to, {String? reason}) async {
    if (await appSend(UServices.cafe.setOrderStatus(p: UMenuOrderStatusParams(id: o.id, status: to.number, reason: reason)), toast: false)) await read(silent: true);
  }

  Future<void> _reject(UMenuOrderResponse o) async {
    final TextEditingController reason = TextEditingController();
    await AppForm.show(
      title: U.s.rejectAndRefund,
      help: "app.cafe.reject",
      submitTitle: U.s.rejectAndRefund,
      onSubmit: () async {
        await _move(o, TagMenuOrder.rejected, reason: reason.valueOrNull());
        return true;
      },
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextBodySmall(U.s.theMoneyGoesBackToTheCustomersWallet),
        UTextField(controller: reason, labelText: U.s.reasonTheCustomerSeesIt),
      ],
    );
    reason.dispose();
  }

  static TagMenuOrder? next(TagMenuOrder s) => switch (s) {
    TagMenuOrder.paid => TagMenuOrder.accepted,
    TagMenuOrder.accepted => TagMenuOrder.preparing,
    TagMenuOrder.preparing => TagMenuOrder.ready,
    TagMenuOrder.ready => TagMenuOrder.completed,
    _ => null,
  };

  String _where(UMenuOrderResponse o) => switch (o.type) {
    TagMenuOrder.table => "${U.s.tableNumber} ${o.jsonData.table.toString().toPersianNumber()}",
    TagMenuOrder.room => "${U.s.room} ${o.jsonData.room ?? ""}",
    _ => U.s.takeaway,
  };

  Widget _order(BuildContext context, UMenuOrderResponse o) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TagMenuOrder? n = next(o.status);
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          URow(
            children: <Widget>[
              UContainer(radius: 10, color: scheme.primary, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: UTextTitleSmall(o.number.toString().toPersianNumber(), color: scheme.onPrimary)),
              const SizedBox(width: 8),
              UTextTitleSmall(_where(o), expanded: 1),
              UTextLabelSmall(o.createdAt.toLocal().toJalaliDateTime().split(" ").last.toPersianNumber(), color: scheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          for (final UMenuOrderLine l in o.jsonData.lines)
            UTextBodyMedium("${l.quantity.toString().toPersianNumber()}× ${l.title}${l.choices.isEmpty ? "" : " (${l.choices.join("، ")})"}${l.note == null ? "" : " — ${l.note}"}"),
          if (o.jsonData.note != null) UTextBodySmall(o.jsonData.note!, color: scheme.error),
          const SizedBox(height: 8),
          URow(
            children: <Widget>[
              UTextTitleSmall(money(o.total), expanded: 1),
              if (o.status == TagMenuOrder.paid || o.status == TagMenuOrder.accepted) IconButton(icon: Icon(Icons.close_rounded, color: scheme.error), tooltip: U.s.rejectAndRefund, onPressed: () => _reject(o)),
              if (n != null) UButton(title: n.localizedTitle, size: UButtonSize.small, onTap: () => _move(o, n)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.place.title).help("app.cafe.page", inline: true),
      actions: <Widget>[
        if (AppWorkspace.isOwner) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => PlaceForm.show(AppKind.cafe, place: widget.place)),
        if (widget.place.menuId != null) IconButton(icon: const Icon(Icons.visibility_outlined), tooltip: U.s.seeItAsACustomer, onPressed: () => UNavigator.push(PublicMenuPage(menuId: widget.place.menuId!))).help("app.cafe.preview"),
        const UHelpActions("app.cafe."),
      ],
    ),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          if (widget.place.pending) AppCard(child: AppTile(icon: Icons.hourglass_top_rounded, title: U.s.waitingForApproval, subtitle: U.s.newPlacesAreShownToCustomersAfterKhabroomApprovesThem)).pOnly(bottom: 12),
          AppGrid(
            columns: 4,
            spacing: 10,
            children: <Widget>[
              AppFeatureTile(title: U.s.menu, subtitle: "${menu?.itemCount.toString().toPersianNumber() ?? "-"} ${U.s.items}", icon: Icons.restaurant_menu_rounded, onTap: () => UNavigator.push(CafeMenuPage(place: widget.place)).then((_) {
                menu = null;
                read();
              })),
              AppFeatureTile(title: U.s.tablesAndQr, subtitle: "${menu?.jsonData.scans.toString().toPersianNumber() ?? "-"} ${U.s.scans}", icon: Icons.qr_code_2_rounded, onTap: () => UNavigator.push(CafeTablesPage(place: widget.place))),
              AppFeatureTile(title: U.s.menuLook, subtitle: U.s.colorAndOrdering, icon: Icons.palette_outlined, onTap: () => UNavigator.push(CafeLookPage(place: widget.place)).then((_) {
                menu = null;
                read();
              })),
              AppFeatureTile(title: U.s.photos, icon: Icons.photo_library_outlined, onTap: () => UNavigator.push(PlacePhotosPage(place: widget.place))),
              AppFeatureTile(title: U.s.reviews, icon: Icons.rate_review_outlined, onTap: () => UNavigator.push(ReviewsPage(place: widget.place))),
            ],
          ).help("app.cafe.tiles"),
          if (canOrders) ...<Widget>[
            AppLabel("${U.s.openOrders} · ${orders.length.toString().toPersianNumber()}"),
            if (menu != null && !menu!.has(TagMenu.ordering)) AppCard(child: AppTile(icon: Icons.info_outline_rounded, title: U.s.orderingIsOff, subtitle: U.s.turnItOnInMenuLook)).pOnly(bottom: 10),
            if (orders.isEmpty) AppCard(child: AppEmpty(title: U.s.noOpenOrders, subtitle: U.s.newOrdersAppearHereByThemselves, icon: Icons.local_cafe_outlined)),
            AppGrid(children: <Widget>[for (final UMenuOrderResponse o in orders) _order(context, o)]).help("app.cafe.orders"),
          ],
        ],
      ),
    ),
  );
}
