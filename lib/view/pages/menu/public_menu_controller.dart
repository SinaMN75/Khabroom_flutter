import "package:khabroom/main.dart";
import "package:khabroom/utils/app_pay.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/view/pages/menu/order_tracking_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:u/utilities.dart";

class MenuCartLine {
  MenuCartLine({required this.item, required this.choices, this.quantity = 1, this.note});

  final UMenuItemResponse item;
  final List<String> choices;
  int quantity;
  String? note;

  double get unitPrice => item.price + item.jsonData.options.expand((UMenuItemOption o) => o.choices).where((UMenuItemChoice c) => choices.contains(c.title)).fold<double>(0, (double s, UMenuItemChoice c) => s + c.price);

  double get total => unitPrice * quantity;

  bool sameAs(UMenuItemResponse i, List<String> c, String? n) => item.id == i.id && note == n && choices.length == c.length && choices.every(c.contains);
}

class PublicMenuController extends UBaseController {
  late String menuId;
  int? table;
  UMenuResponse? menu;
  final URxList<MenuCartLine> cart = <MenuCartLine>[].obs;
  TagMenuOrder type = TagMenuOrder.table;
  final TextEditingController tableController = TextEditingController();
  final TextEditingController roomController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool get ordering => menu?.has(TagMenu.ordering) ?? false;

  List<TagMenuOrder> get types => <TagMenuOrder>[
    if (menu?.has(TagMenu.tableOrder) ?? false) TagMenuOrder.table,
    if (menu?.has(TagMenu.takeawayOrder) ?? false) TagMenuOrder.takeaway,
    if (menu?.has(TagMenu.roomOrder) ?? false) TagMenuOrder.room,
  ];

  Color get accent => Color(int.tryParse("FF${(menu?.jsonData.accent ?? "#E07A3F").replaceAll("#", "")}", radix: 16) ?? 0xFFE07A3F);

  int get count => cart.fold<int>(0, (int s, MenuCartLine l) => s + l.quantity);

  double get total => cart.fold<double>(0, (double s, MenuCartLine l) => s + l.total);

  Future<void> init({required String menuId, int? table, bool fromLink = false}) async {
    this.menuId = menuId;
    this.table = table;
    if (table != null) tableController.text = table.toString();
    if (fromLink) await AppSession.load();
    await read();
  }

  Future<void> read() async {
    state.loading();
    final UResponse<UMenuResponse>? r = (await UServices.cafe.openMenu(p: UMenuOpenParams(id: menuId, table: table))).$1;
    if (r?.result == null) return setError();
    menu = r!.result;
    if (!types.contains(type) && types.isNotEmpty) type = types.first;
    (menu!.items ?? <UMenuItemResponse>[]).isEmpty ? state.emptying() : state.loaded();
  }

  List<UMenuItemResponse> itemsOf(String? categoryId) => (menu?.items ?? <UMenuItemResponse>[]).where((UMenuItemResponse i) => i.categoryId == categoryId).toList();

  List<UMenuItemResponse> get featured => (menu?.items ?? <UMenuItemResponse>[]).where((UMenuItemResponse i) => i.has(TagMenuItem.featured)).toList();

  void add(UMenuItemResponse item, List<String> choices, int quantity, String? note) {
    final MenuCartLine? same = cart.where((MenuCartLine l) => l.sameAs(item, choices, note)).firstOrNull;
    if (same != null) {
      same.quantity += quantity;
      cart.refresh();
    } else {
      cart.add(MenuCartLine(item: item, choices: choices, quantity: quantity, note: note));
    }
  }

  void change(MenuCartLine line, int delta) {
    line.quantity += delta;
    if (line.quantity <= 0) cart.remove(line);
    cart.refresh();
  }

  Future<bool> submit() async {
    if (cart.isEmpty || menu == null) return false;
    final (UResponse<UMenuOrderResponse>? ok, UEmptyResponse? error, String? exception) = await UServices.cafe.createOrder(
      p: UMenuOrderCreateParams(
        menuId: menu!.id,
        type: type.number,
        table: type == TagMenuOrder.table ? int.tryParse(tableController.numString()) : null,
        room: type == TagMenuOrder.room ? roomController.text.trim() : null,
        note: noteController.valueOrNull(),
        lines: cart.map((MenuCartLine l) => UMenuOrderLineParams(itemId: l.item.id, quantity: l.quantity, choices: l.choices, note: l.note)).toList(),
      ),
    );
    final UMenuOrderResponse? order = ok?.result;
    if (order == null) {
      UToast.error(message: error?.message ?? exception ?? U.s.error);
      return false;
    }
    final bool paid = await AppPay.pay(
      title: "${U.s.orderNo} ${order.number.toString().toPersianNumber()} · ${menu!.placeTitle ?? menu!.title}",
      amount: order.total,
      tag: TagTxn.menuOrder,
      invoiceId: order.id,
      payFromWallet: () => UServices.cafe.payOrder(p: UIdParams(id: order.id)),
      lines: <(String, String)>[for (final MenuCartLine l in cart) ("${l.quantity.toString().toPersianNumber()}× ${l.item.title}", money(l.total))],
    );
    if (!paid) {
      await appSend(UServices.cafe.cancelOrder(p: UIdParams(id: order.id)), toast: false);
      return false;
    }
    cart.clear();
    noteController.clear();
    await UNavigator.push(OrderTrackingPage(orderId: order.id));
    return true;
  }

  @override
  void dispose() {
    tableController.dispose();
    roomController.dispose();
    noteController.dispose();
    cart.dispose();
    super.dispose();
  }
}
