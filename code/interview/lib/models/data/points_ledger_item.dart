import '../../enums/index.dart';

/// 单条积分流水。
///
/// 用于积分详情页展示收入、支出、冻结或退款记录。
final class PointsLedgerItem {
  const PointsLedgerItem({
    required this.id,
    required this.title,
    required this.dateText,
    required this.amount,
    required this.direction,
  });

  /// 流水记录 id。
  final String id;

  /// 流水标题或来源说明。
  final String title;

  /// 已格式化的流水时间。
  final String dateText;

  /// 积分变动数量。
  final int amount;

  /// 积分变动方向。
  final PointDirection direction;

  factory PointsLedgerItem.fromJson(Map<String, dynamic> json) {
    final amount = _amount(json);
    return PointsLedgerItem(
      id: '${json['id'] ?? ''}',
      title: _titleText(json['title'] ?? json['remark']),
      dateText: _dateText(
        json['dateText'] ?? json['createdAt'] ?? json['createTime'],
      ),
      amount: amount,
      direction: _direction(json['direction'], amount, json['recordType']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'dateText': dateText,
      'amount': amount,
      'direction': direction.name,
    };
  }
}

int _amount(Map<String, dynamic> json) {
  final value = json['amount'] ?? json['points'];
  return (value as num?)?.toInt() ?? 0;
}

PointDirection _direction(Object? value, int amount, Object? recordType) {
  final matched = PointDirection.values.where((item) => item.name == value);
  if (matched.isNotEmpty) {
    return matched.first;
  }
  final type = (recordType as num?)?.toInt();
  if (type == 1) {
    return PointDirection.income;
  }
  if (type == 3) {
    return PointDirection.expense;
  }
  return amount >= 0 ? PointDirection.income : PointDirection.expense;
}

/// 积分标题只展示用户能理解的业务名称，隐藏后端内部流程节点说明。
String _titleText(Object? value) {
  return '${value ?? ''}'.replaceAll('（已加入百度项目）', '').trim();
}

/// 将后端 LocalDateTime/ISO 字符串转成积分详情页可读时间。
///
/// 后端当前返回形如 `2026-05-28T17:24:40.134746` 的时间，这里去掉 `T`
/// 和微秒，避免把接口序列化格式直接展示给用户。
String _dateText(Object? value) {
  final rawText = '${value ?? ''}'.trim();
  if (rawText.isEmpty) {
    return '';
  }
  final dateTime = DateTime.tryParse(rawText);
  if (dateTime == null) {
    return rawText;
  }
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${dateTime.year}-${twoDigits(dateTime.month)}-${twoDigits(dateTime.day)} '
      '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}
