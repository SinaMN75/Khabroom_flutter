import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// How the menu looks to customers and what it lets them do: a short line under the name, the accent colour, and the kinds of order.
class CafeLookPage extends StatefulWidget {
  const CafeLookPage({required this.place, super.key});

  final AppPlace place;

  @override
  State<CafeLookPage> createState() => _CafeLookPageState();
}

class _CafeLookPageState extends State<CafeLookPage> {
  final URxState state = URxState();
  final TextEditingController tagline = TextEditingController();
  UMenuResponse? menu;
  String accent = "#E07A3F";
  final Set<int> tags = <int>{};
  bool busy = false;

  static const List<String> accents = <String>["#E07A3F", "#C0432E", "#2E7D5B", "#2F5A86", "#7A4E9C", "#B4553A", "#1F3B2D", "#C8892F"];

  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    tagline.dispose();
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
    tagline.text = menu!.jsonData.tagline ?? "";
    accent = menu!.jsonData.accent;
    tags
      ..clear()
      ..addAll(menu!.tags);
    if (mounted) setState(() {});
    state.loaded();
  }

  Color _color(String hex) => Color(int.tryParse("FF${hex.replaceAll("#", "")}", radix: 16) ?? 0xFFE07A3F);

  Future<void> _save() async {
    setState(() => busy = true);
    await appSend(UServices.cafe.updateMenu(p: UMenuUpdateParams(id: menu!.id, tagline: tagline.text.trim(), accent: accent, tags: tags.toList())));
    if (mounted) setState(() => busy = false);
  }

  Widget _switch(TagMenu t, String title, String subtitle) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    value: tags.contains(t.number),
    onChanged: (bool v) => setState(() => v ? tags.add(t.number) : tags.remove(t.number)),
    title: Text(title),
    subtitle: Text(subtitle),
  );

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.menuLook).help("app.look.page", inline: true), actions: const <Widget>[UHelpActions("app.look.")]),
    body: AppStateView(
      state: state,
      onRetry: read,
      onLoaded: (BuildContext context) => AppPageBody(
        maxWidth: AppResponsive.readableMaxWidth,
        children: <Widget>[
          AppSectionCard(
            title: U.s.look,
            icon: Icons.palette_outlined,
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: <Widget>[
                UTextField(controller: tagline, labelText: U.s.tagline, hintText: U.s.forExampleCoffeeUnderTheOrangeTrees),
                UTextBodySmall(U.s.accentColor),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final String c in accents)
                      UContainer(
                        width: 40,
                        height: 40,
                        radius: 20,
                        color: _color(c),
                        border: accent == c ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                        onTap: () => setState(() => accent = c),
                      ),
                  ],
                ).help("app.look.accent"),
              ],
            ),
          ).pOnly(bottom: 12),
          AppSectionCard(
            title: U.s.ordering,
            icon: Icons.shopping_bag_outlined,
            child: UColumn(
              children: <Widget>[
                _switch(TagMenu.active, U.s.menuIsOpen, U.s.whenOffTheQrCodesShowNothing),
                _switch(TagMenu.ordering, U.s.onlineOrdering, U.s.whenOffTheMenuIsForViewingOnly),
                if (tags.contains(TagMenu.ordering.number)) ...<Widget>[
                  _switch(TagMenu.tableOrder, U.s.atTheTable, U.s.theOrderIsBroughtToTheTable),
                  _switch(TagMenu.takeawayOrder, U.s.takeaway, U.s.theCustomerPicksItUpAtTheCounter),
                  _switch(TagMenu.roomOrder, U.s.toARoom, U.s.onlyForCurrentGuestsOrResidentsOfThisBusiness),
                ],
              ],
            ),
          ).help("app.look.ordering"),
          const SizedBox(height: 16),
          UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save),
        ],
      ),
    ),
  );
}
