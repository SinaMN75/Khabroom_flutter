import "package:khabroom/main.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Plan cards: what each plan includes, its price for the chosen period, and the free trial when there is one.
class PlanPicker extends StatelessWidget {
  const PlanPicker({required this.plans, required this.selected, required this.months, required this.onSelected, required this.onMonths, super.key});

  final List<USubscriptionPlanResponse> plans;
  final USubscriptionPlanResponse? selected;
  final int months;
  final ValueChanged<USubscriptionPlanResponse> onSelected;
  final ValueChanged<int> onMonths;

  static double? priceOf(USubscriptionPlanResponse p, int months) => p.prices.where((UPlanPrice x) => x.months == months).firstOrNull?.price;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<int> periods = plans.expand((USubscriptionPlanResponse p) => p.prices.map((UPlanPrice x) => x.months)).toSet().toList()..sort();
    return UColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (periods.length > 1)
          Wrap(
            spacing: 8,
            children: <Widget>[for (final int m in periods) ChoiceChip(label: Text("${m.toString().toPersianNumber()} ${U.s.month}"), selected: months == m, onSelected: (_) => onMonths(m))],
          ).pOnly(bottom: 12),
        for (final USubscriptionPlanResponse p in plans.where((USubscriptionPlanResponse p) => priceOf(p, months) != null || p.trialDays > 0))
          UContainer(
            margin: const EdgeInsets.only(bottom: 10),
            radius: 18,
            padding: const EdgeInsets.all(14),
            color: selected?.id == p.id ? scheme.primaryContainer : scheme.surface,
            border: Border.all(color: selected?.id == p.id ? scheme.primary : scheme.outlineVariant, width: selected?.id == p.id ? 2 : 1),
            onTap: () => onSelected(p),
            child: UColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                URow(
                  children: <Widget>[
                    UTextTitleMedium(p.title, expanded: 1),
                    if (p.tags.contains(TagSubscriptionPlan.featured.number)) AppChip(label: TagSubscriptionPlan.featured.localizedTitle, tone: AppTone.warning),
                  ],
                ),
                if (p.description != null) UTextBodySmall(p.description!, color: scheme.onSurfaceVariant),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: <Widget>[for (final TagModule m in TagModule.values.where((TagModule m) => p.modules.contains(m.number))) AppChip(label: m.localizedTitle)]),
                for (final String f in p.features) UTextBodySmall("• $f", color: scheme.onSurfaceVariant),
                const SizedBox(height: 6),
                URow(
                  children: <Widget>[
                    UTextTitleMedium(priceOf(p, months) == null ? "-" : money(priceOf(p, months)), expanded: 1),
                    if (p.trialDays > 0) AppChip(label: "${p.trialDays.toString().toPersianNumber()} ${U.s.daysFree}", tone: AppTone.positive),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
