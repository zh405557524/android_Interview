part of 'index.dart';

final class KnowledgePointController extends GetxController {
  KnowledgePointController({required this.pointId});

  /// Knowledge point id from the route path.
  final String pointId;

  /// Detail page loading state.
  final Rx<ViewState> state = ViewState.loading.obs;

  /// Current knowledge point detail.
  final Rxn<KnowledgePointDetail> detail = Rxn<KnowledgePointDetail>();

  /// Whether the complete action is submitting.
  final RxBool completing = false.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// Loads the knowledge point article and related interview questions.
  Future<void> load() async {
    state.value = ViewState.loading;
    try {
      detail.value = await OfferHunterAPI.pointDetail(pointId);
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Point loading failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Marks the point as completed and refreshes the page state.
  Future<void> complete() async {
    if (completing.value) {
      return;
    }
    completing.value = true;
    try {
      await OfferHunterAPI.completePoint(pointId);
      CustomToast.success('Completed');
      await load();
    } catch (error, stackTrace) {
      CustomToast.error(
        'Complete failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      completing.value = false;
    }
  }
}
