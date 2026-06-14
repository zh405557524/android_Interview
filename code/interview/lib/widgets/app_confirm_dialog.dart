part of 'index.dart';

/// 项目通用二次确认弹框。
///
/// 用于删除、退出登录、注销账号等普通业务确认场景；积分消耗、权限说明等
/// 具有独立信息结构的弹框不复用此组件。
class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = '确定',
    this.cancelText = '取消',
  });

  /// 弹框标题，描述当前需要用户确认的业务动作。
  final String title;

  /// 弹框说明文案，描述确认后的影响或不可逆风险。
  final String message;

  /// 右侧主操作按钮文案；点击后返回 `true`。
  final String confirmText;

  /// 左侧取消按钮文案；点击后返回 `false`。
  final String cancelText;

  /// 展示通用二次确认弹框，并将用户选择转换为布尔结果。
  ///
  /// 返回 `true` 表示用户确认继续，返回 `false` 表示主动取消；
  /// 当允许点击遮罩关闭时可能返回 `null`。
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = '确定',
    String cancelText = '取消',
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) {
        return AppConfirmDialog(
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 35.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          width: 305.w,
          constraints: BoxConstraints(minHeight: 200.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0B100C),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: CustomTheme.primary.withValues(alpha: 0.1),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                height: 140.h,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFC4FF81).withValues(alpha: 0.24),
                        const Color(0xFFC4FF81).withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(17.w, 20.h, 17.w, 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF999999),
                        fontSize: 14.sp,
                        height: 24 / 14,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _AppConfirmDialogButton(
                            text: cancelText,
                            primary: false,
                            onPressed: () => Navigator.of(context).pop(false),
                          ),
                        ),
                        SizedBox(width: 13.w),
                        Expanded(
                          child: _AppConfirmDialogButton(
                            text: confirmText,
                            primary: true,
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 通用确认弹框内的固定尺寸按钮，负责还原 Figma 的取消 / 确认样式。
class _AppConfirmDialogButton extends StatelessWidget {
  const _AppConfirmDialogButton({
    required this.text,
    required this.primary,
    required this.onPressed,
  });

  /// 按钮展示文案。
  final String text;

  /// 是否为右侧主操作按钮；主按钮使用黄绿色渐变。
  final bool primary;

  /// 点击按钮后关闭弹框并回传选择结果。
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12.r);
    return SizedBox(
      height: 42.h,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: primary ? null : Colors.white.withValues(alpha: 0.05),
              gradient: primary
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF82F571),
                        Color(0xFFD9FB5C),
                        Color(0xFF2BDC3D),
                      ],
                      stops: [0, 0.4, 1],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: borderRadius,
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: primary ? Colors.black : Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
