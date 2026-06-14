part of '../index.dart';

/// 展示创作页删除已选视频的二次确认弹框。
///
/// 这里只确认从当前创作草稿中移除视频，不会删除系统相册或本地原始文件。
Future<bool?> showCreationDeleteConfirmDialog(BuildContext context) {
  return AppConfirmDialog.show(
    context,
    title: '是否删除',
    message: '是否选择删除当前“视频”，删除后可重新添加',
  );
}
