import "package:u/utilities.dart";

class DormDetailController extends UBaseController {
  final RxState detailState = RxState();

  late String dormId;
  UDormResponse? dorm;

  Future<void> init({required String dormId}) async {
    this.dormId = dormId;
    await read();
  }

  Future<void> read() async {
    detailState.loading();
    await UServices.hotel.readDormById(
      p: UIdParams(
        id: dormId,
        selectorArgs: const DormSelectorArgs(
          media: MediaSelectorArgs(),
          rooms: DormRoomSelectorArgs(beds: DormBedSelectorArgs(), media: MediaSelectorArgs()),
          comments: CommentSelectorArgs(user: UserSelectorArgs()),
        ),
      ),
      onOk: (UResponse<UDormResponse> response) {
        dorm = response.result;
        detailState.loaded();
      },
      onError: (UEmptyResponse response) => detailState.error(),
      onException: (String exception) => detailState.error(),
    );
  }
}
