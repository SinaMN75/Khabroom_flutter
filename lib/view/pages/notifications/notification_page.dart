import "package:khabroom/utils/responsive.dart";
import "package:khabroom/view/pages/notifications/notification_controller.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationController c = NotificationController();

  @override
  void initState() {
    c.read();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.notifications)),
    body: RefreshIndicator(
      onRefresh: c.read,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppResponsive.pagePadding(context),
        child: AppContent(
          maxWidth: AppResponsive.readableMaxWidth,
          child: AppStateView(
            state: c.notificationState,
            onRetry: c.read,
            emptyTitle: U.s.noNotifications,
            emptyIcon: Icons.notifications_none_rounded,
            onLoaded: (BuildContext context) => UColumn(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final UNotificationResponse item in c.notifications) _NotificationTile(notification: item).pOnly(bottom: 12),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final UNotificationResponse notification;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String title = notification.jsonData.detail1 ?? U.s.notifications;
    final String body = notification.jsonData.detail2 ?? "";

    return AppCard(
      child: URow(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          UIconBackground(Icons.notifications_none_rounded, color: scheme.primary, size: 38),
          const SizedBox(width: 12),
          UColumn(
            expanded: 1,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              UTextTitleSmall(title, color: scheme.onSurface),
              if (body.isNotEmpty) ...<Widget>[
                const SizedBox(height: 5),
                UTextBodySmall(body, color: scheme.onSurfaceVariant),
              ],
              const SizedBox(height: 6),
              UTextLabelSmall(notification.createdAt.toJalaliDateTime(), color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
