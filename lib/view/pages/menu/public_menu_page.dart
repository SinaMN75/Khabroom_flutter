import "package:khabroom/main.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/menu/public_menu_controller.dart";
import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The café's online menu: what a customer sees after scanning a table's QR code.
class PublicMenuPage extends StatefulWidget {
  const PublicMenuPage({required this.menuId, super.key, this.table, this.fromLink = false});

  final String menuId;
  final int? table;
  final bool fromLink;

  @override
  State<PublicMenuPage> createState() => _PublicMenuPageState();
}

class _PublicMenuPageState extends State<PublicMenuPage> {
  final PublicMenuController c = PublicMenuController();
  static const Color _deep = Color(0xFF1F3B2D);
  static const Color _cream = Color(0xFFF4EBDD);

  @override
  void initState() {
    c.init(menuId: widget.menuId, table: widget.table, fromLink: widget.fromLink).then((_) => mounted ? setState(() {}) : null);
    super.initState();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme.copyWith(primary: c.accent)),
    child: UScaffold(
      color: UApp.isDarkTheme() ? null : _cream,
      body: AppStateView(
        state: c.state,
        onRetry: c.read,
        emptyTitle: U.s.thisMenuHasNoItemsYet,
        emptyIcon: Icons.restaurant_menu_rounded,
        loadingHeight: 400,
        onLoaded: (BuildContext context) => _body(context),
      ),
      bottomNavigationBar: UObx(() => c.ordering && c.cart.isNotEmpty ? _cartBar(context) : const SizedBox.shrink()),
    ),
  );

  Widget _body(BuildContext context) {
    final UMenuResponse m = c.menu!;
    final List<UMenuCategory> categories = <UMenuCategory>[
      ...m.jsonData.categories.where((UMenuCategory x) => c.itemsOf(x.id).isNotEmpty),
      if (c.itemsOf(null).isNotEmpty) UMenuCategory(id: "", title: U.s.more),
    ];
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: _deep,
          foregroundColor: Colors.white,
          leading: widget.fromLink ? IconButton(icon: const Icon(Icons.home_outlined), onPressed: () => UNavigator.offAll(const SplashPage())) : null,
          title: Text(m.placeTitle ?? m.title),
          flexibleSpace: FlexibleSpaceBar(background: _hero(m)),
        ),
        if (c.featured.isNotEmpty)
          SliverToBoxAdapter(
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                UTextTitleLarge(U.s.ourPicks).pOnly(right: 16, left: 16, top: 18, bottom: 10),
                SizedBox(
                  height: 214,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: <Widget>[for (final UMenuItemResponse i in c.featured) _featuredCard(context, i).pOnly(left: 12)],
                  ),
                ),
              ],
            ).help("app.menu.featured"),
          ),
        for (final UMenuCategory cat in categories) ...<Widget>[
          SliverToBoxAdapter(child: _categoryTitle(context, cat.title)),
          SliverList.list(children: <Widget>[for (final UMenuItemResponse i in c.itemsOf(cat.id.isEmpty ? null : cat.id)) _row(context, i)]),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _hero(UMenuResponse m) => UContainer(
    gradient: const LinearGradient(colors: <Color>[_deep, Color(0xFF2E5A44)], begin: Alignment.topRight, end: Alignment.bottomLeft),
    padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
    child: UColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        UTextDisplaySmall(m.placeTitle ?? m.title, color: _cream),
        if (m.jsonData.tagline != null) UTextBodyMedium(m.jsonData.tagline!, color: _cream.withValues(alpha: 0.8)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: <Widget>[
            if (c.table != null) _pill("${U.s.tableNumber} ${c.table.toString().toPersianNumber()}", Icons.table_restaurant_outlined),
            _pill(c.ordering ? U.s.orderAndPayFromYourTable : U.s.viewOnlyMenu, c.ordering ? Icons.touch_app_outlined : Icons.menu_book_outlined),
          ],
        ),
      ],
    ),
  );

  Widget _pill(String text, IconData icon) => UContainer(
    radius: 99,
    color: Colors.white.withValues(alpha: 0.14),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: URow(mainAxisSize: MainAxisSize.min, children: <Widget>[Icon(icon, size: 14, color: _cream), const SizedBox(width: 6), UTextLabelMedium(text, color: _cream)]),
  );

  Widget _categoryTitle(BuildContext context, String title) => URow(
    children: <Widget>[
      UTextTitleLarge(title, color: Theme.of(context).colorScheme.onSurface),
      const SizedBox(width: 10),
      Expanded(child: Divider(color: c.accent.withValues(alpha: 0.4), thickness: 1.5)),
    ],
  ).pOnly(right: 16, left: 16, top: 22, bottom: 6);

  Widget _thumb(UMenuItemResponse i, double size) => i.imageUrl == null
      ? UContainer(width: size, height: size, radius: 16, color: c.accent.withValues(alpha: 0.12), alignment: Alignment.center, child: Icon(Icons.local_cafe_outlined, color: c.accent, size: size * 0.4))
      : UImage(i.imageUrl!, width: size, height: size, fit: BoxFit.cover, borderRadius: 16);

  Widget _featuredCard(BuildContext context, UMenuItemResponse i) => SizedBox(
    width: 168,
    child: AppCard(
      onTap: () => _openItem(i),
      padding: const EdgeInsets.all(10),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _thumb(i, 148),
          const SizedBox(height: 8),
          UTextTitleSmall(i.title, maxLines: 1),
          UTextBodySmall(money(i.price), color: c.accent, fontWeight: FontWeight.w700),
        ],
      ),
    ),
  );

  Widget _row(BuildContext context, UMenuItemResponse i) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => _openItem(i),
      child: URow(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _thumb(i, 76),
          const SizedBox(width: 12),
          UColumn(
            expanded: 1,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              URow(
                children: <Widget>[
                  UTextTitleMedium(i.title, expanded: 1, maxLines: 1),
                  if (i.has(TagMenuItem.isNew)) AppChip(label: TagMenuItem.isNew.localizedTitle, tone: AppTone.positive),
                  if (i.has(TagMenuItem.popular)) AppChip(label: TagMenuItem.popular.localizedTitle, tone: AppTone.warning),
                ],
              ),
              if (i.jsonData.description != null) UTextBodySmall(i.jsonData.description!, color: scheme.onSurfaceVariant, maxLines: 2),
              const SizedBox(height: 6),
              URow(
                children: <Widget>[
                  UTextTitleSmall(money(i.price), color: c.accent, expanded: 1),
                  if (c.ordering)
                    UContainer(
                      radius: 12,
                      color: c.accent,
                      padding: const EdgeInsets.all(6),
                      onTap: () => i.jsonData.options.isEmpty ? _quickAdd(i) : _openItem(i),
                      child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                    ).help("app.menu.add"),
                ],
              ),
            ],
          ),
        ],
      ).pSymmetric(horizontal: 16, vertical: 10),
    );
  }

  void _quickAdd(UMenuItemResponse i) {
    c.add(i, <String>[], 1, null);
    UToast.snackBar(message: "${i.title} ${U.s.wasAddedToYourOrder}");
  }

  Future<void> _openItem(UMenuItemResponse i) => UNavigator.bottomSheet<void>(_ItemSheet(item: i, c: c));

  Widget _cartBar(BuildContext context) => SafeArea(
    child: UContainer(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      radius: 20,
      color: _deep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => UNavigator.bottomSheet<void>(_CartSheet(c: c)),
      child: URow(
        children: <Widget>[
          UContainer(radius: 10, color: c.accent, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), child: UTextLabelLarge(c.count.toString().toPersianNumber(), color: Colors.white)),
          const SizedBox(width: 10),
          UTextTitleSmall(U.s.viewYourOrder, color: Colors.white, expanded: 1),
          UTextTitleSmall(money(c.total), color: _cream),
        ],
      ),
    ).help("app.menu.cart"),
  );
}

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.item, required this.c});

  final UMenuItemResponse item;
  final PublicMenuController c;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  final Set<String> chosen = <String>{};
  final TextEditingController note = TextEditingController();
  int quantity = 1;

  @override
  void initState() {
    for (final UMenuItemOption o in widget.item.jsonData.options.where((UMenuItemOption o) => o.required && o.choices.isNotEmpty)) chosen.add(o.choices.first.title);
    super.initState();
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  double get unit => widget.item.price + widget.item.jsonData.options.expand((UMenuItemOption o) => o.choices).where((UMenuItemChoice x) => chosen.contains(x.title)).fold<double>(0, (double s, UMenuItemChoice x) => s + x.price);

  void _pick(UMenuItemOption o, UMenuItemChoice choice) => setState(() {
    if (!o.multiple) chosen.removeAll(o.choices.map((UMenuItemChoice x) => x.title));
    if (o.multiple && chosen.contains(choice.title)) {
      chosen.remove(choice.title);
    } else {
      chosen.add(choice.title);
    }
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final UMenuItemResponse i = widget.item;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (i.imageUrl != null) UImage(i.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover, borderRadius: 20).pOnly(bottom: 14),
          UTextHeadlineSmall(i.title),
          if (i.jsonData.description != null) UTextBodyMedium(i.jsonData.description!, color: scheme.onSurfaceVariant).pOnly(top: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              if (i.jsonData.prepMinutes != null) AppChip(label: "${i.jsonData.prepMinutes.toString().toPersianNumber()} ${U.s.minutes}", icon: Icons.timer_outlined),
              for (final TagMenuItem t in <TagMenuItem>[TagMenuItem.vegetarian, TagMenuItem.spicy, TagMenuItem.glutenFree, TagMenuItem.sugarFree].where(i.has)) AppChip(label: t.localizedTitle, tone: AppTone.positive),
            ],
          ).pOnly(top: 10),
          for (final UMenuItemOption o in i.jsonData.options) ...<Widget>[
            const SizedBox(height: 16),
            UTextTitleSmall("${o.title}${o.required ? " *" : ""}"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final UMenuItemChoice x in o.choices)
                  ChoiceChip(
                    label: Text(x.price > 0 ? "${x.title} (+${money(x.price)})" : x.title),
                    selected: chosen.contains(x.title),
                    onSelected: widget.c.ordering ? (_) => _pick(o, x) : null,
                  ),
              ],
            ),
          ],
          if (widget.c.ordering) ...<Widget>[
            const SizedBox(height: 16),
            UTextField(controller: note, labelText: U.s.noteForTheKitchen, hintText: U.s.forExampleLessSugar),
            const SizedBox(height: 16),
            URow(
              children: <Widget>[
                IconButton.filledTonal(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove_rounded)),
                UTextTitleLarge(quantity.toString().toPersianNumber()).pSymmetric(horizontal: 14),
                IconButton.filledTonal(onPressed: quantity < 50 ? () => setState(() => quantity++) : null, icon: const Icon(Icons.add_rounded)),
                const SizedBox(width: 12),
                Expanded(
                  child: UButton(
                    title: "${U.s.addToOrder} · ${money(unit * quantity)}",
                    onTap: () {
                      widget.c.add(i, chosen.toList(), quantity, note.text.trim().isEmpty ? null : note.text.trim());
                      UNavigator.back();
                    },
                  ),
                ),
              ],
            ),
          ] else
            UTextBodySmall(U.s.thisMenuIsForViewingOnly, color: scheme.onSurfaceVariant, textAlign: TextAlign.center).pOnly(top: 18),
        ],
      ),
    );
  }
}

class _CartSheet extends StatefulWidget {
  const _CartSheet({required this.c});

  final PublicMenuController c;

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool busy = false;

  PublicMenuController get c => widget.c;

  String _typeTitle(TagMenuOrder t) => switch (t) {
    TagMenuOrder.table => U.s.atTheTable,
    TagMenuOrder.room => U.s.toMyRoom,
    _ => U.s.takeaway,
  };

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    await AppSession.require(() async {
      setState(() => busy = true);
      final bool ok = await c.submit();
      if (!mounted) return;
      if (ok) {
        UNavigator.back();
        return;
      }
      setState(() => busy = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UObx(
      () => Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
          child: AppContent(
            maxWidth: AppResponsive.readableMaxWidth,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                UTextTitleLarge(U.s.yourOrder),
                const SizedBox(height: 10),
                for (final MenuCartLine l in c.cart)
                  URow(
                    children: <Widget>[
                      UColumn(
                        expanded: 1,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          UTextTitleSmall(l.item.title),
                          if (l.choices.isNotEmpty || l.note != null) UTextBodySmall(<String>[...l.choices, ?l.note].join("، "), color: scheme.onSurfaceVariant),
                          UTextBodySmall(money(l.total), color: scheme.primary),
                        ],
                      ),
                      IconButton(onPressed: () => c.change(l, -1), icon: const Icon(Icons.remove_circle_outline)),
                      UTextTitleMedium(l.quantity.toString().toPersianNumber()),
                      IconButton(onPressed: () => c.change(l, 1), icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ).pOnly(bottom: 6),
                const Divider(),
                if (c.types.length > 1) ...<Widget>[
                  UTextTitleSmall(U.s.howDoYouWantIt).help("app.menu.type", inline: true),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[for (final TagMenuOrder t in c.types) ChoiceChip(label: Text(_typeTitle(t)), selected: c.type == t, onSelected: (_) => setState(() => c.type = t))],
                  ),
                  const SizedBox(height: 12),
                ],
                if (c.type == TagMenuOrder.table)
                  UTextField(controller: c.tableController, labelText: U.s.tableNumber, keyboardType: TextInputType.number, validator: UValidators.required<String>()),
                if (c.type == TagMenuOrder.room) UTextField(controller: c.roomController, labelText: U.s.roomNumber, validator: UValidators.required<String>()),
                const SizedBox(height: 10),
                UTextField(controller: c.noteController, labelText: U.s.note),
                const SizedBox(height: 14),
                AppInfoRow(label: U.s.total, value: money(c.total), emphasize: true),
                const SizedBox(height: 10),
                UButton(title: "${U.s.orderAndPay} · ${money(c.total)}", isLoading: busy, onTap: busy || c.cart.isEmpty ? null : _submit).help("app.menu.pay"),
                UTextBodySmall(U.s.ifTheCafeRejectsYourOrderTheMoneyGoesBackToYourWallet, color: scheme.onSurfaceVariant, textAlign: TextAlign.center).pOnly(top: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
