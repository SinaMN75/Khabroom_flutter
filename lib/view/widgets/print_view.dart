import "package:u/utilities.dart";

abstract final class AppPrint {
  static Future<void> show(Future<(UResponse<String>?, UEmptyResponse?, String?)> call) async {
    ULoading.show();
    final (UResponse<String>? r, UEmptyResponse? e, String? x) = await call;
    ULoading.dismiss();
    final String? html = r?.result;
    if (html == null) {
      UToast.error(message: e?.message.nullIfEmpty() ?? x.nullIfEmpty() ?? U.s.errorSubmittingForm);
      return;
    }
    await UNavigator.push(
      UScaffold(
        appBar: AppBar(title: Text(U.s.print)),
        body: UWebView(initialUrl: Uri.dataFromString(html, mimeType: "text/html", encoding: utf8).toString()),
      ),
    );
  }
}
