import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/places/place_form.dart";
import "package:khabroom/view/pages/business/places/place_home_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// The business's dorms, hotels and cafés. The owner adds new ones here; they show to customers after the platform approves them.
class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  final URxState state = URxState();

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
    await AppWorkspace.loadPlaces();
    if (mounted) setState(() {});
    AppWorkspace.myPlaces.isEmpty ? state.emptying() : state.loaded();
  }

  List<AppKind> get _addable => AppKind.values.where((AppKind k) => AppWorkspace.isOwner && AppWorkspace.hasModule(k.module)).toList();

  Future<void> _add() async {
    final List<AppKind> kinds = _addable;
    if (kinds.isEmpty) {
      UToast.error(message: U.s.yourPlanDoesNotIncludeAnyPlaceType);
      return;
    }
    final AppKind? kind = kinds.length == 1
        ? kinds.first
        : await UNavigator.bottomSheet<AppKind>(
            SafeArea(
              child: UColumn(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[for (final AppKind k in kinds) AppTile(icon: k.icon, iconColor: k.color, title: k.title, onTap: () => UNavigator.back(k)).pSymmetric(horizontal: 16)],
              ),
            ),
          );
    if (kind == null) return;
    if (await PlaceForm.show(kind)) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: businessAppBar(context, U.s.places, help: "app.places.page"),
    floatingActionButton: _addable.isEmpty ? null : FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_business_outlined), label: Text(U.s.newPlace)).help("app.places.add"),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: AppWorkspace.isOwner ? U.s.addYourFirstPlace : U.s.theOwnerHasNotGivenYouAccessToAnyPlaceYet,
      emptyIcon: Icons.storefront_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        children: <Widget>[
          for (final AppKind kind in AppKind.values)
            if (AppWorkspace.myPlaces.any((AppPlace p) => p.kind == kind)) ...<Widget>[
              AppLabel(kind.title),
              for (final AppPlace p in AppWorkspace.myPlaces.where((AppPlace p) => p.kind == kind))
                Theme(
                  data: kind.theme(context),
                  child: Builder(
                    builder: (BuildContext context) => AppCard(
                      onTap: () => UNavigator.push(PlaceHomePage(place: p)).then((_) => read()),
                      child: AppTile(
                        icon: kind.icon,
                        title: p.title,
                        subtitle: p.address ?? UCountries.cityFullName(p.cityCode ?? "") ?? "",
                        trailing: AppChip(
                          label: p.pending ? U.s.inReview : p.rejected ? U.s.notApproved : p.active ? U.s.visible : U.s.hidden,
                          tone: p.pending ? AppTone.warning : p.rejected ? AppTone.danger : p.active ? AppTone.positive : AppTone.neutral,
                        ),
                      ),
                    ).pOnly(bottom: 10),
                  ),
                ),
            ],
          if (AppWorkspace.myPlaces.any((AppPlace p) => p.pending))
            UTextBodySmall(U.s.newPlacesAreShownToCustomersAfterKhabroomApprovesThem, color: Theme.of(context).colorScheme.onSurfaceVariant, textAlign: TextAlign.center).pOnly(top: 8),
        ],
      ),
    ),
  );
}
