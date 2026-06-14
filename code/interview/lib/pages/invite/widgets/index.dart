import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../widgets/index.dart';

const Color inviteBgTop = Color(0xFF071306);
const Color inviteBgBottom = Color(0xFF020402);
const Color invitePrimary = Color(0xFF78FF4F);
const Color invitePrimaryAlt = Color(0xFFB4FF00);
const Color inviteGreen = Color(0xFF76FF38);
const Color inviteTextMuted = Color(0xFF9A9A9A);

String inviteFormatYuan(int cents) {
  return (cents / 100).toStringAsFixed(2);
}

String inviteFormatMoney(int cents) {
  final yuan = cents / 100;
  return '¥${yuan.toStringAsFixed(yuan.truncateToDouble() == yuan ? 0 : 2)}';
}

class InviteScaffold extends StatelessWidget {
  const InviteScaffold({
    required this.title,
    required this.child,
    super.key,
    this.light = false,
  });

  final String title;
  final Widget child;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final foreground = light ? Colors.black : Colors.white;
    return CustomScaffold(
      backgroundColor: light ? Colors.white : inviteBgTop,
      appBar: AppBar(
        toolbarHeight: 48.h,
        leadingWidth: 52.w,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: foreground,
            size: 20.r,
          ),
          tooltip: '返回',
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: light ? Colors.white : null,
          gradient: light
              ? const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFEFF7FF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : const LinearGradient(
                  colors: [inviteBgTop, inviteBgBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(top: false, bottom: false, child: child),
      ),
    );
  }
}

class InviteGreenSectionTitle extends StatelessWidget {
  const InviteGreenSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5.w,
          height: 14.h,
          decoration: BoxDecoration(
            color: inviteGreen,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class InviteMenuRow extends StatelessWidget {
  const InviteMenuRow({required this.title, required this.onTap, super.key});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.r),
      child: Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 18.w),
        decoration: inviteCardDecoration(radius: 18.r),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20.r),
          ],
        ),
      ),
    );
  }
}

class InvitePanelCard extends StatelessWidget {
  const InvitePanelCard({
    required this.child,
    required this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: inviteCardDecoration(radius: 18.r),
      child: child,
    );
  }
}

class InviteTextInput extends StatelessWidget {
  const InviteTextInput({
    required this.controller,
    required this.hintText,
    super.key,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        cursorColor: invitePrimary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: inviteTextMuted, fontSize: 16.sp),
          filled: true,
          fillColor: const Color(0xFF333333).withValues(alpha: 0.15),
          contentPadding: EdgeInsets.symmetric(horizontal: 11.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.r),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.r),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.r),
            borderSide: BorderSide(color: invitePrimary.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}

class InviteGradientButton extends StatelessWidget {
  const InviteGradientButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: Opacity(
        opacity: onPressed == null ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [invitePrimary, invitePrimaryAlt, Color(0xFF2BDC3D)],
              stops: [0, 0.4, 1],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class InviteMemberTag extends StatelessWidget {
  const InviteMemberTag({super.key, this.text = '会员'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 17.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      decoration: BoxDecoration(
        color: inviteGreen,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontSize: 11.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class InviteEmptyPanel extends StatelessWidget {
  const InviteEmptyPanel({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 120.h),
      alignment: Alignment.center,
      decoration: inviteCardDecoration(radius: 18.r),
      child: Text(
        message,
        style: TextStyle(color: inviteTextMuted, fontSize: 14.sp),
      ),
    );
  }
}

class InviteDarkLoading extends StatelessWidget {
  const InviteDarkLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(color: invitePrimary, strokeWidth: 2.r),
    );
  }
}

class InviteDarkError extends StatelessWidget {
  const InviteDarkError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '邀请信息加载失败',
              style: TextStyle(color: Colors.white, fontSize: 15.sp),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: 140.w,
              child: InviteGradientButton(label: '重试', onPressed: onRetry),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration inviteCardDecoration({required double radius}) {
  return BoxDecoration(
    color: const Color(0xFF333333).withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
  );
}
