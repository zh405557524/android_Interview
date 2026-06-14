part of 'index.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : Get.put(MainController(), permanent: true);
    if (Get.isRegistered<AppUpdateService>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          unawaited(Get.find<AppUpdateService>().checkAfterStartup(context));
        }
      });
    }

    return Obx(
      () => CustomScaffold(
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            HomePage(),
            KnowledgePage(),
            MockInterviewPage(),
            OfferProfilePage(),
          ],
        ),
        bottomNavigationBar: _MainBottomNav(controller: controller),
      ),
    );
  }
}

class _MainBottomNav extends StatelessWidget {
  const _MainBottomNav({required this.controller});

  final MainController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DecoratedBox(
        decoration: BoxDecoration(
          color: CustomTheme.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.changeTab,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedFontSize: 12.sp,
            unselectedFontSize: 12.sp,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.space_dashboard_outlined),
                activeIcon: Icon(Icons.space_dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'Knowledge',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.record_voice_over_outlined),
                activeIcon: Icon(Icons.record_voice_over_rounded),
                label: 'Mock',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
