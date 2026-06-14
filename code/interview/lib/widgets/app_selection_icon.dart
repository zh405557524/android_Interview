part of 'index.dart';

class AppSelectionIcon extends StatelessWidget {
  const AppSelectionIcon({
    required this.selected,
    super.key,
    this.size,
    this.showUnselected = true,
  });

  final bool selected;
  final double? size;
  final bool showUnselected;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.r;
    if (!selected && !showUnselected) {
      return SizedBox(width: iconSize, height: iconSize);
    }

    return SizedBox.square(
      dimension: iconSize,
      child: Center(
        child: Image.asset(
          selected ? AppAssets.iconConfirm : AppAssets.iconUnconfirm,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class AppAgreementIcon extends StatelessWidget {
  const AppAgreementIcon({required this.selected, super.key, this.size});

  final bool selected;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 20.r;
    return SizedBox.square(
      dimension: iconSize,
      child: Center(
        child: Image.asset(
          selected ? AppAssets.iconCheckAgreement : AppAssets.iconCircle,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
