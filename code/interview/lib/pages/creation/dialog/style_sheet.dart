part of '../index.dart';

/// 展示解说风格选择弹层，并在用户确认后返回风格 ID。
Future<String?> showCreationStyleSheet(
  BuildContext context, {
  required List<CreationStyle> styles,
  required CreationMode initialMode,
  required String initialStyleId,
}) {
  var selectedMode = initialMode;
  var selectedStyleId = initialStyleId;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final visibleStyles = styles
              .where((item) => item.mode == selectedMode)
              .toList();

          return _CreationSheetScaffold(
            height: 544.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '解说风格',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _SegmentedChoice<CreationMode>(
                        value: selectedMode,
                        values: const <CreationMode>[
                          CreationMode.narration,
                          CreationMode.trimming,
                        ],
                        labelBuilder: (value) => switch (value) {
                          CreationMode.narration => '视频解说',
                          CreationMode.trimming => '视频精剪',
                        },
                        onChanged: (value) {
                          setSheetState(() {
                            selectedMode = value;
                            selectedStyleId = _firstStyleIdForMode(
                              styles,
                              value,
                              selectedStyleId,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: visibleStyles.isEmpty
                      ? const Center(
                          child: Text(
                            '暂无可用风格',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                          itemCount: visibleStyles.length,
                          separatorBuilder: (_, _) => SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final item = visibleStyles[index];
                            final selected = item.id == selectedStyleId;
                            return InkWell(
                              onTap: () {
                                setSheetState(() => selectedStyleId = item.id);
                              },
                              borderRadius: BorderRadius.circular(16.r),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                constraints: BoxConstraints(minHeight: 62.h),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? CustomTheme.primary.withValues(
                                          alpha: 0.16,
                                        )
                                      : Colors.white.withValues(alpha: 0.06),
                                  border: Border.all(
                                    color: selected
                                        ? CustomTheme.primary
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            item.description,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white60,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      const AppSelectionIcon(
                                        selected: true,
                                        showUnselected: false,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                _SheetActionBar(
                  onCancel: () => Navigator.pop(context),
                  onConfirm: visibleStyles.isEmpty
                      ? () => Navigator.pop(context)
                      : () => Navigator.pop(context, selectedStyleId),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// 在指定模式下找到可用风格，优先保留当前选择。
String _firstStyleIdForMode(
  List<CreationStyle> styles,
  CreationMode mode,
  String current,
) {
  final visible = styles.where((item) => item.mode == mode).toList();
  if (visible.any((item) => item.id == current)) {
    return current;
  }
  if (visible.isNotEmpty) {
    return visible.first.id;
  }
  return current;
}
