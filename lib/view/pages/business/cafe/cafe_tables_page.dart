import "package:khabroom/main.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:khabroom/utils/responsive.dart";
import "package:u/utilities.dart";

/// A QR code for every table. Print and put them on the tables; a scan opens the menu with the table number already set.
class CafeTablesPage extends StatefulWidget {
  const CafeTablesPage({required this.place, super.key});

  final AppPlace place;

  @override
  State<CafeTablesPage> createState() => _CafeTablesPageState();
}

class _CafeTablesPageState extends State<CafeTablesPage> {
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
    if (widget.place.menuId == null) {
      state.emptying();
      return;
    }
    menu = (await UServices.cafe.openMenu(p: UMenuOpenParams(id: widget.place.menuId!, manage: true))).$1?.result;
    if (menu == null) {
      state.error();
      return;
    }
    if (mounted) setState(() {});
    state.loaded();
  }

  Future<void> _count() async {
    final TextEditingController count = TextEditingController(text: menu!.jsonData.tables.length.toString());
    final bool ok = await AppForm.show(
      title: U.s.howManyTables,
      help: "app.tables.count",
      onSubmit: () => appSend(
        UServices.cafe.updateMenu(p: UMenuUpdateParams(id: menu!.id, tables: List<UMenuTableParams>.generate((int.tryParse(count.numString()) ?? 0).clamp(0, 200), (int i) => UMenuTableParams(number: i + 1)))),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(controller: count, labelText: U.s.tableCount, keyboardType: TextInputType.number)],
    );
    count.dispose();
    if (ok) await read();
  }

  Widget _qr(BuildContext context, String title, String link, {int? scans}) => AppCard(
    padding: const EdgeInsets.all(12),
    child: UColumn(
      children: <Widget>[
        UBarcode(value: link, width: 140, height: 140, moduleShape: UBarcodeModuleShape.rounded, barColor: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        UTextTitleSmall(title),
        if (scans != null) UTextLabelSmall("${scans.toString().toPersianNumber()} ${U.s.scans}", color: Theme.of(context).colorScheme.onSurfaceVariant),
        UButton(title: U.s.copyLink, type: UButtonType.text, onTap: () => UClipboard.set(link, snackBar: true)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.tablesAndQr).help("app.tables.page", inline: true), actions: <Widget>[IconButton(icon: const Icon(Icons.tune_rounded), onPressed: menu == null ? null : _count), const UHelpActions("app.tables.")]),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) {
        final UMenuResponse m = menu!;
        return AppPageBody(
          onRefresh: read,
          children: <Widget>[
            AppGrid(
              columns: 3,
              spacing: 10,
              children: <Widget>[
                AppStat(label: U.s.menuViews, value: m.jsonData.views.toString().toPersianNumber(), icon: Icons.visibility_outlined),
                AppStat(label: U.s.tableScans, value: m.jsonData.scans.toString().toPersianNumber(), icon: Icons.qr_code_scanner_rounded),
                AppStat(label: U.s.tables, value: m.jsonData.tables.length.toString().toPersianNumber(), icon: Icons.table_restaurant_outlined),
              ],
            ),
            UTextBodySmall(U.s.printTheseCodesAndPutOneOnEachTable, color: Theme.of(context).colorScheme.onSurfaceVariant).pSymmetric(vertical: 12),
            AppGrid(
              columns: 3,
              spacing: 10,
              children: <Widget>[
                _qr(context, U.s.generalMenu, AppLinks.menu(m.id)),
                for (final UMenuTable t in m.jsonData.tables) _qr(context, t.title ?? "${U.s.tableNumber} ${t.number.toString().toPersianNumber()}", AppLinks.menu(m.id, table: t.number), scans: t.scans),
              ],
            ).help("app.tables.codes"),
            if (m.jsonData.tables.isEmpty) UButton(title: U.s.setTheNumberOfTables, type: UButtonType.outlined, onTap: _count).pOnly(top: 12),
          ],
        );
      },
    ),
  );
}
