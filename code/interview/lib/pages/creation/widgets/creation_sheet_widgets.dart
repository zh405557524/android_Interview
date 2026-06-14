part of '../index.dart';

/// 创作页底部弹层的统一容器。
class _CreationSheetScaffold extends StatelessWidget {
  const _CreationSheetScaffold({required this.height, required this.child});

  /// 弹层固定高度。
  final double height;

  /// 弹层主体内容。
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF0B100C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

/// 创作页底部弹层顶部的拖拽视觉把手。
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42.w,
        height: 4.h,
        margin: EdgeInsets.only(top: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
    );
  }
}

/// 创作页底部弹层通用的取消/确定操作区。
class _SheetActionBar extends StatelessWidget {
  const _SheetActionBar({required this.onCancel, required this.onConfirm});

  /// 点击取消时关闭弹层或放弃本地选择。
  final VoidCallback onCancel;

  /// 点击确定时把弹层选择结果返回给页面。
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15.w, 12.h, 15.w, 14.h),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 49.h,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
                child: const Text('取消'),
              ),
            ),
          ),
          SizedBox(width: 17.w),
          Expanded(
            child: SizedBox(
              height: 49.h,
              child: FilledButton(
                onPressed: onConfirm,
                style: FilledButton.styleFrom(
                  backgroundColor: CustomTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),
                child: const Text('确定'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 创作页弹层内的小型分段选择器。
class _SegmentedChoice<T> extends StatelessWidget {
  const _SegmentedChoice({
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  /// 当前选中的值。
  final T value;

  /// 分段选择器展示的全部候选项。
  final List<T> values;

  /// 把候选项转换为展示文案。
  final String Function(T value) labelBuilder;

  /// 用户切换选项时的回调。
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32.h,
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: values.map((item) {
          final selected = item == value;
          return InkWell(
            onTap: () => onChanged(item),
            borderRadius: BorderRadius.circular(14.r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 28.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? CustomTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                labelBuilder(item),
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
