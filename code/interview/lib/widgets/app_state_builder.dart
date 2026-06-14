part of 'index.dart';

class AppStateBuilder extends StatelessWidget {
  const AppStateBuilder({
    required this.state,
    required this.builder,
    super.key,
    this.loadingMessage,
    this.emptyMessage = '暂无内容',
    this.errorMessage = '加载失败',
    this.notFoundMessage = '内容不存在或已失效',
    this.onRetry,
    this.emptyAction,
    this.loading,
    this.empty,
    this.error,
    this.notFound,
  });

  final ViewState state;
  final WidgetBuilder builder;
  final String? loadingMessage;
  final String emptyMessage;
  final String errorMessage;
  final String notFoundMessage;
  final VoidCallback? onRetry;
  final Widget? emptyAction;
  final Widget? loading;
  final Widget? empty;
  final Widget? error;
  final Widget? notFound;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ViewState.loading => loading ?? AppLoading(message: loadingMessage),
      ViewState.empty =>
        empty ?? AppEmpty(message: emptyMessage, action: emptyAction),
      ViewState.error =>
        error ?? AppError(message: errorMessage, onRetry: onRetry),
      ViewState.notFound =>
        notFound ?? AppError(message: notFoundMessage, onRetry: onRetry),
      ViewState.idle ||
      ViewState.success ||
      ViewState.submitting => builder(context),
    };
  }
}
