part of 'index.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 12.h),
            Text(
              message!,
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ],
        ],
      ),
    );
  }
}
