part of '../index.dart';

Future<bool?> showCreationEntitlementDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.8),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 48.w),
        child: Container(
          width: 279.w,
          padding: EdgeInsets.fromLTRB(25.w, 24.h, 25.w, 22.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF17230C), Color(0xFF080B08)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: CustomTheme.primary.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '哎呀..',
                style: TextStyle(
                  color: const Color(0xFFE7F8C7),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '权益不足',
                style: TextStyle(
                  color: const Color(0xFFE7F8C7),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '当前权益不足，请升级会员后继续体验',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42.h,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFAFCB9A),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(
                            color: CustomTheme.primary.withValues(alpha: 0.18),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('我再想想'),
                      ),
                    ),
                  ),
                  SizedBox(width: 9.w),
                  Expanded(
                    child: SizedBox(
                      height: 42.h,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: CustomTheme.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text('升级会员'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
