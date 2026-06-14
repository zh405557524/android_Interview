part of 'index.dart';

abstract class PaymentAPI {
  /// 获取会员套餐列表。
  ///
  /// 接口：`GET /api/tbProduct/tbProductList?type=1`。
  /// 返回会员套餐展示信息；协议勾选和支付提交状态由会员 Controller 处理。
  static Future<List<MembershipPlan>> membershipPlans() async {
    final result = await products(purpose: PaymentPurpose.membership);
    return result.map((item) => item.toMembershipPlan()).toList();
  }

  /// 获取积分充值套餐列表。
  ///
  /// 接口：`GET /api/tbProduct/tbProductList?type=2`。
  /// 返回积分数量、价格和角标；支付方式选择由积分充值 Controller 处理。
  static Future<List<PointsPackage>> pointsPackages() async {
    final result = await products(purpose: PaymentPurpose.points);
    return result.map((item) => item.toPointsPackage()).toList();
  }

  /// 查询支付产品列表。
  ///
  /// 会员和积分共用 `/api/tbProduct/tbProductList`，通过 `type` 区分：
  /// `1` 为会员卡套，`2` 为积分积套。
  static Future<List<PaymentProduct>> products({
    required PaymentPurpose purpose,
    int pageNo = 1,
    int pageSize = 20,
  }) async {
    final response = await HttpService.to.get(
      '/api/tbProduct/tbProductList',
      query: <String, dynamic>{
        'pageNo': pageNo,
        'pageSize': pageSize,
        'type': _productType(purpose),
      },
    );
    if (purpose == PaymentPurpose.membership) {
      _logMembershipProductResponse(response);
    }
    return ApiParser.dataList(response).map((item) {
      return PaymentProduct.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// 创建会员购买订单。
  ///
  /// 接口：`POST /api/tbOrder/creOrder`。
  /// 返回后端 AliPayInfo，其中 `appPayInfo` 是支付宝 App 支付参数；
  /// 真实支付结果以后端订单状态为准。
  static Future<PaymentOrder> createMembershipOrder({
    required String planId,
    required PaymentChannel channel,
  }) {
    return _createOrder(
      productId: planId,
      purpose: PaymentPurpose.membership,
      channel: channel,
    );
  }

  /// 创建积分充值订单。
  ///
  /// 接口：`POST /api/tbOrder/creOrder`。
  /// 返回后端 AliPayInfo，其中 `appPayInfo` 是支付宝 App 支付参数；
  /// 支付完成后通过订单详情确认状态。
  static Future<PaymentOrder> createPointsOrder({
    required String packageId,
    required PaymentChannel channel,
  }) {
    return _createOrder(
      productId: packageId,
      purpose: PaymentPurpose.points,
      channel: channel,
    );
  }

  /// 待支付订单继续支付时刷新第三方支付参数。
  ///
  /// 接口：`POST /api/tbOrder/reqPayment`，body 同时兼容 `id/orderId` 与支付方式 `type`。
  /// 返回结构与 `creOrder` 的 AliPayInfo 一致，其中 `appPayInfo` 用于调起支付宝 SDK。
  static Future<PaymentOrder> requestPayment({
    required String orderId,
    required PaymentChannel channel,
    PaymentPurpose? fallbackPurpose,
    String fallbackProductId = '',
  }) async {
    final response = await HttpService.to.post(
      '/api/tbOrder/reqPayment',
      data: <String, dynamic>{
        'id': orderId,
        'orderId': orderId,
        'type': _payType(channel),
      },
    );
    return _orderFromAliPayInfoResponse(
      response,
      fallbackChannel: channel,
      fallbackPurpose: fallbackPurpose,
      fallbackProductId: fallbackProductId,
      failureMessage: '获取支付参数失败，请稍后重试',
    );
  }

  /// 创建支付订单的真实请求封装。
  ///
  /// 后端通过产品 id 判断会员 / 积分，通过 `type` 判断支付方式。
  /// 当前后端返回 AliPayInfo 对象；旧版字符串和嵌套字符串仍保留兼容。
  static Future<PaymentOrder> _createOrder({
    required String productId,
    required PaymentPurpose purpose,
    required PaymentChannel channel,
  }) async {
    final response = await HttpService.to.post(
      '/api/tbOrder/creOrder',
      data: <String, dynamic>{'id': productId, 'type': _payType(channel)},
    );
    return _orderFromAliPayInfoResponse(
      response,
      fallbackChannel: channel,
      fallbackPurpose: purpose,
      fallbackProductId: productId,
      failureMessage: '创建订单失败，请稍后重试',
    );
  }

  /// 将 creOrder / reqPayment 返回的 AliPayInfo 转为 [PaymentOrder]。
  ///
  /// 兼容旧版纯字符串与嵌套 `data` 字符串响应。
  static PaymentOrder _orderFromAliPayInfoResponse(
    Object? response, {
    PaymentChannel? fallbackChannel,
    PaymentPurpose? fallbackPurpose,
    String fallbackProductId = '',
    required String failureMessage,
  }) {
    final data = _unwrapNestedData(response);
    final channel = fallbackChannel ?? PaymentChannel.alipay;
    final purpose = fallbackPurpose ?? PaymentPurpose.points;
    if (data is String) {
      return PaymentOrder.fromOrderInfo(
        orderInfo: data,
        channel: channel,
        purpose: purpose,
        productId: fallbackProductId,
      );
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['data'] is String) {
        return PaymentOrder.fromOrderInfo(
          orderInfo: '${map['data']}',
          channel: channel,
          purpose: purpose,
          productId: fallbackProductId,
        );
      }
      return PaymentOrder.fromJson(
        map,
        fallbackChannel: channel,
        fallbackPurpose: purpose,
        fallbackProductId: fallbackProductId,
      );
    }
    throw ApiException(
      type: ApiErrorType.paymentFailed,
      message: failureMessage,
    );
  }

  /// 查询单个订单详情。
  ///
  /// 继续支付与支付完成后的状态确认都以该接口的最新订单状态为准。
  static Future<PaymentOrder> orderDetail(String orderId) async {
    final response = await HttpService.to.get(
      '/api/tbOrder/selectOne',
      query: <String, dynamic>{'id': orderId},
    );
    return PaymentOrder.fromJson(ApiParser.dataMap(response));
  }

  /// 查询当前用户订单列表。
  ///
  /// 订单列表用于展示历史订单；待支付订单的真正支付参数和状态以详情接口为准。
  static Future<PageResult<PaymentOrder>> orders({
    int pageNo = 1,
    int pageSize = 10,
  }) async {
    final response = await HttpService.to.get(
      '/api/tbOrder/tbOrderList',
      query: <String, dynamic>{'pageNo': pageNo, 'pageSize': pageSize},
    );
    final result = ApiParser.pageResult(
      response,
      (json) => PaymentOrder.fromJson(json),
    );
    final visibleItems = result.items
        .where((item) => !item.isDeleted)
        .toList(growable: false);
    return PageResult<PaymentOrder>(
      items: visibleItems,
      total: visibleItems.length,
      hasMore: result.hasMore,
    );
  }

  /// 取消待支付订单。
  ///
  /// 接口：`POST /api/tbOrder/upOrder`，body 为订单号数组。
  static Future<void> cancelOrders(List<String> orderIds) async {
    await HttpService.to.post('/api/tbOrder/upOrder', data: orderIds);
  }

  /// 删除已完成、已取消或已关闭订单。
  ///
  /// 接口：`POST /api/tbOrder/delOrder`，body 为订单号数组。
  static Future<void> deleteOrders(List<String> orderIds) async {
    await HttpService.to.post('/api/tbOrder/delOrder', data: orderIds);
  }
}

int _productType(PaymentPurpose purpose) {
  return switch (purpose) {
    PaymentPurpose.membership => 1,
    PaymentPurpose.points => 2,
  };
}

String _payType(PaymentChannel channel) {
  return switch (channel) {
    PaymentChannel.alipay => '1',
    PaymentChannel.wechat => throw const ApiException(
      type: ApiErrorType.validation,
      message: '当前仅支持支付宝',
    ),
    PaymentChannel.appleIap => throw const ApiException(
      type: ApiErrorType.validation,
      message: '当前仅支持支付宝',
    ),
  };
}

Object? _unwrapNestedData(Object? data) {
  final value = ApiParser.unwrapData(data);
  if (value is Map<String, dynamic> && _looksLikeApiResponse(value)) {
    final response = BaseResponse.fromJson(value);
    if (!response.isSuccess) {
      throw ApiException(
        type: ApiErrorType.paymentFailed,
        message: response.message,
      );
    }
    return response.data;
  }
  if (value is Map && _looksLikeApiResponse(value)) {
    final response = BaseResponse.fromJson(value);
    if (!response.isSuccess) {
      throw ApiException(
        type: ApiErrorType.paymentFailed,
        message: response.message,
      );
    }
    return response.data;
  }
  return value;
}

bool _looksLikeApiResponse(Map<dynamic, dynamic> value) {
  return value.containsKey('code') && value.containsKey('data');
}

void _logMembershipProductResponse(BaseResponse response) {
  try {
    AppLogger.info(
      '[Payment][Membership] tbProductList response=${jsonEncode(<String, dynamic>{'code': response.code, 'message': response.message, 'data': response.data})}',
    );
  } catch (_) {
    AppLogger.info(
      '[Payment][Membership] tbProductList response code=${response.code} '
      'message=${response.message} data=${response.data}',
    );
  }
}
