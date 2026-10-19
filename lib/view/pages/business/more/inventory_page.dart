import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

enum _StoreTab { stock, purchases, equipment }

/// The storeroom: what is in stock and what is running low, purchases waiting for approval, and the equipment each place has.
class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final URxState state = URxState();
  _StoreTab tab = _StoreTab.stock;
  bool lowOnly = false;
  List<UWarehouseResponse> warehouses = <UWarehouseResponse>[];
  List<UInventoryItemResponse> items = <UInventoryItemResponse>[];
  List<UStockResponse> stock = <UStockResponse>[];
  List<UPurchaseResponse> purchases = <UPurchaseResponse>[];
  List<UAssetResponse> assets = <UAssetResponse>[];

  String get orgId => AppWorkspace.org.id;

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

  String _title(_StoreTab t) => switch (t) {
    _StoreTab.stock => U.s.stock,
    _StoreTab.purchases => U.s.purchases,
    _StoreTab.equipment => U.s.equipment,
  };

  Future<void> read() async {
    state.loading();
    warehouses = (await UServices.inventory.readWarehouses(p: UInventoryReadParams(organizationId: orgId, pageSize: 100, pageNumber: 1))).$1?.result ?? <UWarehouseResponse>[];
    if (warehouses.isEmpty) {
      await UServices.inventory.createWarehouse(p: UWarehouseCreateParams(organizationId: orgId, title: U.s.mainStoreroom));
      warehouses = (await UServices.inventory.readWarehouses(p: UInventoryReadParams(organizationId: orgId, pageSize: 100, pageNumber: 1))).$1?.result ?? <UWarehouseResponse>[];
    }
    items = (await UServices.inventory.readItems(p: UInventoryReadParams(organizationId: orgId, pageSize: 500, pageNumber: 1))).$1?.result ?? <UInventoryItemResponse>[];
    switch (tab) {
      case _StoreTab.stock:
        stock = (await UServices.inventory.readStock(p: UStockReadParams(organizationId: orgId, lowOnly: lowOnly))).$1?.result ?? <UStockResponse>[];
      case _StoreTab.purchases:
        purchases = (await UServices.inventory.readPurchases(p: UPurchaseReadParams(organizationId: orgId, pageSize: 100, pageNumber: 1))).$1?.result ?? <UPurchaseResponse>[];
      case _StoreTab.equipment:
        assets = (await UServices.inventory.readAssets(p: UInventoryReadParams(organizationId: orgId, pageSize: 300, pageNumber: 1))).$1?.result ?? <UAssetResponse>[];
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _newItem() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController unit = TextEditingController(text: U.s.piece);
    final TextEditingController min = TextEditingController();
    final bool ok = await AppForm.show(
      title: U.s.newStockItem,
      onSubmit: () => appSend(UServices.inventory.createItem(p: UInventoryItemCreateParams(organizationId: orgId, title: title.text.trim(), unit: unit.text.trim(), minStock: double.tryParse(min.numString()) ?? 0))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.name, hintText: U.s.forExampleTowel, validator: UValidators.required<String>()),
        UTextField(controller: unit, labelText: U.s.unit),
        UTextField(controller: min, labelText: U.s.warnMeBelow, keyboardType: TextInputType.number).help("app.inventory.min"),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, unit, min]) c.dispose();
    if (ok) await read();
  }

  Future<void> _newPurchase() async {
    if (items.isEmpty) {
      await _newItem();
      return;
    }
    String? itemId = items.first.id;
    final TextEditingController quantity = TextEditingController(text: "1");
    final TextEditingController price = TextEditingController();
    final TextEditingController note = TextEditingController();
    final bool ok = await AppForm.show(
      title: U.s.newPurchase,
      help: "app.inventory.purchase",
      onSubmit: () => appSend(
        UServices.inventory.createPurchase(
          p: UPurchaseCreateParams(
            organizationId: orgId,
            warehouseId: warehouses.first.id,
            detail1: note.valueOrNull(),
            lines: <UPurchaseLineParams>[UPurchaseLineParams(itemId: itemId!, quantity: double.tryParse(quantity.numString()) ?? 1, unitPrice: tomanToRial(price))],
          ),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UDropDownField<String?>(
          labelText: U.s.item,
          initialValue: itemId,
          items: <DropdownMenuItem<String?>>[for (final UInventoryItemResponse i in items) DropdownMenuItem<String?>(value: i.id, child: Text(i.title))],
          onChanged: (String? v) => setState(() => itemId = v),
        ),
        UTextField(controller: quantity, labelText: U.s.quantity, keyboardType: TextInputType.number),
        AppMoneyField(controller: price, label: U.s.unitPrice),
        UTextField(controller: note, labelText: U.s.note),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[quantity, price, note]) c.dispose();
    if (ok) await read();
  }

  Future<void> _use(UStockResponse s) async {
    final TextEditingController quantity = TextEditingController(text: "1");
    final bool ok = await AppForm.show(
      title: "${U.s.takeOut} · ${s.itemTitle}",
      help: "app.inventory.use",
      onSubmit: () => appSend(
        UServices.inventory.createMovement(
          p: UStockMovementCreateParams(organizationId: orgId, itemId: s.itemId, warehouseId: s.warehouseId, quantity: double.tryParse(quantity.numString()) ?? 1, tags: <int>[TagStockMovement.stockOut.number]),
        ),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(controller: quantity, labelText: "${U.s.quantity} (${s.unit})", keyboardType: TextInputType.number)],
    );
    quantity.dispose();
    if (ok) await read();
  }

  Future<void> _newAsset() async {
    final TextEditingController title = TextEditingController();
    final TextEditingController code = TextEditingController(text: "A-${(assets.length + 1).toString().padLeft(3, "0")}");
    final TextEditingController location = TextEditingController();
    String? placeId = AppWorkspace.myPlaces.firstOrNull?.id;
    final bool ok = await AppForm.show(
      title: U.s.newEquipment,
      onSubmit: () => appSend(UServices.inventory.createAsset(p: UAssetCreateParams(organizationId: orgId, title: title.text.trim(), code: code.text.trim(), placeId: placeId, location: location.valueOrNull(), tags: <int>[TagAsset.other.number, TagAsset.inUse.number]))),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        UTextField(controller: title, labelText: U.s.name, hintText: U.s.forExampleWashingMachine, validator: UValidators.required<String>()),
        UTextField(controller: code, labelText: U.s.code),
        UDropDownField<String?>(
          labelText: U.s.branch,
          initialValue: placeId,
          items: <DropdownMenuItem<String?>>[for (final AppPlace p in AppWorkspace.myPlaces) DropdownMenuItem<String?>(value: p.id, child: Text(p.title))],
          onChanged: (String? v) => setState(() => placeId = v),
        ),
        UTextField(controller: location, labelText: U.s.where),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, code, location]) c.dispose();
    if (ok) await read();
  }

  Widget _stock(BuildContext context) => UColumn(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      SwitchListTile(contentPadding: EdgeInsets.zero, value: lowOnly, onChanged: (bool v) {
        setState(() => lowOnly = v);
        read();
      }, title: Text(U.s.onlyWhatIsRunningLow)),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: UColumn(
          children: <Widget>[
            if (stock.isEmpty) AppEmpty(title: U.s.nothingInStockYet, actionTitle: U.s.newStockItem, onAction: _newItem),
            for (final UStockResponse s in stock)
              AppTile(
                icon: Icons.inventory_2_outlined,
                iconColor: s.low ? Theme.of(context).colorScheme.error : null,
                title: s.itemTitle,
                subtitle: "${s.warehouseTitle} · ${money(s.value)}",
                trailing: URow(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppChip(label: "${s.quantity.toStringAsFixed(s.quantity % 1 == 0 ? 0 : 1).toPersianNumber()} ${s.unit}", tone: s.low ? AppTone.danger : AppTone.neutral),
                    IconButton(icon: const Icon(Icons.remove_circle_outline_rounded), tooltip: U.s.takeOut, onPressed: () => _use(s)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _purchases(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: UColumn(
      children: <Widget>[
        if (purchases.isEmpty) AppEmpty(title: U.s.noPurchasesYet),
        for (final UPurchaseResponse p in purchases)
          AppTile(
            icon: Icons.shopping_bag_outlined,
            title: "${U.s.purchase} ${p.number.toString().toPersianNumber()} · ${money(p.total)}",
            subtitle: "${p.supplierTitle ?? p.warehouseTitle ?? ""} · ${p.date.toJalaliDate().toPersianNumber()}",
            trailing: p.tags.contains(TagPurchase.requested.number) && AppWorkspace.can(TagUser.permissionManageAccounting)
                ? URow(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(icon: const Icon(Icons.check_rounded), tooltip: U.s.approve, onPressed: () async {
                        if (await appSend(UServices.inventory.reviewPurchase(p: UPurchaseReviewParams(id: p.id, approve: true)))) await read();
                      }),
                      IconButton(icon: const Icon(Icons.close_rounded), tooltip: U.s.reject, onPressed: () async {
                        if (await appSend(UServices.inventory.reviewPurchase(p: UPurchaseReviewParams(id: p.id, approve: false)))) await read();
                      }),
                    ],
                  )
                : p.tags.contains(TagPurchase.approved.number)
                ? UButton(title: U.s.received, size: UButtonSize.small, onTap: () async {
                    if (await appSend(UServices.inventory.receivePurchase(p: UPurchaseReceiveParams(id: p.id)))) await read();
                  })
                : AppChip(label: TagPurchase.values.where((TagPurchase t) => p.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""),
          ),
      ],
    ),
  );

  Widget _equipment(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: UColumn(
      children: <Widget>[
        if (assets.isEmpty) AppEmpty(title: U.s.noEquipmentYet),
        for (final UAssetResponse a in assets)
          AppTile(
            icon: Icons.chair_outlined,
            title: "${a.title} · ${a.code}",
            subtitle: <String>[?AppWorkspace.places.where((AppPlace p) => p.id == a.placeId).firstOrNull?.title, ?a.location].join(" · "),
            trailing: AppChip(label: TagAsset.values.where((TagAsset t) => t.number > 200 && a.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.storeroom).help("app.inventory.page", inline: true), actions: const <Widget>[UHelpActions("app.inventory.")]),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: switch (tab) {
        _StoreTab.stock => _newItem,
        _StoreTab.purchases => _newPurchase,
        _StoreTab.equipment => _newAsset,
      },
      icon: const Icon(Icons.add_rounded),
      label: Text(switch (tab) {
        _StoreTab.stock => U.s.newStockItem,
        _StoreTab.purchases => U.s.newPurchase,
        _StoreTab.equipment => U.s.newEquipment,
      }),
    ),
    body: UColumn(
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final _StoreTab t in _StoreTab.values)
              ChoiceChip(label: Text(_title(t)), selected: tab == t, onSelected: (_) {
                setState(() => tab = t);
                read();
              }),
          ],
        ).pSymmetric(horizontal: 16, vertical: 10),
        Expanded(
          child: AppStateView(
            state: state,
            onRetry: read,
            onLoaded: (BuildContext context) => AppPageBody(
              onRefresh: read,
              children: <Widget>[
                switch (tab) {
                  _StoreTab.stock => _stock(context),
                  _StoreTab.purchases => _purchases(context),
                  _StoreTab.equipment => _equipment(context),
                },
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
