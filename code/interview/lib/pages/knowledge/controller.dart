part of 'index.dart';

final class KnowledgeController extends GetxController {
  KnowledgeController({this.initialCategoryId});

  /// Optional category id loaded when the page is opened from a category card.
  final String? initialCategoryId;

  /// Current page state for category list or category detail.
  final Rx<ViewState> state = ViewState.loading.obs;

  /// Category list used by the root knowledge map.
  final RxList<KnowledgeCategory> categories = <KnowledgeCategory>[].obs;

  /// Current category detail when `initialCategoryId` is provided.
  final Rxn<KnowledgeCategoryDetail> detail = Rxn<KnowledgeCategoryDetail>();

  bool get isDetailMode => initialCategoryId?.isNotEmpty ?? false;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// Loads either all categories or the selected category detail.
  Future<void> load() async {
    state.value = ViewState.loading;
    try {
      if (isDetailMode) {
        detail.value = await OfferHunterAPI.categoryDetail(initialCategoryId!);
      } else {
        categories.assignAll(await OfferHunterAPI.categories());
      }
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Knowledge loading failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Opens a category detail page.
  void openCategory(BuildContext context, KnowledgeCategory category) {
    context.pushNamed(
      RouteName.knowledgeCategory,
      pathParameters: <String, String>{'id': category.categoryId},
    );
  }

  /// Opens the article-style detail for a knowledge point.
  void openPoint(BuildContext context, KnowledgePointItem point) {
    context.pushNamed(
      RouteName.knowledgePoint,
      pathParameters: <String, String>{'id': point.pointId},
    );
  }
}
