part of 'index.dart';

class InviteBindPage extends StatefulWidget {
  const InviteBindPage({super.key});

  @override
  State<InviteBindPage> createState() => _InviteBindPageState();
}

class _InviteBindPageState extends State<InviteBindPage> {
  late final InviteBindController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteBindController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '绑定邀请人',
      child: ListView(
        key: const ValueKey<String>('invite-bind'),
        padding: EdgeInsets.fromLTRB(15.w, 50.h, 15.w, 36.h),
        children: [
          InviteTextInput(
            controller: controller.bindCodeController,
            hintText: '请输入邀请码',
            textCapitalization: TextCapitalization.characters,
          ),
          SizedBox(height: 27.h),
          Obx(
            () => InviteGradientButton(
              label: controller.binding.value ? '绑定中...' : '立即兑换',
              onPressed: controller.binding.value
                  ? null
                  : controller.bindInviteCode,
            ),
          ),
          SizedBox(height: 28.h),
          Text(
            '说明',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '1.一个账号只支持绑定一次，不可更改，提交前请认真\n   核对;\n2.通过邀请链接注册会自动绑定邀请人，无需重复填写。',
            style: TextStyle(
              color: inviteTextMuted,
              fontSize: 14.sp,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
