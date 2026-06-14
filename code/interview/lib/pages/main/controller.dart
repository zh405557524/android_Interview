part of 'index.dart';

final class MainController extends GetxController {
  static const int _homeTabIndex = 0;
  static const int _knowledgeTabIndex = 1;
  static const int _mockTabIndex = 2;
  static const int _profileTabIndex = 3;

  /// Currently selected bottom navigation tab.
  final RxInt currentIndex = _homeTabIndex.obs;

  /// Switches the visible Offer Hunter tab.
  void changeTab(int index) {
    currentIndex.value = index.clamp(_homeTabIndex, _profileTabIndex).toInt();
  }

  /// Jumps back to the home tab after a cross-page action.
  void showHomeTab() {
    changeTab(_homeTabIndex);
  }

  /// Opens the knowledge map tab.
  void showKnowledgeTab() {
    changeTab(_knowledgeTabIndex);
  }

  /// Opens the mock interview tab.
  void showMockTab() {
    changeTab(_mockTabIndex);
  }

  /// Opens the profile tab.
  void showProfileTab() {
    changeTab(_profileTabIndex);
  }
}
