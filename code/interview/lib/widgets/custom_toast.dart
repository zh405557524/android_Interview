part of 'index.dart';

abstract final class CustomToast {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static TransitionBuilder init({
    required BuildContext context,
    required TransitionBuilder builder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.ring
      ..loadingStyle = EasyLoadingStyle.custom
      ..radius = 10
      ..progressColor = Colors.transparent
      ..contentPadding = const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 24,
      )
      ..backgroundColor = CustomTheme.surfaceHigh
      ..maskColor = Colors.transparent
      ..indicatorColor = Colors.transparent
      ..textColor = Colors.white
      ..textStyle = const TextStyle(fontSize: 16, color: Colors.white)
      ..maskType = EasyLoadingMaskType.clear
      ..userInteractions = true
      ..dismissOnTap = false
      ..successWidget = const CustomToastSuccess(color: Colors.white)
      ..errorWidget = const CustomToastFail(color: Colors.white)
      ..indicatorWidget = CustomLoadingIndicator(color: colorScheme.primary);
    _initialized = true;
    return EasyLoading.init(builder: builder);
  }

  static void text(
    String text, {
    EasyLoadingToastPosition position = EasyLoadingToastPosition.center,
  }) {
    if (!_initialized) return;

    dismiss();
    EasyLoading.instance
      ..maskType = EasyLoadingMaskType.clear
      ..userInteractions = true;
    EasyLoading.showToast(text, toastPosition: position);
  }

  static void showProgress(double progress, String? statusText) {
    if (!_initialized) return;

    EasyLoading.instance
      ..progressColor = CustomTheme.primary
      ..indicatorColor = Colors.white
      ..progressWidth = 5
      ..maskType = EasyLoadingMaskType.clear
      ..userInteractions = false;

    EasyLoading.showProgress(progress, status: statusText);
  }

  static void success(String text) {
    if (!_initialized) return;

    EasyLoading.instance
      ..maskType = EasyLoadingMaskType.clear
      ..userInteractions = true;
    EasyLoading.showSuccess(text);
  }

  static void fail(
    String text, {
    Object? error,
    StackTrace? stackTrace,
    String tag = '[Toast]',
  }) {
    AppLogger.error('$tag $text', error, stackTrace);
    if (!_initialized) return;

    dismiss();
    EasyLoading.instance
      ..maskType = EasyLoadingMaskType.clear
      ..userInteractions = true;
    EasyLoading.showError(text);
  }

  static void error(
    String text, {
    Object? error,
    StackTrace? stackTrace,
    String tag = '[Toast]',
  }) {
    AppLogger.error('$tag $text', error, stackTrace);
    CustomToast.text(text);
  }

  static void loading([String? text]) {
    if (!_initialized) return;

    WakelockPlus.enable();
    EasyLoading.instance
      ..maskType = EasyLoadingMaskType.custom
      ..userInteractions = false;
    EasyLoading.show(status: text);
  }

  static void dismiss() {
    if (!_initialized) return;

    WakelockPlus.disable();
    EasyLoading.dismiss();
  }
}

class CustomToastFail extends StatelessWidget {
  const CustomToastFail({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.close_rounded,
      color: color ?? CustomTheme.danger,
      size: 40,
    );
  }
}

class CustomToastSuccess extends StatelessWidget {
  const CustomToastSuccess({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_rounded,
      color: color ?? CustomTheme.primary,
      size: 40,
    );
  }
}

class CustomLoadingIndicator extends StatefulWidget {
  const CustomLoadingIndicator({
    super.key,
    this.color,
    this.strokeWidth = 4,
    this.size = 40,
    this.duration = const Duration(milliseconds: 1200),
    this.controller,
    this.padding,
  });

  final Color? color;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final EdgeInsetsGeometry? padding;
  final AnimationController? controller;

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation1;
  late final Animation<double> _animation2;
  late final Animation<double> _animation3;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AnimationController(vsync: this, duration: widget.duration);
    _controller
      ..addListener(_handleTick)
      ..repeat();
    _animation1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 1, curve: Curves.linear),
      ),
    );
    _animation2 = Tween(begin: -2 / 3, end: 1 / 2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1, curve: Curves.linear),
      ),
    );
    _animation3 = Tween(begin: 0.25, end: 5 / 6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 1, curve: _RingCurve()),
      ),
    );
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTick);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _handleTick() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(10),
      child: Transform(
        transform: Matrix4.identity()
          ..rotateZ(_animation1.value * 5 * math.pi / 6),
        alignment: FractionalOffset.center,
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _RingPainter(
              paintWidth: widget.strokeWidth,
              trackColor: widget.color ?? Theme.of(context).colorScheme.primary,
              progressPercent: _animation3.value,
              startAngle: math.pi * _animation2.value,
              gradientColors: const [
                Color.fromRGBO(98, 218, 243, 1),
                Color.fromRGBO(90, 122, 238, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.paintWidth,
    required this.trackColor,
    required this.gradientColors,
    required this.progressPercent,
    required this.startAngle,
  });

  final double paintWidth;
  final Color trackColor;
  final List<Color> gradientColors;
  final double progressPercent;
  final double startAngle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - paintWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = paintWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor.withValues(alpha: 0.2);
    final foregroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = paintWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradientColors,
      ).createShader(rect);

    canvas
      ..drawCircle(center, radius, backgroundPaint)
      ..drawArc(
        rect,
        startAngle,
        2 * math.pi * progressPercent,
        false,
        foregroundPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return paintWidth != oldDelegate.paintWidth ||
        trackColor != oldDelegate.trackColor ||
        gradientColors != oldDelegate.gradientColors ||
        progressPercent != oldDelegate.progressPercent ||
        startAngle != oldDelegate.startAngle;
  }
}

class _RingCurve extends Curve {
  const _RingCurve();

  @override
  double transform(double t) => t <= 0.5 ? 2 * t : 2 * (1 - t);
}
