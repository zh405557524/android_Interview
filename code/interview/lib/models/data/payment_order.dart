import 'dart:convert';

import '../../enums/index.dart';

/// 支付订单数据。
///
/// 用于会员购买和积分充值提交后承载支付参数。
final class PaymentOrder {
  const PaymentOrder({
    required this.id,
    required this.orderNo,
    required this.channel,
    required this.purpose,
    required this.status,
    required this.payParams,
    this.orderInfo = '',
    this.productId = '',
    this.productName = '',
    this.amountText = '',
    this.createdAtText = '',
    this.userId = '',
    this.appCode = '',
    this.cardType,
    this.isDeleted = false,
  });

  /// 订单 id。
  final String id;

  /// 业务订单号。
  final String orderNo;

  /// 支付渠道。
  final PaymentChannel channel;

  /// 订单用途：会员或积分。
  final PaymentPurpose purpose;

  /// 当前订单状态。
  final PaymentOrderStatus status;

  /// 调起第三方支付 SDK 所需参数。
  final Map<String, dynamic> payParams;

  /// 支付宝 App 支付 orderInfo 签名串。
  final String orderInfo;

  /// 产品 ID。
  final String productId;

  /// 产品名称。
  final String productName;

  /// 订单金额展示文案。
  final String amountText;

  /// 订单创建时间展示文案。
  final String createdAtText;

  /// 下单用户 ID。
  final String userId;

  /// 后端应用标识。
  final String appCode;

  /// 会员卡类型：1=月卡，2=季卡，3=年卡。
  final int? cardType;

  /// 后端逻辑删除标记；删除后的订单不再展示在前端列表。
  final bool isDeleted;

  String get identity => id.isNotEmpty ? id : orderNo;

  factory PaymentOrder.fromJson(
    Map<String, dynamic> json, {
    PaymentChannel? fallbackChannel,
    PaymentPurpose? fallbackPurpose,
    String fallbackProductId = '',
  }) {
    final orderInfo = _stringValue(json, const <String>[
      'orderInfo',
      'appPayInfo',
      'payInfo',
    ]);
    final orderId = _stringValue(json, const <String>[
      'id',
      'orderId',
      'orderNo',
    ]).ifEmpty(_orderIdFromOrderInfo(orderInfo));
    final payParams = Map<String, dynamic>.from(
      json['payParams'] as Map? ?? const <String, dynamic>{},
    );
    if (orderInfo.isNotEmpty && !payParams.containsKey('orderInfo')) {
      payParams['orderInfo'] = orderInfo;
    }
    return PaymentOrder(
      id: orderId,
      orderNo: _stringValue(json, const <String>[
        'orderNo',
        'orderId',
        'id',
      ]).ifEmpty(orderId),
      channel: _channel(json['channel'] ?? json['payType'], fallbackChannel),
      purpose: _purpose(
        json['purpose'] ?? json['productType'],
        fallbackPurpose,
      ),
      status: _status(json['status'] ?? json['payStatus']),
      payParams: payParams,
      orderInfo: orderInfo,
      productId: _stringValue(json, const <String>[
        'productId',
      ]).ifEmpty(fallbackProductId),
      productName: '${json['productName'] ?? ''}',
      amountText: _amountText(json),
      createdAtText: _createdAtText(json),
      userId: '${json['userId'] ?? ''}',
      appCode: '${json['appCode'] ?? ''}',
      cardType: (json['cardType'] as num?)?.toInt(),
      isDeleted: _deleted(json['del'] ?? json['deleted'] ?? json['isDeleted']),
    );
  }

  factory PaymentOrder.fromOrderInfo({
    required String orderInfo,
    required PaymentChannel channel,
    required PaymentPurpose purpose,
    String productId = '',
  }) {
    final orderId = _orderIdFromOrderInfo(orderInfo);
    return PaymentOrder(
      id: orderId,
      orderNo: orderId,
      channel: channel,
      purpose: purpose,
      status: PaymentOrderStatus.pending,
      payParams: <String, dynamic>{'orderInfo': orderInfo},
      orderInfo: orderInfo,
      productId: productId,
    );
  }

  PaymentOrder copyWith({
    String? id,
    String? orderNo,
    PaymentChannel? channel,
    PaymentPurpose? purpose,
    PaymentOrderStatus? status,
    Map<String, dynamic>? payParams,
    String? orderInfo,
    String? productId,
    String? productName,
    String? amountText,
    String? createdAtText,
    String? userId,
    String? appCode,
    int? cardType,
    bool? isDeleted,
  }) {
    return PaymentOrder(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      channel: channel ?? this.channel,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      payParams: payParams ?? this.payParams,
      orderInfo: orderInfo ?? this.orderInfo,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      amountText: amountText ?? this.amountText,
      createdAtText: createdAtText ?? this.createdAtText,
      userId: userId ?? this.userId,
      appCode: appCode ?? this.appCode,
      cardType: cardType ?? this.cardType,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'orderNo': orderNo,
      'channel': channel.name,
      'purpose': purpose.name,
      'status': status.name,
      'payParams': payParams,
      'orderInfo': orderInfo,
      'productId': productId,
      'productName': productName,
      'amountText': amountText,
      'createdAtText': createdAtText,
      'userId': userId,
      'appCode': appCode,
      if (cardType != null) 'cardType': cardType,
      'isDeleted': isDeleted,
    };
  }
}

PaymentChannel _channel(Object? value, [PaymentChannel? fallback]) {
  final raw = '${value ?? ''}'.trim().toLowerCase();
  if (raw == '1' || raw == 'zfb' || raw == 'alipay') {
    return PaymentChannel.alipay;
  }
  if (raw == '2' || raw == 'wx' || raw == 'wechat') {
    return PaymentChannel.wechat;
  }
  if (raw == '3' || raw == 'ios' || raw == 'appleiap') {
    return PaymentChannel.appleIap;
  }
  return PaymentChannel.values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback ?? PaymentChannel.alipay,
  );
}

PaymentPurpose _purpose(Object? value, [PaymentPurpose? fallback]) {
  final raw = '${value ?? ''}'.trim().toLowerCase();
  if (raw == '1' || raw == 'membership' || raw == 'card') {
    return PaymentPurpose.membership;
  }
  if (raw == '2' || raw == 'points') {
    return PaymentPurpose.points;
  }
  return PaymentPurpose.values.firstWhere(
    (item) => item.name == value,
    orElse: () => fallback ?? PaymentPurpose.points,
  );
}

PaymentOrderStatus _status(Object? value) {
  final raw = '${value ?? ''}'.trim().toLowerCase();
  if (raw == '0' || raw == 'pending') {
    return PaymentOrderStatus.pending;
  }
  if (raw == '1' || raw == 'paid' || raw == 'success') {
    return PaymentOrderStatus.paid;
  }
  if (raw == '2' || raw == 'canceled' || raw == 'cancelled') {
    return PaymentOrderStatus.canceled;
  }
  if (raw == '3' || raw == 'closed' || raw == 'failed') {
    return PaymentOrderStatus.failed;
  }
  return PaymentOrderStatus.values.firstWhere(
    (item) => item.name == value,
    orElse: () => PaymentOrderStatus.pending,
  );
}

bool _deleted(Object? value) {
  final raw = '${value ?? ''}'.trim().toLowerCase();
  return raw == '1' || raw == 'true' || raw == 'yes';
}

String _stringValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && '$value'.trim().isNotEmpty) {
      return '$value'.trim();
    }
  }
  return '';
}

String _amountText(Map<String, dynamic> json) {
  final value = _firstValue(json, const <String>[
    'totalAmount',
    'payAmount',
    'amount',
    'price',
  ]);
  if (value == null) {
    return '';
  }
  if (value is num) {
    final hasDecimal = value % 1 != 0;
    return '¥${value.toStringAsFixed(hasDecimal ? 2 : 0)}';
  }
  final raw = '$value'.trim();
  if (raw.isEmpty) {
    return '';
  }
  if (raw.startsWith('¥')) {
    return raw;
  }
  final number = num.tryParse(raw);
  if (number == null) {
    return raw;
  }
  final hasDecimal = number % 1 != 0;
  return '¥${number.toStringAsFixed(hasDecimal ? 2 : 0)}';
}

String _createdAtText(Map<String, dynamic> json) {
  final value = _firstValue(json, const <String>[
    'createTime',
    'createDate',
    'orderTime',
    'payTime',
  ]);
  if (value == null) {
    return '';
  }
  if (value is num) {
    final milliseconds = value > 1000000000000
        ? value.toInt()
        : value.toInt() * 1000;
    return _formatDateTime(
      DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal(),
    );
  }
  final raw = '$value'.trim();
  if (raw.isEmpty) {
    return '';
  }
  final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    return raw;
  }
  return _formatDateTime(parsed.toLocal());
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && '$value'.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

String _formatDateTime(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}.$month.$day $hour:$minute';
}

String _orderIdFromOrderInfo(String orderInfo) {
  if (orderInfo.trim().isEmpty) {
    return '';
  }
  final params = _queryParams(orderInfo);
  final bizContent = params['biz_content'];
  if (bizContent != null && bizContent.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(bizContent);
      if (decoded is Map) {
        final value = decoded['out_trade_no'];
        if (value != null && '$value'.trim().isNotEmpty) {
          return '$value'.trim();
        }
      }
    } catch (_) {
      // Fall through to regex parsing for non-standard orderInfo strings.
    }
  }
  final match = RegExp(r'"out_trade_no"\s*:\s*"([^"]+)"').firstMatch(orderInfo);
  return match?.group(1)?.trim() ?? '';
}

Map<String, String> _queryParams(String orderInfo) {
  try {
    return Uri.splitQueryString(orderInfo, encoding: utf8);
  } catch (_) {
    return const <String, String>{};
  }
}

extension on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
  }
}
