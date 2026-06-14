/// 后端配置的静态内容页。
///
/// 用于用户协议、隐私政策、充值规则等轻量文本页面。
final class AppStaticPage {
  const AppStaticPage({
    required this.key,
    required this.title,
    required this.content,
    this.url = '',
  });

  /// 静态页标识，例如 `privacy-policy`。
  final String key;

  /// 页面标题。
  final String title;

  /// 页面正文内容。
  final String content;

  /// 后端托管的静态 HTML 页面地址。
  final String url;

  factory AppStaticPage.fromJson(Map<String, dynamic> json) {
    return AppStaticPage(
      key: '${json['key'] ?? ''}',
      title: '${json['title'] ?? ''}',
      content: '${json['content'] ?? ''}',
      url: '${json['url'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key,
      'title': title,
      'content': content,
      'url': url,
    };
  }
}
