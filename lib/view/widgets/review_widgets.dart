import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// Reviews block shared by the hotel and dorm pages: the list plus the "write one" sheet.
class ReviewSection extends StatelessWidget {
  const ReviewSection({required this.comments, required this.onSubmitted, super.key, this.hotelId, this.dormId});

  final List<UCommentResponse> comments;
  final Future<void> Function() onSubmitted;
  final String? hotelId;
  final String? dormId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppSectionHeader(
            title: U.s.reviews,
            actionTitle: U.s.writeAReview,
            onAction: () => openReviewSheet(context, hotelId: hotelId, dormId: dormId, onSubmitted: onSubmitted),
          ),
          const SizedBox(height: 12),
          if (comments.isEmpty)
            UTextBodySmall(U.s.noReviewsYet, color: scheme.onSurfaceVariant)
          else
            for (final UCommentResponse comment in comments) _ReviewTile(comment: comment),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.comment});

  final UCommentResponse comment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String name = <String?>[comment.creator?.firstName, comment.creator?.lastName].whereType<String>().join(" ").trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: UColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          URow(
            children: <Widget>[
              UTextTitleSmall(name.isEmpty ? U.s.user : name, color: scheme.onSurface, expanded: 1),
              AppRating(score: comment.score, count: 1, compact: true),
            ],
          ),
          const SizedBox(height: 6),
          UTextBodyMedium(comment.description, color: scheme.onSurfaceVariant),
          const SizedBox(height: 6),
          UTextLabelSmall(comment.createdAt.toJalaliDate(), color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

Future<void> openReviewSheet(
  BuildContext context, {
  required Future<void> Function() onSubmitted,
  String? hotelId,
  String? dormId,
}) async {
  final TextEditingController controller = TextEditingController();
  final RxDouble score = 5.0.obs;

  await UNavigator.bottomSheet(
    StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        final ColorScheme scheme = Theme.of(context).colorScheme;
        return UColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UTextTitleLarge(U.s.writeAReview, color: scheme.onSurface),
            const SizedBox(height: 6),
            UTextBodySmall(U.s.yourReviewHelpsOthers, color: scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            UTextLabelMedium(U.s.yourRating, color: scheme.onSurfaceVariant),
            const SizedBox(height: 8),
            Obx(
              () => URow(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 1; i <= 5; i++)
                    Icon(
                      i <= score.value ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 30,
                      color: scheme.primary,
                    ).pOnly(left: 4).onTap(() => score(i.toDouble())),
                ],
              ),
            ),
            const SizedBox(height: 16),
            UTextField(labelText: U.s.description, controller: controller, lines: 4),
            const SizedBox(height: 16),
            UButton(
              title: U.s.submit,
              fullWidth: true,
              onTap: () async {
                if (controller.text.trim().isEmpty) {
                  UToast.error(message: U.s.thisFieldIsInvalid);
                  return;
                }
                ULoading.show();
                await UServices.comment.create(
                  p: UCommentCreateParams(
                    tags: <int>[],
                    description: controller.text.trim(),
                    score: score.value,
                    hotelId: hotelId,
                    dormId: dormId,
                  ),
                  onOk: (UResponse<String> response) async {
                    ULoading.dismiss();
                    UNavigator.back();
                    UToast.success(message: U.s.thanksForYourReview);
                    await onSubmitted();
                  },
                  onError: (UEmptyResponse response) {
                    ULoading.dismiss();
                    UToast.error(message: response.message);
                  },
                  onException: (String exception) {
                    ULoading.dismiss();
                    UToast.error(message: exception);
                  },
                );
              },
            ),
          ],
        ).pAll(20);
      },
    ),
  );
}
