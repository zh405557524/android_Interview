part of 'index.dart';

final class ConfigStore extends GetxController {
  ConfigStore({
    bool mockEnabled = false,
    String apiBaseUrl = '',
    String appEnvironment = '',
  }) : mockEnabled = mockEnabled.obs,
       apiBaseUrl = apiBaseUrl.trim().obs,
       appEnvironment = appEnvironment.obs;

  final RxBool hasAcceptedAgreement = false.obs;
  final RxBool mockEnabled;
  final RxString apiBaseUrl;
  final RxString appEnvironment;
  final RxString appVersion = '0.0.0'.obs;

  void acceptAgreement(bool value) {
    hasAcceptedAgreement.value = value;
  }

  void setMockEnabled(bool value) {
    mockEnabled.value = value;
  }

  void setApiBaseUrl(String value) {
    apiBaseUrl.value = value.trim();
  }
}
