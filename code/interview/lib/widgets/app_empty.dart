part of 'index.dart';

class AppEmpty extends StatelessWidget {
  const AppEmpty({super.key, this.message = '暂无内容', this.action});

  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.iconNoRecord,
            width: 50.r,
            height: 50.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          if (action != null) ...[SizedBox(height: 16.h), action!],
        ],
      ),
    );
  }
}
