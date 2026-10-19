import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/pages/login/login_sheet.dart";
import "package:u/utilities.dart";

/// Who is using the app: a guest can browse everything public; anything personal asks to sign in first.
abstract class AppSession {
  static final URxBool signedIn = UAuth.isSignedIn.obs;

  static bool get isGuest => !signedIn.value;

  /// Reads the signed-in user (with wallet) and their businesses. Returns false when the session is no longer valid.
  static Future<bool> load() async {
    if (!UAuth.isSignedIn) {
      signedIn(false);
      return true;
    }
    final (UResponse<UUserResponse>? ok, _, _) = await UServices.user.readById(
      p: UIdParams(id: ULocalStorage.getUserId() ?? "", selectorArgs: const UUserSelectorArgs(wallet: UWalletSelectorArgs())),
    );
    if (ok?.result == null) {
      signedIn(false);
      return false;
    }
    U.user = ok!.result!;
    signedIn(true);
    await AppWorkspace.load();
    return true;
  }

  /// Runs [action] right away for a signed-in user; a guest signs in first and then continues where they were.
  static Future<void> require(VoidCallback action) async {
    if (signedIn.value || await LoginSheet.show()) action();
  }

  static Future<void> signOut() async {
    await UAuth.signOut();
    AppWorkspace.clear();
    signedIn(false);
  }
}
