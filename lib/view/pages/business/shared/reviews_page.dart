import "package:khabroom/utils/app_workspace.dart";
import "package:khabroom/view/widgets/app_kit.dart";
import "package:khabroom/view/widgets/app_widgets.dart";
import "package:u/utilities.dart";

/// What customers wrote about a place, with a reply under each review.
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({required this.place, super.key});

  final AppPlace place;

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final URxState state = URxState();
  List<UCommentResponse> list = <UCommentResponse>[];

  String? get hotelId => widget.place.kind == AppKind.hotel ? widget.place.id : null;

  String? get dormId => widget.place.kind == AppKind.dorm ? widget.place.id : null;


  @override
  void initState() {
    read();
    super.initState();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  Future<void> read() async {
    state.loading();
    final UResponse<List<UCommentResponse>>? r = (await UServices.comment.read(
      p: UCommentReadParams(hotelId: hotelId, dormId: dormId, pageSize: 100, pageNumber: 1, selectorArgs: const UCommentSelectorArgs(creator: UUserSelectorArgs(), children: UCommentSelectorArgs())),
    )).$1;
    if (r == null) {
      state.error();
      return;
    }
    list = (r.result ?? <UCommentResponse>[]).where((UCommentResponse c) => c.parentId == null).toList();
    if (mounted) setState(() {});
    list.isEmpty ? state.emptying() : state.loaded();
  }

  Future<void> _reply(UCommentResponse c) async {
    final TextEditingController text = TextEditingController();
    final bool ok = await AppForm.show(
      title: U.s.reply,
      onSubmit: () => appSend(UServices.comment.create(p: UCommentCreateParams(description: text.text.trim(), score: 0, parentId: c.id, hotelId: hotelId, dormId: dormId, tags: <int>[TagComment.values.first.number]))),
      children: (BuildContext context, StateSetter setState) => <Widget>[UTextField(controller: text, labelText: U.s.yourReply, lines: 3, validator: UValidators.required<String>())],
    );
    text.dispose();
    if (ok) await read();
  }

  @override
  Widget build(BuildContext context) => UScaffold(
    appBar: AppBar(title: Text(U.s.reviews).help("app.reviews.page", inline: true)),
    body: AppStateView(
      state: state,
      onRetry: read,
      emptyTitle: U.s.noReviewsYet,
      emptyIcon: Icons.rate_review_outlined,
      onLoaded: (BuildContext context) => AppPageBody(
        onRefresh: read,
        maxWidth: 760,
        children: <Widget>[
          for (final UCommentResponse c in list)
            AppCard(
              child: UColumn(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  URow(
                    children: <Widget>[
                      UTextTitleSmall("${c.creator?.firstName ?? ""} ${c.creator?.lastName ?? ""}".trim(), expanded: 1),
                      AppRating(score: c.score, count: 1, compact: true),
                    ],
                  ),
                  UTextBodyMedium(c.description),
                  for (final UCommentResponse r in c.children ?? <UCommentResponse>[])
                    UContainer(radius: 12, color: Theme.of(context).colorScheme.primaryContainer, padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(top: 8), child: UTextBodySmall(r.description)),
                  Align(alignment: AlignmentDirectional.centerEnd, child: UButton(title: U.s.reply, type: UButtonType.text, onTap: () => _reply(c))),
                ],
              ),
            ).pOnly(bottom: 10),
        ],
      ),
    ),
  );
}
