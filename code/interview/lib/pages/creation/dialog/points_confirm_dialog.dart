part of '../index.dart';

Future<bool?> showCreationPointsConfirmDialog(
  BuildContext context,
  GenerationEstimate estimate,
) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 45.w),
        child: Stack(
          children: [
            Container(
              width: 284.w,
              padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 28.h),
              decoration: BoxDecoration(
                color: const Color(0xFF071007),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: CustomTheme.primary),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        colors: [Color(0xFFF2F865), Color(0xFF2BDC3D)],
                      ).createShader(bounds);
                    },
                    child: Text(
                      '${estimate.pointCost}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 76.sp,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '本次创作消耗积分',
                    style: TextStyle(
                      color: const Color(0xFFF0FCF7),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: 34.h),
                  SizedBox(
                    width: 240.w,
                    height: 46.h,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: CustomTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        '立即生成',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 10.w,
              top: 10.h,
              child: IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: Image.asset(
                  AppAssets.iconClose,
                  width: 24.r,
                  height: 24.r,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                ),
                color: Colors.white70,
                tooltip: '关闭',
              ),
            ),
          ],
        ),
      );
    },
  );
}
