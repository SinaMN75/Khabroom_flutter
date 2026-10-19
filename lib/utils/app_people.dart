import "package:u/utilities.dart";

/// Finds a person by phone number, or makes an account for them so a contract or booking can be made right away.
/// They sign in later with the same number and see everything that was made for them.
abstract class AppPeople {
  static String _normalize(String phone) {
    final String digits = phone.toLatinNumber().replaceAll(RegExp(r"\D"), "");
    return digits.startsWith("98") ? "0${digits.substring(2)}" : digits.startsWith("9") ? "0$digits" : digits;
  }

  static Future<UUserResponse?> find(String phone) async =>
      (await UServices.user.read(p: UUserReadParams(phoneNumber: _normalize(phone), pageSize: 1, pageNumber: 1))).$1?.result?.firstOrNull;

  static Future<String?> findOrCreate({required String phone, String? firstName, String? lastName}) async {
    final UUserResponse? found = await find(phone);
    if (found != null) return found.id;
    final String number = _normalize(phone);
    final (UResponse<String>? ok, UEmptyResponse? error, String? exception) = await UServices.user.create(
      p: UUserCreateParams(userName: number, password: "${number}K${DateTime.now().millisecondsSinceEpoch}", tags: <int>[], phoneNumber: number, firstName: firstName, lastName: lastName),
    );
    if (ok?.result == null) UToast.error(message: error?.message ?? exception ?? U.s.error);
    return ok?.result;
  }
}
