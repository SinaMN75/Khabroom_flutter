import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class _OptionDraft {
  _OptionDraft({String title = "", this.required = false, this.multiple = false, List<UMenuItemChoice> choices = const <UMenuItemChoice>[]})
    : title = TextEditingController(text: title),
      choices = choices.map((UMenuItemChoice c) => (TextEditingController(text: c.title), TextEditingController(text: rialToTomanText(c.price)))).toList();

  final TextEditingController title;
  bool required;
  bool multiple;
  final List<(TextEditingController, TextEditingController)> choices;

  void dispose() {
    title.dispose();
    for (final (TextEditingController, TextEditingController) c in choices) {
      c.$1.dispose();
      c.$2.dispose();
    }
  }
}

/// One dish or drink: its photo, price, labels, and choices like milk type that can change the price.
class CafeItemPage extends StatefulWidget {
  const CafeItemPage({required this.menu, super.key, this.item});

  final UMenuResponse menu;
  final UMenuItemResponse? item;

  @override
  State<CafeItemPage> createState() => _CafeItemPageState();
}

class _CafeItemPageState extends State<CafeItemPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late final TextEditingController title = TextEditingController(text: widget.item?.title);
  late final TextEditingController price = TextEditingController(text: rialToTomanText(widget.item?.price));
  late final TextEditingController description = TextEditingController(text: widget.item?.jsonData.description);
  late final TextEditingController prep = TextEditingController(text: widget.item?.jsonData.prepMinutes?.toString());
  late String? categoryId = widget.item?.categoryId ?? widget.menu.jsonData.categories.firstOrNull?.id;
  late final List<int> labels = List<int>.from(widget.item?.tags.where((int t) => t >= 200) ?? <int>[]);
  late final List<_OptionDraft> options = (widget.item?.jsonData.options ?? <UMenuItemOption>[])
      .map((UMenuItemOption o) => _OptionDraft(title: o.title, required: o.required, multiple: o.multiple, choices: o.choices))
      .toList();
  late final UFilePickerController photo = UFilePickerController.fromMedia(widget.item?.media ?? <UMediaResponse>[]);
  bool busy = false;

  static const List<TagMenuItem> labelOptions = <TagMenuItem>[
    TagMenuItem.featured,
    TagMenuItem.isNew,
    TagMenuItem.popular,
    TagMenuItem.vegetarian,
    TagMenuItem.spicy,
    TagMenuItem.glutenFree,
    TagMenuItem.sugarFree,
  ];

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[title, price, description, prep]) c.dispose();
    for (final _OptionDraft o in options) o.dispose();
    super.dispose();
  }

  List<UMenuItemOption> get _options => options
      .where((_OptionDraft o) => o.title.text.trim().isNotEmpty)
      .map(
        (_OptionDraft o) => UMenuItemOption(
          title: o.title.text.trim(),
          required: o.required,
          multiple: o.multiple,
          choices: o.choices.where(((TextEditingController, TextEditingController) c) => c.$1.text.trim().isNotEmpty).map(((TextEditingController, TextEditingController) c) => UMenuItemChoice(title: c.$1.text.trim(), price: tomanToRial(c.$2))).toList(),
        ),
      )
      .toList();

  Future<void> _save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => busy = true);
    final UMenuItemResponse? i = widget.item;
    final List<int> tags = <int>[i?.has(TagMenuItem.unavailable) ?? false ? TagMenuItem.unavailable.number : TagMenuItem.available.number, ...labels];
    String? id = i?.id;
    final bool ok;
    if (i == null) {
      final (UResponse<String>? r, UEmptyResponse? error, String? exception) = await UServices.cafe.createMenuItem(
        p: UMenuItemCreateParams(
          menuId: widget.menu.id,
          title: title.text.trim(),
          price: tomanToRial(price),
          tags: tags,
          order: widget.menu.itemCount,
          categoryId: categoryId,
          description: description.valueOrNull(),
          prepMinutes: int.tryParse(prep.numString()),
          options: _options,
        ),
      );
      id = r?.result;
      ok = id != null;
      if (!ok) UToast.error(message: error?.message ?? exception ?? U.s.error);
    } else {
      ok = await appSend(
        UServices.cafe.updateMenuItem(
          p: UMenuItemUpdateParams(id: i.id, title: title.text.trim(), price: tomanToRial(price), tags: tags, categoryId: categoryId, description: description.text.trim(), prepMinutes: int.tryParse(prep.numString()), options: _options),
        ),
        toast: false,
      );
    }
    if (ok && id != null) await UServices.media.syncGallery(photo, existing: i?.media ?? <UMediaResponse>[], menuItemId: id);
    if (ok) {
      UToast.success(message: U.s.done);
      UNavigator.back(true);
      return;
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _delete() async {
    if (await UNavigator.confirmAsync(title: U.s.delete, message: U.s.areYouSureYouWantToDelete, destructive: true) && await appSend(UServices.cafe.deleteMenuItem(p: UIdParams(id: widget.item!.id)))) UNavigator.back(true);
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(
      title: Text(widget.item?.title ?? U.s.newItem).help("app.item.page", inline: true),
      actions: <Widget>[if (widget.item != null) IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete), const UHelpActions("app.item.")],
    ),
    body: Form(
      key: formKey,
      child: AppPageBody(
        maxWidth: AppResponsive.readableMaxWidth,
        children: <Widget>[
          UFilePicker.gallery(photo).help("app.item.photo"),
          const SizedBox(height: 12),
          UTextField(controller: title, labelText: U.s.name, validator: UValidators.required<String>()),
          const SizedBox(height: 10),
          AppMoneyField(controller: price, label: U.s.price),
          const SizedBox(height: 10),
          UDropDownField<String?>(
            labelText: U.s.category,
            initialValue: categoryId,
            items: <DropdownMenuItem<String?>>[
              DropdownMenuItem<String?>(child: Text(U.s.withoutCategory)),
              for (final UMenuCategory c in widget.menu.jsonData.categories) DropdownMenuItem<String?>(value: c.id, child: Text(c.title)),
            ],
            onChanged: (String? v) => setState(() => categoryId = v),
          ),
          const SizedBox(height: 10),
          UTextField(controller: description, labelText: U.s.description, lines: 2),
          const SizedBox(height: 10),
          UTextField(controller: prep, labelText: U.s.prepMinutes, keyboardType: TextInputType.number),
          const SizedBox(height: 14),
          UTextTitleSmall(U.s.labels),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final TagMenuItem t in labelOptions)
                FilterChip(label: Text(t.localizedTitle), selected: labels.contains(t.number), onSelected: (bool on) => setState(() => on ? labels.add(t.number) : labels.remove(t.number))),
            ],
          ).help("app.item.labels"),
          AppLabel(U.s.choices, action: U.s.addChoice, onAction: () => setState(() => options.add(_OptionDraft(choices: <UMenuItemChoice>[UMenuItemChoice(title: "")])))),
          for (final _OptionDraft o in options)
            AppCard(
              padding: const EdgeInsets.all(12),
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: <Widget>[
                  URow(
                    children: <Widget>[
                      Expanded(child: UTextField(controller: o.title, labelText: U.s.choiceTitle, hintText: U.s.forExampleMilkType)),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () => setState(() => options.remove(o))),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      FilterChip(label: Text(U.s.mustChoose), selected: o.required, onSelected: (bool v) => setState(() => o.required = v)),
                      FilterChip(label: Text(U.s.canPickMoreThanOne), selected: o.multiple, onSelected: (bool v) => setState(() => o.multiple = v)),
                    ],
                  ),
                  for (final (TextEditingController, TextEditingController) c in o.choices)
                    URow(
                      spacing: 8,
                      children: <Widget>[
                        Expanded(flex: 3, child: UTextField(controller: c.$1, labelText: U.s.option)),
                        Expanded(flex: 2, child: AppMoneyField(controller: c.$2, label: U.s.extra, required: false)),
                      ],
                    ),
                  UButton(title: U.s.addOption, type: UButtonType.text, onTap: () => setState(() => o.choices.add((TextEditingController(), TextEditingController())))),
                ],
              ),
            ).pOnly(bottom: 10),
          const SizedBox(height: 10),
          UButton(title: U.s.save, isLoading: busy, onTap: busy ? null : _save),
        ],
      ),
    ),
  );
}
