import "package:u/utilities.dart";

enum DormServicesTab { notices, meals, laundry, maintenance }

class DormServicesController extends UBaseController {
  final URxState listState = URxState();
  late String dormId;
  List<String> machines = <String>[];
  DormServicesTab tab = DormServicesTab.notices;

  List<UDormRecordResponse> records = <UDormRecordResponse>[];
  List<UDormMealResponse> meals = <UDormMealResponse>[];
  Map<String, String> mealBookings = <String, String>{};
  List<UDormBookingResponse> laundry = <UDormBookingResponse>[];
  List<UStaffTaskResponse> tasks = <UStaffTaskResponse>[];

  Future<void> init(UDormBedContractResponse contract) async {
    dormId = contract.bed?.room?.dorm?.id ?? contract.bed?.room?.dormId ?? "";
    machines = contract.bed?.room?.dorm?.jsonData.laundryMachines ?? <String>[];
    await read();
  }

  Future<void> setTab(DormServicesTab t) async {
    tab = t;
    await read();
  }

  Future<void> read() async {
    listState.loading();
    final DateTime today = DateTime.now().subtract(const Duration(hours: 12));
    switch (tab) {
      case DormServicesTab.notices:
        records = (await UServices.dorm.readRecords(p: UDormRecordReadParams(dormId: dormId, mine: true, pageSize: 50))).$1?.result ?? <UDormRecordResponse>[];
      case DormServicesTab.meals:
        meals = (await UServices.dorm.readMeals(p: UDormMealReadParams(dormId: dormId, fromDate: today, pageSize: 60))).$1?.result ?? <UDormMealResponse>[];
        final List<UDormBookingResponse> mine = (await UServices.dorm.readBookings(p: UDormBookingReadParams(dormId: dormId, mine: true, fromDate: today, pageSize: 100))).$1?.result ?? <UDormBookingResponse>[];
        mealBookings = <String, String>{
          for (final UDormBookingResponse b in mine.where((UDormBookingResponse b) => b.mealId != null && b.tags.contains(TagDormBooking.reserved.number))) b.mealId!: b.id,
        };
      case DormServicesTab.laundry:
        laundry = (await UServices.dorm.readBookings(p: UDormBookingReadParams(dormId: dormId, mine: true, fromDate: today, tags: <int>[TagDormBooking.laundry.number], pageSize: 50))).$1?.result ?? <UDormBookingResponse>[];
      case DormServicesTab.maintenance:
        tasks = (await UServices.organization.readTasks(p: UStaffTaskReadParams(placeId: dormId, mine: true, pageSize: 50))).$1?.result ?? <UStaffTaskResponse>[];
    }
    final bool empty = switch (tab) {
      DormServicesTab.notices => records.isEmpty,
      DormServicesTab.meals => meals.isEmpty,
      DormServicesTab.laundry => laundry.isEmpty,
      DormServicesTab.maintenance => tasks.isEmpty,
    };
    empty ? listState.emptying() : listState.loaded();
  }

  Future<void> _call(Future<(Object?, Object?, String?)> call) async {
    ULoading.show();
    final (Object? ok, Object? error, String? exception) = await call;
    ULoading.dismiss();
    if (ok == null) {
      UToast.error(message: (error is UEmptyResponse ? error.message : null).nullIfEmpty() ?? exception.nullIfEmpty() ?? U.s.errorSubmittingForm);
      return;
    }
    UToast.success(message: U.s.submitted);
    await read();
  }

  Future<void> reserveMeal(UDormMealResponse m) => _call(UServices.dorm.createBooking(p: UDormBookingCreateParams(dormId: dormId, mealId: m.id, tags: <int>[TagDormBooking.meal.number])));

  Future<void> cancelBooking(String id) => _call(UServices.dorm.cancelBooking(p: UIdParams(id: id)));

  Future<void> bookLaundry(String? machine, DateTime at) =>
      _call(UServices.dorm.createBooking(p: UDormBookingCreateParams(dormId: dormId, startAt: at, resource: machine, tags: <int>[TagDormBooking.laundry.number])));

  Future<void> request(TagDormRecord kind, String title, DateTime? from, DateTime? to, String? visitor, String? note) => _call(
    UServices.dorm.createRecord(p: UDormRecordCreateParams(dormId: dormId, title: title, tags: <int>[kind.number], date: from, endDate: to, visitorName: visitor, body: note)),
  );

  Future<void> maintenance(String title, String? description, bool urgent) => _call(
    UServices.organization.createTask(
      p: UStaffTaskCreateParams(placeId: dormId, title: title, description: description, tags: <int>[(urgent ? TagStaffTask.urgent : TagStaffTask.normal).number]),
    ),
  );
}
