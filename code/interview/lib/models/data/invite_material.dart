/// 邀请推广素材数据。
///
/// 用于推广素材子页面展示复制链接、海报文案和下载落地页。
final class InviteMaterial {
  const InviteMaterial({
    required this.inviteCode,
    required this.inviteLink,
    required this.posterTitle,
    required this.ruleText,
    required this.landingDownloadUrl,
  });

  /// 当前用户邀请码，用于海报二维码和链接兜底。
  final String inviteCode;

  /// 当前用户邀请链接。
  final String inviteLink;

  /// 推广海报主标题。
  final String posterTitle;

  /// 推广素材页展示的邀请规则摘要。
  final String ruleText;

  /// 推广落地页下载地址。
  final String landingDownloadUrl;

  factory InviteMaterial.fromJson(Map<String, dynamic> json) {
    return InviteMaterial(
      inviteCode: '${json['inviteCode'] ?? ''}',
      inviteLink: '${json['inviteLink'] ?? json['visitUrl'] ?? ''}',
      posterTitle: '${json['posterTitle'] ?? '邀请好友一起用剧说'}',
      ruleText: '${json['ruleText'] ?? ''}',
      landingDownloadUrl:
          '${json['landingDownloadUrl'] ?? json['downloadUrl'] ?? ''}',
    );
  }
}
