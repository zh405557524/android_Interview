part of 'index.dart';

class InviteMaterialsPage extends StatefulWidget {
  const InviteMaterialsPage({super.key});

  @override
  State<InviteMaterialsPage> createState() => _InviteMaterialsPageState();
}

class _InviteMaterialsPageState extends State<InviteMaterialsPage> {
  late final InviteMaterialsController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(InviteMaterialsController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InviteScaffold(
      title: '推广素材',
      child: Obx(
        () => AppStateBuilder(
          state: controller.pageState,
          loadingMessage: '加载推广素材...',
          errorMessage: controller.errorMessage.value ?? '推广素材加载失败',
          onRetry: controller.loadMaterials,
          loading: const InviteDarkLoading(),
          error: InviteDarkError(onRetry: controller.loadMaterials),
          builder: (_) => RefreshIndicator(
            color: invitePrimary,
            backgroundColor: const Color(0xFF101C10),
            onRefresh: controller.loadMaterials,
            child: _MaterialsContent(
              link: controller.inviteLink,
              inviteCode: controller.inviteCode,
              onCopyLink: controller.copyInviteLink,
              onPromote: controller.shareInvite,
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialsContent extends StatelessWidget {
  const _MaterialsContent({
    required this.link,
    required this.inviteCode,
    required this.onCopyLink,
    required this.onPromote,
  });

  final String link;
  final String inviteCode;
  final VoidCallback onCopyLink;
  final VoidCallback onPromote;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('invite-materials'),
      padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 22.h),
      children: [
        const InviteGreenSectionTitle('方法一: 分享链接'),
        SizedBox(height: 10.h),
        InvitePanelCard(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 14.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                link,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 44.h,
                child: OutlinedButton(
                  onPressed: onCopyLink,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: invitePrimary.withValues(alpha: 0.7),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                  ),
                  child: Text(
                    '复制链接',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        const InviteGreenSectionTitle('方法二: 分享海报'),
        SizedBox(height: 10.h),
        _PosterPreview(inviteCode: inviteCode),
        SizedBox(height: 28.h),
        InviteGradientButton(label: '立即推广', onPressed: onPromote),
      ],
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({required this.inviteCode});

  final String inviteCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380.h,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF233209), Color(0xFF061005), Color(0xFF1F2C09)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: CustomTheme.primary.withValues(alpha: 0.6)),
      ),
      child: Center(
        child: Container(
          width: 198.w,
          height: 356.h,
          decoration: BoxDecoration(
            color: const Color(0xFF101625),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Column(
            children: [
              SizedBox(height: 22.h),
              Text(
                '影视剧解说',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '0基础也能解说大片',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                width: 150.w,
                height: 80.h,
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC391FF), Color(0xFF7628CB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '开启你的创作之旅',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      height: 20.h,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2F6DCD), Color(0xFF3C016F)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          '创建项目',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Container(
                width: 168.w,
                height: 105.h,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage(AppAssets.imageCreateBg),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22.r,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '影视剧解说工具！\n长按识别二维码，免费体验',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          height: 1.45,
                        ),
                      ),
                    ),
                    _QrCodeMock(text: inviteCode),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodeMock extends StatelessWidget {
  const _QrCodeMock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43.r,
      height: 43.r,
      padding: EdgeInsets.all(3.r),
      color: Colors.white,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 49,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemBuilder: (_, index) {
          final filled = (index + text.hashCode).abs() % 3 != 0;
          return Container(
            margin: const EdgeInsets.all(0.5),
            color: filled ? Colors.black : Colors.white,
          );
        },
      ),
    );
  }
}
