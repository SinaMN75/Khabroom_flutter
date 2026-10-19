import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The dorm's food: each meal, its price and how many residents reserved it.
class DormMealsPage extends StatefulWidget {
  const DormMealsPage({required this.dormId, super.key});

  final String dormId;

  @override
  State<DormMealsPage> createState() => _DormMealsPageState();
}

class _DormMealsPageState extends State<DormMealsPage> {
  final URxState state = URxState();
  List<UDormMealResponse> list = <UDormMealResponse>[];

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
    final DateTime today = DateTime.now().copyWith(hour: 0, minute: 0);
    final UResponse<List<UDormMealResponse>>? r = (await UServices.dorm.readMeals(p: UDormMealReadParams(dormId: widget.dormId, fromDate: today.subtract(const Duration(days: 1)), toDate: today.add(const Duration(days: 14)), pageSize: 200, pageNumber: 1))).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = r.result ?? <UDormMealResponse>[];
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _form([UDormMealResponse? meal]) async {
    TagDormMeal kind = TagDormMeal.values.where((TagDormMeal t) => meal?.tags.contains(t.number) ?? false).firstOrNull ?? TagDormMeal.lunch;
    final TextEditingController title = TextEditingController(text: meal?.title);
    final TextEditingController price = TextEditingController(text: rialToTomanText(meal?.price));
    final TextEditingController capacity = TextEditingController(text: meal?.capacity?.toString());
    DateTime? date = meal?.date ?? DateTime.now().add(const Duration(days: 1));
    final bool ok = await AppForm.show(
      title: meal == null ? U.s.newMeal : "${U.s.edit} · ${meal.title}",
      help: "app.meals.form",
      onSubmit: () => appSend(
        meal == null
            ? UServices.dorm.createMeal(p: UDormMealCreateParams(dormId: widget.dormId, title: title.text.trim(), date: date ?? DateTime.now(), tags: <int>[kind.number], price: tomanToRial(price), capacity: int.tryParse(capacity.numString())))
            : UServices.dorm.updateMeal(p: UDormMealUpdateParams(id: meal.id, title: title.text.trim(), date: date, price: tomanToRial(price), capacity: int.tryParse(capacity.numString()), tags: <int>[kind.number])),
      ),
      children: (BuildContext context, StateSetter setState) => <Widget>[
        Wrap(spacing: 8, children: <Widget>[for (final TagDormMeal k in TagDormMeal.values) ChoiceChip(label: Text(k.localizedTitle), selected: kind == k, onSelected: (_) => setState(() => kind = k))]),
        UTextField(controller: title, labelText: U.s.whatIsOnTheMenu, hintText: U.s.forExampleChickenAndRice, validator: UValidators.required<String>()),
        UTextFieldDatePicker(labelText: U.s.date, jalali: true, initialDate: date, onChange: (DateTime d, _) => date = d),
        AppMoneyField(controller: price, label: U.s.price, required: false),
        UTextField(controller: capacity, labelText: U.s.howManyPortions, keyboardType: TextInputType.number),
      ],
    );
    for (final TextEditingController c in <TextEditingController>[title, price, capacity]) c.dispose();
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.meals).help("app.meals.page", inline: true), actions: const <Widget>[UHelpActions("app.meals.")]),
    floatingActionButton: FloatingActionButton(onPressed: _form, child: const Icon(Icons.add_rounded)),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.noMealsPlanned,
      emptyIcon: Icons.restaurant_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                for (final UDormMealResponse m in list)
                  AppTile(
                    icon: Icons.restaurant_outlined,
                    title: "${TagDormMeal.values.where((TagDormMeal t) => m.tags.contains(t.number)).firstOrNull?.localizedTitle ?? ""} · ${m.title}",
                    subtitle: "${m.date.toJalaliDate().toPersianNumber()} · ${m.price > 0 ? money(m.price) : U.s.free}",
                    trailing: AppChip(label: "${m.reservedCount.toString().toPersianNumber()}${m.capacity == null ? "" : "/${m.capacity.toString().toPersianNumber()}"}", icon: Icons.people_outline_rounded),
                    onTap: () => _form(m),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
