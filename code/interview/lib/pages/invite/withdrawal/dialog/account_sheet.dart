part of '../index.dart';

/// 展示提现账号编辑弹层。
///
/// 弹层只接收输入控制器与关闭动作，不持有提现 Controller；父页面在弹层关闭后
/// 自行同步账号展示文案。
Future<void> showInviteWithdrawAccountSheet(
  BuildContext context, {
  required TextEditingController accountController,
  required TextEditingController nameController,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF091304),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(15.w, 18.h, 15.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '支付宝提现账号',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 16.h),
              InviteTextInput(
                controller: accountController,
                hintText: '请输入支付宝账号',
              ),
              SizedBox(height: 10.h),
              InviteTextInput(
                controller: nameController,
                hintText: '请输入收款人姓名',
              ),
              SizedBox(height: 16.h),
              InviteGradientButton(
                label: '确定',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          ),
        ),
      );
    },
  );
}
