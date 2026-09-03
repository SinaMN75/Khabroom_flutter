import "package:khabroom/view/pages/login/login_mobile/login_mobile_page.dart";
import "package:khabroom/view/pages/splash/splash_page.dart";
import "package:u/utilities.dart";

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
}

Future<void> main() async {
  if (kDebugMode) HttpOverrides.global = MyHttpOverrides();
  await initU(
    baseUrl: AppConstants.baseUrl,
    apiKey: AppConstants.apiKey,
  );
  UHttpClient.onAuthFailed = () async {
    UToast.error(message: U.s.yourSessionHasExpiredPleaseSignInAgain);
    await UNavigator.offAll(const LoginMobilePage());
  };
  String? locale = ULocalStorage.getString(UConstants.locale);
  if (locale == null) {
    ULocalStorage.setLocale("fa");
    locale = "fa";
  }
  runApp(
    UMaterialApp(
      locale: Locale(locale),
      lightThemeData: Core.lightThemeData,
      darkThemeData: Core.darkThemeData,
      home: const SplashPage(),
    ),
  );
}

abstract class AppColors {
  static const Color brand = Color(0xFFB4553A);
  static const Color brandDark = Color(0xFF8E3F29);
  static const Color brandTint = Color(0xFFF6E9E3);
  static const Color ink = Color(0xFF2A211C);
  static const Color muted = Color(0xFF8A7C73);
  static const Color sand = Color(0xFFFAF6F0);
  static const Color sandDeep = Color(0xFFF1E7DC);
  static const Color outline = Color(0xFFE8DFD5);
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFC8892F);
  static const Color danger = Color(0xFFC0432E);
  static const Color onGradient = Colors.white;
  static const List<Color> gradient = <Color>[Color(0xFFB4553A), Color(0xFFD08A62)];
}

abstract class Core {
  static final ThemeData lightThemeData = _buildTheme(
    background: AppColors.sand,
    scheme: ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      primary: AppColors.brand,
      surface: Colors.white,
    ).copyWith(onSurface: AppColors.ink, onSurfaceVariant: AppColors.muted, outlineVariant: AppColors.outline, onPrimary: Colors.white, error: AppColors.danger, surfaceContainer: AppColors.sandDeep, primaryContainer: AppColors.brandTint, onPrimaryContainer: AppColors.brandDark),
  );

  static final ThemeData darkThemeData = _buildTheme(
    background: const Color(0xFF15110F),
    scheme: ColorScheme.fromSeed(
      brightness: Brightness.dark,
      seedColor: AppColors.brand,
      primary: const Color(0xFFE29377),
      surface: const Color(0xFF211A16),
    ).copyWith(onSurface: const Color(0xFFEDE4D8), onSurfaceVariant: const Color(0xFFA2948A), outlineVariant: const Color(0xFF3A2E27), onPrimary: const Color(0xFF2A211C), error: const Color(0xFFE0705A), surfaceContainer: const Color(0xFF1B1512), primaryContainer: const Color(0xFF3A2620), onPrimaryContainer: const Color(0xFFE29377)),
  );

  static ThemeData _buildTheme({required ColorScheme scheme, required Color background}) => ThemeData(
    brightness: scheme.brightness,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: scheme.onSurface),
      titleTextStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 0, thickness: 1),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      surfaceTintColor: scheme.surface,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    colorScheme: scheme,
    fontFamily: UFonts.vazir.fontFamily,
    textTheme: TextTheme(
      displayLarge: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: -0.6, color: scheme.onSurface),
      displayMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: scheme.onSurface),
      displaySmall: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, letterSpacing: -0.4, color: scheme.onSurface),
      headlineLarge: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, letterSpacing: -0.4, color: scheme.onSurface),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3, color: scheme.onSurface),
      headlineSmall: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: scheme.onSurface),
      titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: scheme.onSurface),
      bodyLarge: TextStyle(fontSize: 14, height: 1.8, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 13, height: 1.8, fontWeight: FontWeight.w400, color: scheme.onSurface),
      bodySmall: TextStyle(fontSize: 11.5, height: 1.9, fontWeight: FontWeight.w400, color: scheme.onSurfaceVariant),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: scheme.onSurface),
      labelMedium: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: scheme.onSurface),
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.error, width: 1.2),
      ),
      outlineBorder: const BorderSide(color: Colors.transparent),
      labelStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.onSurfaceVariant, fontSize: 12),
      hintStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, color: scheme.onSurfaceVariant, fontSize: 13),
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: scheme.onPrimary,
        textStyle: TextStyle(fontFamily: UFonts.vazir.fontFamily, fontSize: 14.5, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        backgroundColor: scheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 8)),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actionsPadding: EdgeInsets.zero,
    ),
  );
}

abstract class AppConstants {
  static const String appName = "خوابروم";
  static const String baseUrl = "https://api.sinamn75.com/api";
  static const String apiKey = "123";
  static const String termsUrl = "https://khabroom.com/terms";
  static const String privacyUrl = "https://khabroom.com/privacy";

  /// Prices and wallet balances are stored in Rial; the app shows Toman everywhere.
  static const bool amountsAreRial = true;
}

/// Single place that turns a stored amount into the text the user reads.
String money(double? amount) => AppConstants.amountsAreRial ? amount.rial() : amount.toman();

abstract class AppImages {
  static const String _base = "lib/assets/images";
  static const String logo = "$_base/logo.png";
  static const String logoLauncher = "$_base/logo_launcher.png";
}

abstract class AppIcons {
  static const String _base = "lib/assets/icons";
  static const String profile = "$_base/profile.svg";
}
