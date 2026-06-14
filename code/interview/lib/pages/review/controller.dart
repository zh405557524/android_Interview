part of 'index.dart';

final class ReviewController extends GetxController {
  /// Current review page loading state.
  final Rx<ViewState> state = ViewState.loading.obs;

  /// Today's due review queue.
  final Rxn<TodayReview> review = Rxn<TodayReview>();

  /// Wrong-book question list.
  final Rxn<WrongBook> wrongBook = Rxn<WrongBook>();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// Loads review queue and wrong-book content.
  Future<void> load() async {
    state.value = ViewState.loading;
    try {
      final results = await Future.wait<Object>([
        OfferHunterAPI.todayReview(),
        OfferHunterAPI.wrongBook(),
      ]);
      review.value = results[0] as TodayReview;
      wrongBook.value = results[1] as WrongBook;
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Review loading failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Sends spaced-repetition feedback for one review card.
  Future<void> submitFeedback(ReviewItem item, String result) async {
    try {
      await OfferHunterAPI.submitReviewFeedback(item.reviewItemId, result);
      CustomToast.success('Saved');
      await load();
    } catch (error, stackTrace) {
      CustomToast.error(
        'Feedback failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
