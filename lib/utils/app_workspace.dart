import "package:khabroom/main.dart";
import "package:u/utilities.dart";

/// The three kinds of place a business can run. Each has its own colour so people always know where they are.
enum AppKind {
  dorm(Color(0xFFB4553A), Color(0xFFF6E9E3), Icons.bedroom_parent_outlined),
  hotel(Color(0xFF2F5A86), Color(0xFFE6EEF6), Icons.apartment_outlined),
  cafe(Color(0xFF1F5C41), Color(0xFFE8EFE9), Icons.local_cafe_outlined);

  const AppKind(this.color, this.tint, this.icon);

  final Color color;
  final Color tint;
  final IconData icon;

  String get title => switch (this) {
    AppKind.dorm => U.s.dorm,
    AppKind.hotel => U.s.hotel,
    AppKind.cafe => U.s.cafe,
  };

  TagModule get module => switch (this) {
    AppKind.dorm => TagModule.dorm,
    AppKind.hotel => TagModule.hotel,
    AppKind.cafe => TagModule.cafe,
  };

  TagUser get managePermission => switch (this) {
    AppKind.dorm => TagUser.permissionManageDorms,
    AppKind.hotel => TagUser.permissionManageHotels,
    AppKind.cafe => TagUser.permissionManageCafes,
  };

  List<TagUser> get permissions => switch (this) {
    AppKind.dorm => TagUser.dormPermissions,
    AppKind.hotel => TagUser.hotelPermissions,
    AppKind.cafe => TagUser.cafePermissions,
  };

  /// The app's theme with this kind's colour, so a place's pages read as one space.
  ThemeData theme(BuildContext context) {
    final ThemeData base = Theme.of(context);
    final bool dark = base.brightness == Brightness.dark;
    final Color primary = dark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: primary, primaryContainer: dark ? color.withValues(alpha: 0.25) : tint, onPrimaryContainer: dark ? primary : color),
      elevatedButtonTheme: ElevatedButtonThemeData(style: base.elevatedButtonTheme.style?.copyWith(backgroundColor: WidgetStatePropertyAll<Color>(primary))),
    );
  }
}

/// One hotel, dorm or café of a business, as the business pages need it.
class AppPlace {
  AppPlace({required this.id, required this.kind, required this.title, required this.tags, this.cityCode, this.address, this.menuId, this.hotel, this.dorm, this.cafe});

  final String id;
  final AppKind kind;
  final String title;
  final List<int> tags;
  final String? cityCode;
  final String? address;
  final String? menuId;
  final UHotelResponse? hotel;
  final UDormResponse? dorm;
  final UCafeResponse? cafe;

  bool get approved => tags.contains(TagHotel.approved.number);

  bool get pending => tags.contains(TagHotel.pendingApproval.number);

  bool get rejected => tags.contains(TagHotel.rejected.number);

  bool get active => tags.contains(TagHotel.active.number);
}

/// The businesses the signed-in user owns or works in, and the one they are working in right now.
abstract class AppWorkspace {
  static List<UOrganizationResponse> organizations = <UOrganizationResponse>[];
  static final URx<UOrganizationResponse?> current = URx<UOrganizationResponse?>(null);
  static List<AppPlace> places = <AppPlace>[];
  static const String _lastKey = "appWorkspace";

  static bool get isBusiness => current.value != null;

  static UOrganizationResponse get org => current.value!;

  static Future<void> load() async {
    organizations = (await UServices.organization.readOrganizations(p: UOrganizationReadParams(mine: true, pageSize: 100, pageNumber: 1))).$1?.result ?? <UOrganizationResponse>[];
    final String? last = ULocalStorage.getString(_lastKey);
    final UOrganizationResponse? keep = organizations.where((UOrganizationResponse o) => o.id == (current.value?.id ?? last)).firstOrNull;
    current(keep);
    if (keep != null) await loadPlaces();
  }

  static void clear() {
    organizations = <UOrganizationResponse>[];
    places = <AppPlace>[];
    current(null);
  }

  static Future<void> open(UOrganizationResponse? o) async {
    ULocalStorage.set(_lastKey, o?.id ?? "");
    places = <AppPlace>[];
    current(o);
    if (o != null) await loadPlaces();
  }

  static Future<void> refresh() async {
    final String? id = current.value?.id;
    await load();
    if (id != null && current.value == null) current(organizations.where((UOrganizationResponse o) => o.id == id).firstOrNull);
  }

  static Future<void> loadPlaces() async {
    final String? id = current.value?.id;
    if (id == null) return;
    final List<UHotelResponse> hotels = (await UServices.hotel.readHotels(p: UHotelReadParams(organizationId: id, manage: true, pageSize: 100, pageNumber: 1))).$1?.result ?? <UHotelResponse>[];
    final List<UDormResponse> dorms = (await UServices.dorm.readDorms(p: UDormReadParams(organizationId: id, manage: true, pageSize: 100, pageNumber: 1))).$1?.result ?? <UDormResponse>[];
    final List<UCafeResponse> cafes = (await UServices.cafe.readCafes(p: UCafeReadParams(organizationId: id, manage: true, pageSize: 100, pageNumber: 1))).$1?.result ?? <UCafeResponse>[];
    places = <AppPlace>[
      for (final UDormResponse d in dorms) AppPlace(id: d.id, kind: AppKind.dorm, title: d.title, tags: d.tags, cityCode: d.cityCode, address: d.address, dorm: d),
      for (final UHotelResponse h in hotels) AppPlace(id: h.id, kind: AppKind.hotel, title: h.title, tags: h.tags, cityCode: h.cityCode, address: h.address, hotel: h),
      for (final UCafeResponse c in cafes) AppPlace(id: c.id, kind: AppKind.cafe, title: c.title, tags: c.tags, cityCode: c.cityCode, address: c.address, menuId: c.menuId, cafe: c),
    ];
  }

  static bool isOwnerOf(UOrganizationResponse o) => o.ownerId == U.user.id;

  static bool get isOwner => current.value != null && isOwnerOf(current.value!);

  static UOrganizationMember? memberOf(UOrganizationResponse o) => o.jsonData.members.where((UOrganizationMember m) => m.userId == U.user.id).firstOrNull;

  static bool hasModule(TagModule m) => current.value?.hasModule(m) ?? false;

  /// Owners can do everything their plan allows; staff only what the owner gave them, here or for one place.
  static bool can(TagUser permission, {String? placeId}) {
    final UOrganizationResponse? o = current.value;
    if (o == null) return false;
    if (isOwnerOf(o)) return true;
    return memberOf(o)?.can(permission, placeId: placeId) ?? false;
  }

  static bool canAny(List<TagUser> permissions, {String? placeId}) => permissions.any((TagUser p) => can(p, placeId: placeId));

  static List<AppPlace> placesOf(AppKind kind) => places.where((AppPlace p) => p.kind == kind).toList();

  /// The places this person may work in: all of them for the owner, only the assigned ones for staff.
  static List<AppPlace> get myPlaces => places.where((AppPlace p) => isOwner || canAny(p.kind.permissions, placeId: p.id)).toList();

  static String roleOf(UOrganizationResponse o) => isOwnerOf(o) ? U.s.owner : roleOfMember(memberOf(o));

  static String roleOfMember(UOrganizationMember? m) {
    if (m == null) return U.s.staff;
    if (m.can(TagUser.permissionManageAccounting) || m.can(TagUser.permissionViewAccounting)) return U.s.accountant;
    if (m.can(TagUser.permissionManageReservations)) return U.s.reception;
    if (m.can(TagUser.permissionManageOrders)) return U.s.cashier;
    if (m.can(TagUser.permissionManageInventory)) return U.s.storekeeper;
    return U.s.staff;
  }

  static AppKind kindOf(UOrganizationResponse o) {
    final List<int> modules = o.modules ?? <int>[];
    if (modules.contains(TagModule.dorm.number)) return AppKind.dorm;
    if (modules.contains(TagModule.hotel.number)) return AppKind.hotel;
    if (modules.contains(TagModule.cafe.number)) return AppKind.cafe;
    return AppKind.dorm;
  }

  static Color get color => current.value == null ? AppColors.brand : kindOf(current.value!).color;
}
