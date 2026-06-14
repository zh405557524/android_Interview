part of 'index.dart';

final class CreationStore extends GetxController {
  final RxList<String> selectedMaterialIds = <String>[].obs;
  final RxString selectedStyleId = 'style_fast'.obs;
  final RxString selectedVoiceRoleId = 'voice_male_01'.obs;
  final RxString selectedEmotion = '通用'.obs;
  final RxDouble speed = 1.0.obs;
  final RxBool diversifiedVersionsEnabled = false.obs;

  void clearDraft() {
    selectedMaterialIds.clear();
    selectedStyleId.value = 'style_fast';
    selectedVoiceRoleId.value = 'voice_male_01';
    selectedEmotion.value = '通用';
    speed.value = 1.0;
    diversifiedVersionsEnabled.value = false;
  }
}
