import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/business/more/activity_page.dart";
import "package:khabroom/view/pages/business/more/business_settings_page.dart";
import "package:khabroom/view/pages/business/setup/subscription_page.dart";
import "package:khabroom/view/pages/business/team/shifts_page.dart";
import "package:khabroom/view/pages/business/team/tasks_page.dart";
import "package:khabroom/view/pages/workspace/workspace_sheet.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Everything else: the storeroom, my tasks and shifts, activity, the business's details and its subscription.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool owner = AppWorkspace.isOwner;
    return UScaffold(
      appBar: businessAppBar(context, U.s.more, help: "app.more.page"),
      body: AppPageBody(
        children: <Widget>[
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                AppTile(icon: Icons.task_alt_rounded, title: U.s.myTasks, onTap: () => UNavigator.push(const TasksPage(mine: true))),
                AppTile(icon: Icons.schedule_outlined, title: U.s.myShifts, onTap: () => UNavigator.push(const ShiftsPage())),
                if (owner || AppWorkspace.can(TagUser.permissionManageStaff)) AppTile(icon: Icons.history_rounded, title: U.s.activity, subtitle: U.s.whoDidWhat, onTap: () => UNavigator.push(const ActivityPage())),
              ],
            ),
          ).help("app.more.work"),
          if (owner) ...<Widget>[
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: UColumn(
                children: <Widget>[
                  AppTile(icon: Icons.storefront_outlined, title: U.s.businessDetails, subtitle: U.s.nameBankAccountAndTax, onTap: () => UNavigator.push(const BusinessSettingsPage())),
                  AppTile(icon: Icons.workspace_premium_outlined, title: U.s.subscription, subtitle: AppWorkspace.org.subscriptionEndsAt == null ? null : "${U.s.endsOn} ${AppWorkspace.org.subscriptionEndsAt!.toJalaliDate().toPersianNumber()}", onTap: () => UNavigator.push(const SubscriptionPage())),
                ],
              ),
            ).help("app.more.owner"),
          ],
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: UColumn(
              children: <Widget>[
                AppTile(icon: Icons.swap_horiz_rounded, title: U.s.whereDoYouWantToWork, subtitle: U.s.switchBetweenYourAccountAndYourBusinesses, onTap: WorkspaceSheet.show),
                AppTile(icon: Icons.dark_mode_outlined, title: U.s.theme, onTap: () => UApp.isDarkTheme() ? UApp.toLightMode() : UApp.toDarkMode()),
                UObx(() => SwitchListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 4), secondary: const Icon(Icons.help_outline_rounded), value: UHelp.enabled.value, onChanged: (_) => UHelp.toggle(), title: Text(U.s.helpMode))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
