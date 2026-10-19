import "package:khabroom/main.dart";
import "package:khabroom/view/pages/menu/public_menu_page.dart";
import "package:u/utilities.dart";

/// Opens the camera; a café table's QR code goes straight to that café's menu.
abstract class ScanPage {
  static Future<void> open() async {
    final String? code = await UNavigator.push<String>(UScannerPage(title: U.s.scanTheTableCode, hintText: U.s.pointTheCameraAtTheQrCodeOnTheTable));
    if (code == null || code.isEmpty) return;
    final (String, int?)? link = AppLinks.menuOf(Uri.tryParse(code.trim()) ?? Uri());
    if (link == null) {
      UToast.error(message: U.s.thisCodeIsNotAKhabroomMenu);
      return;
    }
    await UNavigator.push(PublicMenuPage(menuId: link.$1, table: link.$2));
  }
}
