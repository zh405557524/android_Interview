part of '../index.dart';

/// 展示更多设置弹层，并在确认后返回设置结果。
Future<({bool diversifiedVersionsEnabled})?> showCreationMoreSettingsSheet(
  BuildContext context, {
  required bool initialDiversifiedVersionsEnabled,
}) {
  // 视频多样性开关，确认后会随 quick batch 创建请求传给后端。
  var diversifiedVersionsEnabled = initialDiversifiedVersionsEnabled;

  return showModalBottomSheet<({bool diversifiedVersionsEnabled})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return _CreationSheetScaffold(
            height: 544.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                SizedBox(height: 30.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 12.h),
                    decoration: _glassDecoration(radius: 18.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '视频多样性',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setSheetState(() {
                                  diversifiedVersionsEnabled =
                                      !diversifiedVersionsEnabled;
                                });
                              },
                              borderRadius: BorderRadius.circular(10.r),
                              child: Image.asset(
                                diversifiedVersionsEnabled
                                    ? AppAssets.iconSwitchOn
                                    : AppAssets.iconSwitchOff,
                                width: 38.r,
                                height: 20.r,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Colors.white.withValues(alpha: 0.1)),
                        Text(
                          '开启后，系统将为您智能生成一个常规集锦和1~3个多样版本，为您提供更多选择。该过程可能需要更多处理时间',
                          style: TextStyle(
                            color: const Color(0xFF8A8A8A),
                            fontSize: 12.sp,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                _SheetActionBar(
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () {
                    Navigator.pop(context, (
                      diversifiedVersionsEnabled: diversifiedVersionsEnabled,
                    ));
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
