import "package:khabroom/utils/app_session.dart";
import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/business/business_page.dart";
import "package:khabroom/view/pages/main/main_page.dart";
import "package:u/utilities.dart";

class SplashController extends UBaseController {
  Future<void> init() async => delay(700, () async {
    if (!await AppSession.load()) await AppSession.signOut();
    await UNavigator.offAll(AppWorkspace.isBusiness ? const BusinessPage() : const MainPage());
  });
}
