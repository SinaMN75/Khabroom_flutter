import "package:u/utilities.dart";

class NotificationController extends UBaseController {
  final RxState notificationState = RxState();
  List<UNotificationResponse> notifications = <UNotificationResponse>[];

  Future<void> read() async {
    notificationState.loading();
    await UServices.notification.read(
      p: UNotificationReadParams(userId: U.user.id, pageSize: 50, selectorArgs: const NotificationSelectorArgs()),
      onOk: (UResponse<List<UNotificationResponse>> response) {
        notifications = response.result ?? <UNotificationResponse>[];
        notifications.isEmpty ? notificationState.emptying() : notificationState.loaded();
      },
      onError: (UEmptyResponse response) => notificationState.error(),
      onException: (String exception) => notificationState.error(),
    );
  }
}
