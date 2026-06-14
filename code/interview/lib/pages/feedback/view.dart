part of 'index.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final FeedbackController controller;

  @override
  void initState() {
    super.initState();
    controller = putFreshController(FeedbackController());
  }

  @override
  void dispose() {
    deleteControllerIfCurrent(controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.r),
          tooltip: '返回',
        ),
        title: Text(
          '意见反馈',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF071306), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(15.w, 16.h, 15.w, 30.h),
            children: [
              Text('反馈类型', style: _sectionTitleStyle()),
              SizedBox(height: 10.h),
              Obx(
                () => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.types.map((type) {
                    final selected = controller.type.value == type;
                    return ChoiceChip(
                      selected: selected,
                      label: Text(type.label),
                      onSelected: (_) => controller.selectType(type),
                      selectedColor: CustomTheme.primary,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      labelStyle: TextStyle(
                        color: selected ? Colors.black : Colors.white70,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 18.h),
              Text('问题描述', style: _sectionTitleStyle()),
              SizedBox(height: 10.h),
              _FeedbackInput(
                controller: controller.contentController,
                hintText: '请描述你遇到的问题或建议',
                minLines: 6,
                maxLines: 8,
              ),
              SizedBox(height: 14.h),
              Text('联系方式', style: _sectionTitleStyle()),
              SizedBox(height: 10.h),
              _FeedbackInput(
                controller: controller.contactController,
                hintText: '手机号 / 微信 / 邮箱，选填',
                minLines: 1,
                maxLines: 1,
              ),
              SizedBox(height: 24.h),
              Obx(
                () => AppButton(
                  label: '提交反馈',
                  loading: controller.submitting.value,
                  loadingLabel: '提交中',
                  onPressed: controller.submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle() {
    return TextStyle(
      color: Colors.white,
      fontSize: 15.sp,
      fontWeight: FontWeight.w800,
    );
  }
}

class _FeedbackInput extends StatelessWidget {
  const _FeedbackInput({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white38, fontSize: 14.sp),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: const BorderSide(color: CustomTheme.primary),
        ),
      ),
    );
  }
}
