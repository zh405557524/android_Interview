part of 'index.dart';

final class HomeController extends GetxController {
  /// Current page loading state for the Offer Hunter home overview.
  final Rx<ViewState> state = ViewState.loading.obs;

  /// Home overview returned by `/api/offer-hunter/home`.
  final Rx<OfferHomeOverview> overview = OfferHomeOverview.empty().obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadHome());
  }

  /// Loads the home dashboard and featured interview content.
  Future<void> loadHome() async {
    state.value = ViewState.loading;
    try {
      overview.value = await OfferHunterAPI.home();
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Home loading failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Navigates from a home category card to the category learning map.
  void openCategory(BuildContext context, KnowledgeCategory category) {
    context.pushNamed(
      RouteName.knowledgeCategory,
      pathParameters: <String, String>{'id': category.categoryId},
    );
  }

  /// Navigates to the main learning map.
  void openKnowledge(BuildContext context) {
    context.pushNamed(RouteName.knowledge);
  }

  /// Navigates to the mock interview workspace.
  void openMock(BuildContext context) {
    context.pushNamed(RouteName.mockInterview);
  }

  /// Navigates to due review and wrong-book practice.
  void openReview(BuildContext context) {
    context.pushNamed(RouteName.review);
  }
}
