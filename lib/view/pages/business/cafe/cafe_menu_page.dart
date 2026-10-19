import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/cafe/cafe_item_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The menu by category. Switch an item off when it runs out; customers stop seeing it at once.
class CafeMenuPage extends StatefulWidget {
  const CafeMenuPage({required this.place, super.key});

  final AppPlace place;

  @override
  State<CafeMenuPage> createState() => _CafeMenuPageState();
}

class _CafeMenuPageState extends State<CafeMenuPage> {
  final URxState state = URxState();
  UMenuResponse? menu;

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
    String? id = widget.place.menuId;
    if (id == null) {
      final (UResponse<String>? ok, _, _) = await UServices.cafe.createMenu(p: UMenuCreateParams(title: widget.place.title, placeId: widget.place.id));
      id = ok?.result;
    }
    menu = id == null ? null : (await UServices.cafe.openMenu(p: UMenuOpenParams(id: id, manage: true))).$1?.result;
    if (menu == null) {
      state.error();
      return;
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _categories() async {
    final List<UMenuCategory> current = menu!.jsonData.categories;
    final TextEditingController text = TextEditingController(text: current.map((UMenuCategory c) => c.title).join("\n"));
    final bool ok = await AppForm.show(
      title: U.s.categories,
      help: "app.menu.categories",
      onSubmit: () => appSend(
        UServices.cafe.updateMenu(
          p: UMenuUpdateParams(
            id: menu!.id,
            categories: text.text.split("\n").map((String s) => s.trim()).where((String s) => s.isNotEmpty).map((String t) => UMenuCategoryParams(title: t, id: current.where((UMenuCategory c) => c.title == t).firstOrNull?.id)).toList(),
          ),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextBodySmall(U.s.oneCategoryPerLineInTheOrderCustomersSeeThem),
        UTextField(controller: text, labelText: U.s.categories, lines: 8),
      ],
    );
    text.dispose();
    if (ok) await read();
  }

  Future<void> _toggle(UMenuItemResponse i) async {
    final bool off = i.has(TagMenuItem.unavailable);
    if (await appSend(
      UServices.cafe.updateMenuItem(
        p: UMenuItemUpdateParams(id: i.id, addTags: <int>[off ? TagMenuItem.available.number : TagMenuItem.unavailable.number], removeTags: <int>[off ? TagMenuItem.unavailable.number : TagMenuItem.available.number]),
      ),
      toast: false,
    )) await read();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UScaffold(
      appBar: AppBar(
        title: Text(U.s.menu).help("app.menuManage.page", inline: true),
        actions: <Widget>[TextButton.icon(onPressed: menu == null ? null : _categories, icon: const Icon(Icons.category_outlined), label: Text(U.s.categories)).help("app.menuManage.categories"), const UHelpActions("app.menuManage.")],
      ),
      floatingActionButton: menu == null ? null : FloatingActionButton.extended(onPressed: () => UNavigator.push(CafeItemPage(menu: menu!)).then((_) => read()), icon: const Icon(Icons.add_rounded), label: Text(U.s.newItem)),
      body: AppStateView(
        state: state,
        onRetry: read,
        onLoaded: (BuildContext context) {
          final UMenuResponse m = menu!;
          final List<UMenuItemResponse> items = m.items ?? <UMenuItemResponse>[];
          final List<(String?, String)> groups = <(String?, String)>[for (final UMenuCategory c in m.jsonData.categories) (c.id, c.title), (null, U.s.withoutCategory)];
          if (items.isEmpty) return AppEmpty(title: U.s.yourMenuIsEmpty, subtitle: U.s.addCategoriesThenYourFirstItem, icon: Icons.restaurant_menu_rounded, actionTitle: U.s.categories, onAction: _categories);
          return AppPageBody(
            onRefresh: read,
            children: <Widget>[
              for (final (String?, String) g in groups)
                if (items.any((UMenuItemResponse i) => i.categoryId == g.$1)) ...<Widget>[
                  AppLabel("${g.$2} · ${items.where((UMenuItemResponse i) => i.categoryId == g.$1).length.toString().toPersianNumber()}"),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: UColumn(
                      children: <Widget>[
                        for (final UMenuItemResponse i in items.where((UMenuItemResponse i) => i.categoryId == g.$1))
                          URow(
                            children: <Widget>[
                              i.imageUrl == null
                                  ? UContainer(width: 44, height: 44, radius: 12, color: scheme.primaryContainer, child: Icon(Icons.local_cafe_outlined, color: scheme.primary, size: 20))
                                  : UImage(i.imageUrl!, width: 44, height: 44, fit: BoxFit.cover, borderRadius: 12),
                              const SizedBox(width: 10),
                              UColumn(
                                expanded: 1,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  UTextTitleSmall(i.title, color: i.has(TagMenuItem.unavailable) ? scheme.onSurfaceVariant : null),
                                  UTextBodySmall(money(i.price), color: scheme.onSurfaceVariant),
                                ],
                              ),
                              Switch(value: !i.has(TagMenuItem.unavailable), onChanged: (_) => _toggle(i)).help("app.menuManage.available"),
                            ],
                          ).pSymmetric(vertical: 8).onTapInk(() => UNavigator.push(CafeItemPage(menu: m, item: i)).then((_) => read())),
                      ],
                    ),
                  ),
                ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}
