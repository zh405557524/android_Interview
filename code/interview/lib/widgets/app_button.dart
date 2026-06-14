part of 'index.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.loading = false,
    this.disabled = false,
    this.loadingLabel,
    this.icon,
    this.iconAsset,
    this.iconAssetColor,
    this.height,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool disabled;
  final String? loadingLabel;
  final IconData? icon;
  final String? iconAsset;
  final Color? iconAssetColor;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading || disabled ? null : onPressed;
    final bgColor = backgroundColor ?? CustomTheme.primary;
    final fgColor = foregroundColor ?? Colors.black;

    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 50.h,
      child: FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: bgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.38),
          foregroundColor: fgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 25.r),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: loading
              ? _AppButtonLoading(label: loadingLabel)
              : _AppButtonLabel(
                  label: label,
                  icon: icon,
                  iconAsset: iconAsset,
                  iconAssetColor: iconAssetColor ?? fgColor,
                ),
        ),
      ),
    );
  }
}

class _AppButtonLabel extends StatelessWidget {
  const _AppButtonLabel({
    required this.label,
    this.icon,
    this.iconAsset,
    this.iconAssetColor,
  });

  final String label;
  final IconData? icon;
  final String? iconAsset;
  final Color? iconAssetColor;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
    );
    if (icon == null && iconAsset == null) {
      return text;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (iconAsset != null)
          Image.asset(
            iconAsset!,
            width: 18.r,
            height: 18.r,
            color: iconAssetColor,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        else
          Icon(icon, size: 18.r),
        SizedBox(width: 7.w),
        Flexible(child: text),
      ],
    );
  }
}

class _AppButtonLoading extends StatelessWidget {
  const _AppButtonLoading({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('loading'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18.r,
          height: 18.r,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        if (label != null) ...[
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
