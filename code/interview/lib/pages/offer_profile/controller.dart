part of 'index.dart';

final class OfferProfileController extends GetxController {
  /// Current profile page loading state.
  final Rx<ViewState> state = ViewState.loading.obs;

  /// Offer Hunter profile dashboard for the current user.
  final Rxn<ProfileDashboard> dashboard = Rxn<ProfileDashboard>();

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// Loads profile metrics, achievements, and recent mock sessions.
  Future<void> load() async {
    state.value = ViewState.loading;
    try {
      dashboard.value = await OfferHunterAPI.profileDashboard();
      state.value = ViewState.success;
    } catch (error, stackTrace) {
      CustomToast.error(
        'Profile loading failed',
        error: error,
        stackTrace: stackTrace,
      );
      state.value = ViewState.error;
    }
  }

  /// Opens the existing login page when protected profile APIs need auth.
  void openLogin(BuildContext context) {
    context.pushNamed(RouteName.login);
  }
}
