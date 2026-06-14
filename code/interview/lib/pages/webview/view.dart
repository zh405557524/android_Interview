part of 'index.dart';

class StaticPageView extends StatefulWidget {
  const StaticPageView({required this.pageKey, super.key});

  final String pageKey;

  @override
  State<StaticPageView> createState() => _StaticPageViewState();
}

class _StaticPageViewState extends State<StaticPageView> {
  late final StaticPageController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(
      StaticPageController(pageKey: widget.pageKey),
      tag: widget.pageKey,
    );
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller, tag: widget.pageKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          tooltip: '返回',
        ),
        title: Obx(
          () => Text(
            controller.title,
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: controller.webViewController),
              Obx(() {
                final error = controller.errorMessage.value;
                if (error == null) {
                  return const SizedBox.shrink();
                }
                return ColoredBox(
                  color: Colors.white,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14.sp,
                              height: 1.5,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          TextButton(
                            onPressed: controller.reload,
                            child: const Text('重新加载'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              Obx(() {
                if (!controller.loading.value) {
                  return const SizedBox.shrink();
                }
                return LinearProgressIndicator(
                  minHeight: 2.h,
                  value: controller.progress.value <= 0
                      ? null
                      : controller.progress.value / 100,
                  color: CustomTheme.primary,
                  backgroundColor: Colors.transparent,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
