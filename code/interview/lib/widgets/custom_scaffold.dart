part of 'index.dart';

class CustomScaffold extends StatelessWidget {
  const CustomScaffold({
    super.key,
    this.resizeToAvoidBottomInset,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.primaryColor,
    this.backgroundColor = CustomTheme.background,
    this.backgroundImage,
    this.extendBodyBehindAppBar,
  });

  final bool? resizeToAvoidBottomInset;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Color? primaryColor;
  final Color? backgroundColor;
  final AssetImage? backgroundImage;
  final bool? extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: _boxDecoration(),
      child: Theme(
        data: theme.copyWith(
          colorScheme: primaryColor == null
              ? theme.colorScheme
              : theme.colorScheme.copyWith(primary: primaryColor),
          appBarTheme: theme.appBarTheme.copyWith(
            backgroundColor: Colors.transparent,
          ),
          bottomAppBarTheme: theme.bottomAppBarTheme.copyWith(
            color: Colors.transparent,
          ),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: extendBodyBehindAppBar ?? false,
          appBar: appBar,
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    if (backgroundImage == null) {
      return BoxDecoration(color: backgroundColor ?? Colors.transparent);
    }
    return BoxDecoration(
      color: backgroundColor ?? Colors.transparent,
      image: DecorationImage(
        image: backgroundImage!,
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
      ),
    );
  }
}
