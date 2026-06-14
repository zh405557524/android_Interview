part of 'index.dart';

final class StaticPageController extends GetxController {
  StaticPageController({required this.pageKey});

  final String pageKey;

  late final WebViewController webViewController;

  final RxBool loading = true.obs;
  final RxnString errorMessage = RxnString();
  final RxInt progress = 0.obs;
  final RxString pageTitle = ''.obs;

  bool _hasLoadedPage = false;

  static const Map<String, String> _pageTitles = <String, String>{
    'user-agreement': '用户协议',
    'privacy-policy': '隐私政策',
    'membership-agreement': '会员服务协议',
  };
  static const Set<String> _appCodePageKeys = <String>{
    'user-agreement',
    'privacy-policy',
    'membership-agreement',
  };

  @override
  void onInit() {
    super.onInit();
    pageTitle.value = _pageTitles[pageKey] ?? '协议说明';
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            loading.value = true;
            errorMessage.value = null;
            progress.value = 0;
          },
          onProgress: (value) {
            progress.value = value;
          },
          onPageFinished: (_) {
            loading.value = false;
            progress.value = 100;
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) {
              return;
            }
            loading.value = false;
            errorMessage.value = '页面加载失败，请检查网络后重试';
          },
        ),
      );
    unawaited(loadPage());
  }

  String get title => pageTitle.value;

  Future<void> loadPage() async {
    loading.value = true;
    errorMessage.value = null;
    progress.value = 0;
    try {
      final page = await ConfigAPI.staticPage(pageKey);
      final title = page.title.trim();
      if (title.isNotEmpty) {
        pageTitle.value = title;
      }
      final url = page.url.trim();
      _hasLoadedPage = true;
      if (url.isNotEmpty) {
        await webViewController.loadRequest(_pageUri(url));
        return;
      }
      await webViewController.loadHtmlString(_fallbackHtml(page));
    } on ApiException catch (error) {
      _hasLoadedPage = false;
      loading.value = false;
      errorMessage.value = error.userMessage;
    } catch (_) {
      _hasLoadedPage = false;
      loading.value = false;
      errorMessage.value = '页面加载失败，请检查网络后重试';
    }
  }

  void reload() {
    errorMessage.value = null;
    loading.value = true;
    if (_hasLoadedPage) {
      webViewController.reload();
      return;
    }
    unawaited(loadPage());
  }

  Uri _pageUri(String url) {
    final uri = Uri.parse(url);
    if (!_appCodePageKeys.contains(pageKey)) {
      return uri;
    }
    final queryParameters = Map<String, String>.from(uri.queryParameters);
    final appCode = queryParameters['appCode']?.trim();
    if (appCode == null || appCode.isEmpty) {
      queryParameters['appCode'] = AppConstants.appCode;
    }
    return uri.replace(queryParameters: queryParameters);
  }

  String _fallbackHtml(AppStaticPage page) {
    const escape = HtmlEscape();
    final title = escape.convert(
      page.title.trim().isEmpty ? this.title : page.title.trim(),
    );
    final content = page.content.trim().isEmpty ? '页面内容暂未配置。' : page.content;
    final paragraphs = content
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => '<p>${escape.convert(line)}</p>')
        .join('\n');
    return '''
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$title</title>
  <style>
    body{margin:0;padding:24px 18px;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#111827;background:#fff}
    h1{font-size:22px;line-height:1.35;margin:0 0 18px}
    p{font-size:15px;line-height:1.8;margin:0 0 12px;color:#374151}
  </style>
</head>
<body>
  <h1>$title</h1>
  $paragraphs
</body>
</html>
''';
  }
}
