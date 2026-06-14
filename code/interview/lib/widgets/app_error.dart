part of 'index.dart';

class AppError extends StatelessWidget {
  const AppError({super.key, this.message = '加载失败', this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.iconCaution,
            width: 44.r,
            height: 44.r,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16.h),
            FilledButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}
