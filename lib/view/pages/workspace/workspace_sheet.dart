import "package:khabroom/main.dart";
import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/setup/create_business_page.dart";
import "package:khabroom/view/pages/main/main_page.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:u/utilities.dart";

/// "Where do you want to work?" — the personal account and every business the user owns or works in.
class WorkspaceSheet extends StatelessWidget {
  const WorkspaceSheet({super.key});

  static Future<void> show() => AppSession.require(() async {
    ULoading.show();
    await AppWorkspace.load();
    ULoading.dismiss();
    await UNavigator.bottomSheet<void>(const WorkspaceSheet());
  });

  static Future<void> _open(UOrganizationResponse? o) async {
    UNavigator.back();
    await enter(o);
  }

  /// Switches to [o] (null = the personal account) and opens its home.
  static Future<void> enter(UOrganizationResponse? o) async {
    ULoading.show();
    await AppWorkspace.open(o);
    ULoading.dismiss();
    await UNavigator.offAll(o == null ? const MainPage() : const BusinessPage());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? current = AppWorkspace.current.value?.id;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          UTextTitleLarge(U.s.whereDoYouWantToWork).help("app.workspace.page", inline: true).pSymmetric(horizontal: 4),
          const SizedBox(height: 12),
          _item(
            context,
            icon: Icons.person_outline_rounded,
            color: AppColors.brand,
            title: U.s.myPersonalAccount,
            subtitle: U.s.myStaysPaymentsAndOrders,
            selected: current == null,
            onTap: () => _open(null),
          ),
          for (final UOrganizationResponse o in AppWorkspace.organizations)
            _item(
              context,
              icon: AppWorkspace.kindOf(o).icon,
              color: AppWorkspace.kindOf(o).color,
              title: o.title,
              subtitle: AppWorkspace.roleOf(o),
              selected: current == o.id,
              onTap: () => _open(o),
            ),
          const SizedBox(height: 6),
          AppTile(
            icon: Icons.add_business_outlined,
            iconColor: scheme.onSurfaceVariant,
            title: U.s.newBusiness,
            subtitle: U.s.dormOrHotelStartWithAFreeTrial,
            onTap: () {
              UNavigator.back();
              UNavigator.push(const CreateBusinessPage());
            },
          ).help("app.workspace.create"),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, {required IconData icon, required Color color, required String title, required String subtitle, required bool selected, required VoidCallback onTap}) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return UContainer(
      margin: const EdgeInsets.only(bottom: 8),
      radius: 16,
      color: selected ? color.withValues(alpha: 0.08) : scheme.surface,
      border: Border.all(color: selected ? color : scheme.outlineVariant),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AppTile(icon: icon, iconColor: color, title: title, subtitle: subtitle, onTap: onTap, trailing: selected ? Icon(Icons.check_circle_rounded, color: color) : null),
    );
  }
}
