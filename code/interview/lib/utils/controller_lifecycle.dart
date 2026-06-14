part of 'index.dart';

T putFreshController<T extends GetxController>(
  T controller, {
  String? tag,
  bool permanent = false,
}) {
  if (Get.isRegistered<T>(tag: tag)) {
    Get.delete<T>(tag: tag, force: true);
  }
  return Get.put<T>(controller, tag: tag, permanent: permanent);
}

void deleteControllerIfCurrent<T extends GetxController>(
  T controller, {
  String? tag,
}) {
  if (!Get.isRegistered<T>(tag: tag)) {
    return;
  }
  final current = Get.find<T>(tag: tag);
  if (identical(current, controller)) {
    Get.delete<T>(tag: tag, force: true);
  }
}
