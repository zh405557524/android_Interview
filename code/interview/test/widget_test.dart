import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:narrate/apis/index.dart';
import 'package:narrate/enums/index.dart';
import 'package:narrate/models/index.dart';
import 'package:narrate/pages/account/index.dart';
import 'package:narrate/pages/creation/index.dart';
import 'package:narrate/pages/invite/index.dart';
import 'package:narrate/pages/invite/materials/index.dart';
import 'package:narrate/pages/invite/records/index.dart';
import 'package:narrate/pages/main/index.dart';
import 'package:narrate/pages/membership/index.dart';
import 'package:narrate/pages/payment_orders/index.dart';
import 'package:narrate/pages/points/recharge/index.dart';
import 'package:narrate/pages/settings/index.dart';
import 'package:narrate/pages/task_center/index.dart';
import 'package:narrate/routes/index.dart';
import 'package:narrate/services/index.dart';
import 'package:narrate/store/index.dart';
import 'package:narrate/theme.dart';
import 'package:narrate/utils/index.dart';
import 'package:narrate/widgets/index.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:narrate/main.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<MockService>(MockService());
    Get.put<HttpService>(HttpService());
    Get.put<ConfigStore>(ConfigStore());
    Get.find<ConfigStore>().setMockEnabled(true);
    Get.put<UserStore>(UserStore());
    Get.put<CreationStore>(CreationStore());
    Get.put<CreationConfigService>(CreationConfigService());
    Get.put<LoginService>(LoginService());
    Get.put<AppUpdateService>(AppUpdateService());
  });

  test('app static page parses backend url', () {
    final page = AppStaticPage.fromJson(<String, dynamic>{
      'key': 'user-agreement',
      'title': '用户协议',
      'content': '正文',
      'url': 'https://test-static.lxwx.local/agreement/userAgreement.html',
    });

    expect(page.key, 'user-agreement');
    expect(page.title, '用户协议');
    expect(page.content, '正文');
    expect(
      page.url,
      'https://test-static.lxwx.local/agreement/userAgreement.html',
    );
  });

  test('invite models parse backend share urls and legacy names', () {
    final overview = InviteOverview.fromJson(<String, dynamic>{
      'inviteCode': 'JS2026',
      'visitUrl':
          'https://test-static.lxwx.local/invite/register.html?inviteCode=JS2026',
      'ruleSummary': '规则',
      'rewardPoints': 10,
    });
    final material = InviteMaterial.fromJson(<String, dynamic>{
      'inviteCode': 'JS2026',
      'visitUrl':
          'https://test-static.lxwx.local/invite/register.html?inviteCode=JS2026',
      'downloadUrl': 'https://test-static.lxwx.local/invite/download.html',
    });

    expect(
      overview.inviteLink,
      'https://test-static.lxwx.local/invite/register.html?inviteCode=JS2026',
    );
    expect(
      material.inviteLink,
      'https://test-static.lxwx.local/invite/register.html?inviteCode=JS2026',
    );
    expect(
      material.landingDownloadUrl,
      'https://test-static.lxwx.local/invite/download.html',
    );
  });

  test('task center models parse backend overview and check-in result', () {
    final overview = TaskCenterOverview.fromJson(const <String, dynamic>{
      'enabled': true,
      'totalPoints': 23,
      'checkIn': {
        'signedToday': false,
        'consecutiveDays': 1,
        'cycleDay': 2,
        'todayRewardPoints': 3,
        'days': [
          {'day': 1, 'rewardPoints': 3, 'checked': true, 'current': false},
          {'day': 2, 'rewardPoints': 3, 'checked': false, 'current': true},
        ],
      },
      'dailyTasks': [
        {
          'code': 'INVITE_FRIEND',
          'title': '邀请好友领积分',
          'description': '邀请好友注册',
          'target': 1,
          'progress': 0,
          'rewardText': '+10/人',
          'actionText': '去邀请',
          'routeName': 'inviteMaterials',
          'completed': false,
          'enabled': true,
        },
      ],
    });
    final result = TaskCheckInResult.fromJson(const <String, dynamic>{
      'signedToday': true,
      'firstTime': true,
      'rewardPoints': 3,
      'totalPoints': 26,
      'consecutiveDays': 2,
      'cycleDay': 2,
      'days': [
        {'day': 1, 'rewardPoints': 3, 'checked': true, 'current': false},
        {'day': 2, 'rewardPoints': 3, 'checked': true, 'current': true},
      ],
    });

    expect(overview.totalPoints, 23);
    expect(overview.checkIn.days.last.current, isTrue);
    expect(overview.inviteTask?.title, '邀请好友领积分');
    expect(result.totalPoints, 26);
    expect(result.days.last.checked, isTrue);
  });

  test('app update model parses backend policy response', () {
    final update = AppUpdateInfo.fromJson(const <String, dynamic>{
      'enabled': true,
      'updateAvailable': true,
      'forceUpdate': true,
      'latestVersionName': '1.2.0',
      'latestVersionCode': 120,
      'actionType': 'DOWNLOAD_APK',
      'downloadUrl': 'https://download.example.com/narrate.apk',
      'storeUrl': '',
      'title': '发现新版本',
      'message': '请升级',
      'releaseNotes': ['修复问题', '优化体验'],
    });

    expect(update.enabled, isTrue);
    expect(update.updateAvailable, isTrue);
    expect(update.forceUpdate, isTrue);
    expect(update.actionType, AppUpdateActionType.downloadApk);
    expect(update.hasActionUrl, isTrue);
    expect(update.actionUrl, 'https://download.example.com/narrate.apk');
    expect(update.releaseNotes, hasLength(2));
  });

  testWidgets('renders narrate shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('开启你的创作之旅'), findsOneWidget);
    expect(find.text('创作'), findsOneWidget);
    expect(find.text('作品'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('account page shows task center above payment orders', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const AccountPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final taskCenterY = tester.getTopLeft(find.text('任务中心')).dy;
    final paymentY = tester.getTopLeft(find.text('支付订单')).dy;
    final redeemY = tester.getTopLeft(find.text('兑换码')).dy;
    final feedbackY = tester.getTopLeft(find.text('意见反馈')).dy;

    expect(taskCenterY, lessThan(paymentY));
    expect(paymentY, lessThan(redeemY));
    expect(redeemY, lessThan(feedbackY));
  });

  testWidgets('task center uses app tone and keeps ads hidden', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const TaskCenterPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('任务中心'), findsOneWidget);
    expect(find.text('总积分：120'), findsOneWidget);
    expect(find.text('连续签到领积分'), findsOneWidget);
    expect(find.text('每日任务'), findsOneWidget);
    expect(find.text('邀请好友领积分'), findsOneWidget);
    expect(find.text('看视频领积分'), findsNothing);
    expect(find.text('看广告领积分'), findsNothing);

    await tester.tap(find.text('签到领取'));
    await tester.pumpAndSettle();

    expect(find.text('已签到'), findsOneWidget);
    expect(find.text('总积分：124'), findsOneWidget);
  });

  testWidgets('task center invite action opens promotion materials', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);
    Get.find<UserStore>().setSession(
      accessToken: 'task-center-token',
      phone: '139****0008',
      inviteCode: 'TASK88',
      initialPoints: 120,
      vip: true,
    );

    final router = GoRouter(
      initialLocation: '/task-center',
      routes: <RouteBase>[
        GoRoute(
          path: '/task-center',
          name: RouteName.taskCenter,
          builder: (context, state) => const TaskCenterPage(),
        ),
        GoRoute(
          path: '/invite/materials',
          name: RouteName.inviteMaterials,
          builder: (context, state) => const InviteMaterialsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('去邀请'));
    await tester.pumpAndSettle();

    expect(find.text('推广素材'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('invite-materials')),
      findsOneWidget,
    );
  });

  testWidgets('login page back pops to the previous page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建项目'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('开启你的创作之旅'), findsOneWidget);
  });

  testWidgets('home category selection changes even when cases are empty', (
    WidgetTester tester,
  ) async {
    BoxDecoration categoryDecoration(String label) {
      final containers = tester.widgetList<Container>(
        find.ancestor(of: find.text(label), matching: find.byType(Container)),
      );
      return containers
          .map((widget) => widget.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((decoration) {
            return decoration.borderRadius != null &&
                (decoration.gradient != null || decoration.color != null);
          });
    }

    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>()
      ..configure(defaultDelay: Duration.zero)
      ..setEmptyFor('home.cases');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('暂无热门案例'), findsOneWidget);
    expect(categoryDecoration('热门').gradient, isNotNull);
    expect(categoryDecoration('短剧解说').gradient, isNull);

    await tester.tap(find.text('短剧解说'));
    await tester.pumpAndSettle();

    expect(find.text('暂无短剧解说案例'), findsOneWidget);
    expect(categoryDecoration('热门').gradient, isNull);
    expect(categoryDecoration('短剧解说').gradient, isNotNull);
  });

  testWidgets('creation success emits refresh and opens works tab', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.put<EventService>(EventService());
    Get.put<MainController>(MainController());
    Get.find<MockService>().configure(defaultDelay: Duration.zero);
    var refreshEventCount = 0;
    final subscription = Get.find<EventService>()
        .on<WorksListRefreshRequested>()
        .listen((_) => refreshEventCount += 1);
    addTearDown(subscription.cancel);

    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: RouteName.main,
          builder: (context, state) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => context.pushNamed(RouteName.creationVideo),
                child: const Text('打开创作'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/creation',
          name: RouteName.creationVideo,
          builder: (context, state) => const CreationPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开创作'));
    await tester.pumpAndSettle();
    expect(find.text('视频解说'), findsOneWidget);

    final creationContext = tester.element(find.byType(CreationPage));
    Get.find<CreationController>().finishCreatedWork(creationContext);
    await tester.pumpAndSettle();

    expect(refreshEventCount, 1);
    expect(Get.find<MainController>().currentIndex.value, 1);
    expect(find.text('打开创作'), findsOneWidget);
  });

  testWidgets('creation page stays visible when config load fails', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>()
      ..configure(defaultDelay: Duration.zero)
      ..setFailureFor('creation.styles', message: '创作配置加载失败');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const CreationPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('视频解说'), findsOneWidget);
    expect(find.text('解说风格'), findsOneWidget);
    expect(find.text('配音角色'), findsOneWidget);
    expect(find.text('加载创作配置...'), findsNothing);
    expect(find.text('创作配置加载失败'), findsNothing);
  });

  testWidgets('creation style tap loads missing config before opening sheet', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>()
      ..configure(defaultDelay: Duration.zero)
      ..setEmptyFor('creation.styles');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const CreationPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(Get.find<CreationController>().styles, isEmpty);

    Get.find<MockService>().setEmptyFor('creation.styles', enabled: false);
    await tester.tap(find.text('解说风格'));
    await tester.pumpAndSettle();

    expect(find.text('真实解说风格'), findsOneWidget);
  });

  testWidgets('works page batch management hides selected work', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);
    Get.find<UserStore>().setSession(
      accessToken: 'works-access-token',
      phone: '139****0003',
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(theme: CustomTheme.dark, home: const MainPage());
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('作品'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('管理'), findsOneWidget);

    await tester.tap(find.byTooltip('管理'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, '完成'), findsOneWidget);
    expect(find.text('已选 0 个'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsWidgets);

    final firstWorkCard = find
        .ancestor(of: find.text('夜晚的城市街道'), matching: find.byType(InkWell))
        .first;
    await tester.tap(firstWorkCard);
    await tester.pumpAndSettle();

    expect(find.text('已选 1 个'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除作品'), findsOneWidget);
    expect(find.text('删除后将不在我的作品中展示'), findsOneWidget);

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(find.text('夜晚的城市街道'), findsNothing);
    expect(find.widgetWithText(TextButton, '完成'), findsNothing);
  });

  testWidgets('settings page uses unified confirm dialog and hides delete', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const SettingsPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('检查更新'), findsOneWidget);

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(find.text('确定退出当前账号吗？'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.text('账号与安全'), findsOneWidget);
    expect(find.text('注销账号'), findsNothing);
  });

  testWidgets('account security page shows delete account bottom sheet', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const AccountSecurityPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '注销账号'));
    await tester.pumpAndSettle();

    expect(find.text('注销账号'), findsNWidgets(2));
    expect(find.text('注销后账号资料、历史记录等将无法恢复。\n请确认你已经了解相关影响。'), findsOneWidget);
    expect(find.text('我再想想'), findsOneWidget);
    expect(find.text('确认注销账号'), findsOneWidget);

    await tester.tap(find.text('我再想想'));
    await tester.pumpAndSettle();

    expect(find.text('确认注销账号'), findsNothing);
  });

  testWidgets('settings account security entry opens subpage', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: <RouteBase>[
        GoRoute(
          path: '/settings',
          name: RouteName.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/settings/account-security',
          name: RouteName.accountSecurity,
          builder: (context, state) => const AccountSecurityPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('账号与安全'));
    await tester.pumpAndSettle();

    expect(find.byType(AccountSecurityPage), findsOneWidget);
    expect(find.widgetWithText(TextButton, '注销账号'), findsOneWidget);
  });

  testWidgets('settings logout returns to main home tab', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);
    Get.find<UserStore>().setSession(
      accessToken: 'settings-logout-token',
      phone: '138****0001',
    );
    final mainController = Get.put<MainController>(
      MainController(),
      permanent: true,
    )..showAccountTab();

    final router = GoRouter(
      initialLocation: '/settings',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: RouteName.main,
          builder: (context, state) => const MainPage(),
        ),
        GoRoute(
          path: '/settings',
          name: RouteName.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/settings/account-security',
          name: RouteName.accountSecurity,
          builder: (context, state) => const AccountSecurityPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('退出登录'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(mainController.currentIndex.value, 0);
    expect(Get.find<UserStore>().isLoggedIn, isFalse);
    expect(find.text('开启你的创作之旅'), findsOneWidget);
  });

  testWidgets('settings delete account clears session and returns home', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _SettingsDeleteAccountAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'settings-delete-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('settings-delete-token');
    final mainController = Get.put<MainController>(
      MainController(),
      permanent: true,
    )..showAccountTab();

    final router = GoRouter(
      initialLocation: '/settings/account-security',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: RouteName.main,
          builder: (context, state) => const MainPage(),
        ),
        GoRoute(
          path: '/settings',
          name: RouteName.settings,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/settings/account-security',
          name: RouteName.accountSecurity,
          builder: (context, state) => const AccountSecurityPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '注销账号'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认注销账号'));
    await tester.pumpAndSettle();

    expect(adapter.paths, contains('/api/user/delete-request'));
    expect(mainController.currentIndex.value, 0);
    expect(Get.find<UserStore>().isLoggedIn, isFalse);
    expect(
      Get.find<HttpService>().client.options.headers.containsKey(
        'Authorization',
      ),
      isFalse,
    );
    expect(find.text('开启你的创作之旅'), findsOneWidget);
  });

  testWidgets('membership plan selection updates immediately', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const MembershipPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final controller = Get.find<MembershipController>();
    expect(controller.selectedPlanId.value, 'vip_month');
    expect(find.text('订单'), findsNothing);

    await tester.tap(find.text('季卡套'));
    await tester.pump();

    expect(controller.selectedPlanId.value, 'vip_quarter');
  });

  testWidgets('membership payment success refreshes user and pops page', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter()..pendingOrderStatus = 1;
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');
    final mainController = Get.put<MainController>(
      MainController(),
      permanent: true,
    )..showHomeTab();
    Get.put<PaymentGatewayService>(
      PaymentGatewayService(
        alipayExecutor: (_, _) async => <String, dynamic>{
          'resultStatus': '9000',
          'memo': 'success',
        },
      ),
    );

    final router = _paymentPageRouter(
      paymentPath: '/membership',
      paymentRouteName: RouteName.membership,
      paymentPage: const MembershipPage(),
      openButtonLabel: '打开会员页',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开会员页'));
    await tester.pumpAndSettle();

    final controller = Get.find<MembershipController>();
    controller.toggleAgreement(true);
    await tester.pump();
    await tester.tap(find.text('立即充值'));
    await tester.pumpAndSettle();

    expect(find.text('支付来源页'), findsOneWidget);
    expect(find.text('VIP会员'), findsNothing);
    expect(Get.find<UserStore>().isVip.value, isTrue);
    expect(Get.find<UserStore>().points.value, 88);
    expect(mainController.currentIndex.value, 0);
    expect(
      adapter.requests.map((item) => item.path),
      containsAll(<String>[
        '/api/tbOrder/creOrder',
        '/api/tbOrder/selectOne',
        '/api/user/profile',
      ]),
    );
  });

  testWidgets('points recharge exposes alipay as the only payment channel', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const PointsRechargePage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支付宝'), findsOneWidget);
    expect(find.text('微信'), findsNothing);
    expect(find.text('订单'), findsNothing);

    final controller = Get.find<PointsRechargeController>();
    expect(controller.selectedPackageId.value, 'points_30');
    expect(
      find.byKey(const ValueKey<String>('points-package-points_30-true')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('points-package-points_50-false')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('points-package-points_50-false')),
    );
    await tester.pump();

    expect(controller.selectedPackageId.value, 'points_50');
    expect(
      find.byKey(const ValueKey<String>('points-package-points_50-true')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('points-package-points_30-false')),
      findsOneWidget,
    );
  });

  testWidgets('points recharge payment success refreshes user and pops page', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter()..pendingOrderStatus = 1;
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');
    final mainController = Get.put<MainController>(
      MainController(),
      permanent: true,
    )..showHomeTab();
    Get.put<PaymentGatewayService>(
      PaymentGatewayService(
        alipayExecutor: (_, _) async => <String, dynamic>{
          'resultStatus': '9000',
          'memo': 'success',
        },
      ),
    );

    final router = _paymentPageRouter(
      paymentPath: '/points/recharge',
      paymentRouteName: RouteName.pointsRecharge,
      paymentPage: const PointsRechargePage(),
      openButtonLabel: '打开积分充值页',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开积分充值页'));
    await tester.pumpAndSettle();

    final controller = Get.find<PointsRechargeController>();
    controller.toggleAgreement(true);
    await tester.pump();
    await tester.tap(find.text('立即充值'));
    await tester.pumpAndSettle();

    expect(find.text('支付来源页'), findsOneWidget);
    expect(find.text('积分充值'), findsNothing);
    expect(Get.find<UserStore>().points.value, 88);
    expect(Get.find<UserStore>().isVip.value, isTrue);
    expect(mainController.currentIndex.value, 0);
    expect(
      adapter.requests.map((item) => item.path),
      containsAll(<String>[
        '/api/tbOrder/creOrder',
        '/api/tbOrder/selectOne',
        '/api/user/profile',
      ]),
    );
  });

  testWidgets('payment orders page filters and shows retry action', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const PaymentOrdersPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支付订单'), findsOneWidget);
    expect(find.text('月卡套'), findsOneWidget);
    expect(find.text('30元积套'), findsOneWidget);
    expect(find.text('继续支付'), findsOneWidget);
    expect(find.text('取消订单'), findsOneWidget);
    expect(find.text('删除订单'), findsOneWidget);

    await tester.tap(find.text('积分'));
    await tester.pumpAndSettle();

    expect(find.text('月卡套'), findsNothing);
    expect(find.text('30元积套'), findsOneWidget);
    expect(find.text('继续支付'), findsNothing);
    expect(find.text('取消订单'), findsNothing);
    expect(find.text('删除订单'), findsOneWidget);
  });

  testWidgets('payment order actions require confirmation', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const PaymentOrdersPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    adapter.requests.clear();
    await tester.tap(find.text('取消订单'));
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(find.text('取消后该订单将无法继续支付，确认取消吗？'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.map((item) => item.path),
      isNot(contains('/api/tbOrder/upOrder')),
    );

    await tester.tap(find.text('取消订单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认取消'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((item) => item.path),
      contains('/api/tbOrder/upOrder'),
    );
    expect(find.text('继续支付'), findsNothing);

    await tester.tap(find.text('积分'));
    await tester.pumpAndSettle();
    adapter.requests.clear();
    await tester.tap(find.text('删除订单'));
    await tester.pumpAndSettle();

    expect(find.byType(AppConfirmDialog), findsOneWidget);
    expect(find.text('删除后该订单将不再展示，确认删除吗？'), findsOneWidget);
    await tester.tap(find.text('确认删除'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((item) => item.path),
      contains('/api/tbOrder/delOrder'),
    );
    expect(find.text('30元积套'), findsNothing);
  });

  testWidgets('payment order retry loads detail before sdk pay', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');
    Get.put<PaymentGatewayService>(
      PaymentGatewayService(
        alipayExecutor: (_, _) async => <String, dynamic>{
          'resultStatus': '6001',
          'memo': 'cancel',
        },
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const PaymentOrdersPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    adapter.requests.clear();
    await tester.tap(find.text('继续支付'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.map((item) => item.path),
      contains('/api/tbOrder/selectOne'),
    );
    expect(
      adapter.requests.map((item) => item.path),
      isNot(contains('/api/tbOrder/reqPayment')),
    );
  });

  testWidgets('payment order retry success still opens account tab', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'widget-payment-token',
      phone: '138****0001',
    );
    Get.find<HttpService>().setToken('widget-payment-token');
    final mainController = Get.put<MainController>(
      MainController(),
      permanent: true,
    )..showHomeTab();
    Get.put<PaymentGatewayService>(
      PaymentGatewayService(
        alipayExecutor: (_, _) async {
          adapter.pendingOrderStatus = 1;
          return <String, dynamic>{'resultStatus': '9000', 'memo': 'success'};
        },
      ),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const PaymentOrdersPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    adapter.requests.clear();
    await tester.tap(find.text('继续支付'));
    await tester.pumpAndSettle();

    expect(mainController.currentIndex.value, 2);
    expect(Get.find<UserStore>().points.value, 88);
    expect(
      adapter.requests.map((item) => item.path),
      containsAll(<String>[
        '/api/tbOrder/selectOne',
        '/api/user/profile',
        '/api/tbOrder/tbOrderList',
      ]),
    );
  });

  test(
    'payment requestPayment sends id and orderId for compatibility',
    () async {
      final adapter = _WidgetPaymentProductAdapter();
      Get.find<HttpService>().client.httpClientAdapter = adapter;
      Get.find<ConfigStore>()
        ..setMockEnabled(false)
        ..setApiBaseUrl('http://api.test');

      await PaymentAPI.requestPayment(
        orderId: 'PAY202606010001',
        channel: PaymentChannel.alipay,
        fallbackPurpose: PaymentPurpose.membership,
        fallbackProductId: 'vip_month',
      );

      final request = adapter.requests.lastWhere(
        (item) => item.path == '/api/tbOrder/reqPayment',
      );
      final data = Map<String, dynamic>.from(request.data as Map);
      expect(data['id'], 'PAY202606010001');
      expect(data['orderId'], 'PAY202606010001');
      expect(data['type'], '1');
    },
  );

  test('voice config parser accepts backend field aliases', () {
    final role = VoiceRole.fromConfigJson(<String, dynamic>{
      'voice_id': 'vod-clone-jieshuonan1',
      'voice_name': '专业解说男',
      'desc': '百度智能集锦推荐解说音色',
      'sample_url':
          'https://vodstatic1.exp.bcevod.com/voices/sample_url/demo.mp3',
      'cover_url': 'https://vodstatic1.exp.bcevod.com/voices/cover/man.png',
      'sex': 'man',
      'lang': <String>['zh-CN', 'en-US'],
      'is_recommend': 1,
      'is_new_voice': 'true',
      'sort_order': '3',
      'tags': '开心,沉稳',
    });

    expect(role.id, 'vod-clone-jieshuonan1');
    expect(role.name, '专业解说男');
    expect(role.description, '百度智能集锦推荐解说音色');
    expect(
      role.auditionUrl,
      'https://vodstatic1.exp.bcevod.com/voices/sample_url/demo.mp3',
    );
    expect(role.coverUrl, contains('/cover/man.png'));
    expect(role.gender, 'man');
    expect(role.language, 'zh-CN,en-US');
    expect(role.recommend, isTrue);
    expect(role.newVoice, isTrue);
    expect(role.sortOrder, 3);
    expect(role.emotionTags, <String>['开心', '沉稳']);
  });

  test('quick generation file serializes video upload type', () {
    final json = const QuickGenerationFile(
      clientFileId: 'local_001',
      fileName: 'demo.mp4',
      fileSize: 1024,
      contentType: 'video/mp4',
      durationSeconds: 12,
    ).toJson();

    expect(json['type'], 'VIDEO');
    expect(json['uploadType'], isNull);
  });

  test('work parser maps Baidu project type values', () {
    final shortSeries = Work.fromJson(<String, dynamic>{
      'id': 'work_short',
      'title': '短剧作品',
      'status': 'ACTIVE',
      'workType': 'ShortSeries',
    });
    final movie = Work.fromJson(<String, dynamic>{
      'id': 'work_movie',
      'title': '电影作品',
      'status': 'ACTIVE',
      'workType': 'Movie',
    });
    final legacyVideo = Work.fromJson(<String, dynamic>{
      'id': 'work_legacy',
      'title': '旧视频作品',
      'status': 'ACTIVE',
      'workType': 'VIDEO',
    });

    expect(shortSeries.workType, WorkType.shortSeries);
    expect(movie.workType, WorkType.movie);
    expect(legacyVideo.workType, WorkType.shortSeries);
    expect(WorkType.shortSeries.acceptsDuration(20 * 60), isTrue);
    expect(WorkType.shortSeries.acceptsDuration(20 * 60 + 1), isFalse);
    expect(WorkType.movie.acceptsDuration(60 * 60), isTrue);
    expect(WorkType.tvSeries.acceptsDuration(30 * 60), isTrue);
  });

  test('work detail parses multiple video variants', () {
    final detail = WorkDetail.fromJson(<String, dynamic>{
      'id': 'work_001',
      'title': '多样性作品',
      'status': 'succeeded',
      'resources': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'VIDEO',
          'resourceId': 'normal',
          'title': '常规版',
          'url': 'https://cdn.test/work-normal.mp4',
          'downloadUrl': 'https://cdn.test/download-normal.mp4',
        },
        <String, dynamic>{
          'type': 'VIDEO',
          'resourceId': 'variant',
          'title': '多样版',
          'url': 'https://cdn.test/work-variant.mp4',
        },
      ],
    });

    expect(detail.videoUrl, 'https://cdn.test/work-normal.mp4');
    expect(detail.downloadUrl, 'https://cdn.test/download-normal.mp4');
    expect(detail.videoVariants, hasLength(2));
    expect(detail.videoVariants[1].id, 'variant');
    expect(detail.videoVariants[1].title, '多样版');
  });

  testWidgets('creation generate redirects to login when unauthenticated', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    final router = GoRouter(
      initialLocation: '/creation',
      routes: <RouteBase>[
        GoRoute(
          path: '/creation',
          name: RouteName.creationVideo,
          builder: (context, state) => const CreationPage(),
        ),
        GoRoute(
          path: '/login',
          name: RouteName.login,
          builder: (context, state) => const Scaffold(body: Text('登录页')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // CreationController 不再预置 mock 素材，测试里显式准备一份真实页面状态。
    final controller = Get.find<CreationController>();
    controller
      ..loading.value = false
      ..errorMessage.value = null;
    controller.styles.assignAll(const <CreationStyle>[
      CreationStyle(
        id: 'style_real',
        name: '真实解说风格',
        mode: CreationMode.narration,
        description: '用于测试真实交互入口',
      ),
    ]);
    controller.voices.assignAll(const <VoiceRole>[
      VoiceRole(
        id: 'voice_real',
        name: '真实配音',
        description: '用于测试真实交互入口',
        emotionTags: <String>['通用'],
      ),
    ]);
    controller.materials.assignAll(const <CreationMaterial>[
      CreationMaterial(
        id: 'local_test_video',
        name: '测试视频.mp4',
        durationText: '00:00:12',
        durationSeconds: 12,
        thumbUrl: '',
        status: MaterialStatus.ready,
        filePath: '/tmp/test-video.mp4',
        fileSize: 1024,
        contentType: 'video/mp4',
      ),
    ]);
    controller.store.selectedMaterialIds.assignAll(<String>[
      'local_test_video',
    ]);
    await tester.pump();

    await tester.tap(find.text('立即生成'));
    await tester.pumpAndSettle();

    expect(find.text('登录页'), findsOneWidget);
  });

  testWidgets('account page keeps content visible when profile load fails', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.find<MockService>()
      ..configure(defaultDelay: Duration.zero)
      ..setFailureFor('user.profile', message: '用户信息加载失败');
    Get.find<UserStore>().setSession(
      accessToken: 'cached-token',
      phone: '139****0002',
      inviteCode: 'CACHE42',
      initialPoints: 66,
      vip: true,
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const AccountPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('139****0002'), findsOneWidget);
    expect(find.text('邀请好友'), findsOneWidget);
    expect(find.text('支付订单'), findsOneWidget);
    expect(find.text('意见反馈'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('支付订单')).dy,
      lessThan(tester.getTopLeft(find.text('意见反馈')).dy),
    );
    expect(find.text('用户信息加载失败'), findsNothing);
  });

  testWidgets('invite entry opens records subflow through route', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.find<MockService>().configure(defaultDelay: Duration.zero);
    Get.find<UserStore>().setSession(
      accessToken: 'invite-token',
      phone: '139****0003',
      inviteCode: 'CACHE42',
      initialPoints: 66,
      vip: true,
    );

    final router = GoRouter(
      initialLocation: '/invite',
      routes: <RouteBase>[
        GoRoute(
          path: '/invite',
          name: RouteName.invite,
          builder: (context, state) => const InvitePage(),
        ),
        GoRoute(
          path: '/invite/records',
          name: RouteName.inviteRecords,
          builder: (context, state) => const InviteRecordsPage(),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收益'), findsOneWidget);
    expect(find.text('可提现收益  (元)'), findsOneWidget);
    expect(find.text('邀请列表'), findsOneWidget);

    await tester.tap(find.text('邀请列表'));
    await tester.pumpAndSettle();

    expect(find.byType(InviteRecordsPage), findsOneWidget);
    expect(find.text('我的团队'), findsOneWidget);
    expect(find.text('搜索手机号'), findsOneWidget);
    expect(find.text('198****4280'), findsOneWidget);
  });

  testWidgets('invite records load mock data and support local filters', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const InviteRecordsPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('198****4280'), findsOneWidget);
    expect(find.text('198****4281'), findsOneWidget);
    expect(find.text('198****4282'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4281');
    await tester.pump();

    expect(find.text('198****4281'), findsOneWidget);
    expect(find.text('198****4280'), findsNothing);
    expect(find.text('198****4282'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('仅注册'));
    await tester.pump();

    expect(find.text('198****4282'), findsOneWidget);
    expect(find.text('198****4280'), findsNothing);
  });

  testWidgets('account payment order entry opens orders when logged in', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final adapter = _WidgetPaymentProductAdapter();
    Get.find<HttpService>().client.httpClientAdapter = adapter;
    Get.find<ConfigStore>()
      ..setMockEnabled(false)
      ..setApiBaseUrl('http://api.test');
    Get.find<UserStore>().setSession(
      accessToken: 'account-payment-token',
      phone: '139****0002',
      inviteCode: 'CACHE42',
      initialPoints: 66,
      vip: true,
    );
    Get.find<HttpService>().setToken('account-payment-token');

    final router = GoRouter(
      initialLocation: '/account',
      routes: <RouteBase>[
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: '/payment/orders',
          name: RouteName.paymentOrders,
          builder: (context, state) => const PaymentOrdersPage(),
        ),
        GoRoute(
          path: '/login',
          name: RouteName.login,
          builder: (context, state) => const Scaffold(body: Text('登录页')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('支付订单'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('支付订单')).dy,
      lessThan(tester.getTopLeft(find.text('意见反馈')).dy),
    );

    await tester.tap(find.text('支付订单'));
    await tester.pumpAndSettle();

    expect(find.text('支付订单'), findsWidgets);
    expect(find.text('月卡套'), findsOneWidget);
  });

  testWidgets('account page shows guest state when unauthenticated', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp(
            theme: CustomTheme.dark,
            home: const AccountPage(),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('未登录'), findsOneWidget);
    expect(find.text('立即登录'), findsOneWidget);
    expect(find.text('登录后查看积分、作品和邀请奖励'), findsOneWidget);
    expect(find.text('支付订单'), findsOneWidget);
    expect(find.textContaining('邀请码:'), findsNothing);
  });

  testWidgets('account payment order entry redirects guest to login', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.find<MockService>().configure(defaultDelay: Duration.zero);

    final router = GoRouter(
      initialLocation: '/account',
      routes: <RouteBase>[
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountPage(),
        ),
        GoRoute(
          path: '/login',
          name: RouteName.login,
          builder: (context, state) => const Scaffold(body: Text('登录页')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) {
          return MaterialApp.router(
            theme: CustomTheme.dark,
            routerConfig: router,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('支付订单'));
    await tester.pumpAndSettle();

    expect(find.text('登录页'), findsOneWidget);
  });

  testWidgets('voice sheet hides emotion area when role has no tags', (
    WidgetTester tester,
  ) async {
    final originalFactory = creationVoiceAuditionPlayerFactory;
    creationVoiceAuditionPlayerFactory = _FakeCreationVoiceAuditionPlayer.new;
    addTearDown(() {
      creationVoiceAuditionPlayerFactory = originalFactory;
    });
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<({String voiceId, String emotion})?>? sheetResult;
    await tester.pumpWidget(
      _VoiceSheetTestApp(
        onOpen: (context) {
          sheetResult = showCreationVoiceSheet(
            context,
            voices: const <VoiceRole>[
              VoiceRole(
                id: 'voice_plain',
                name: '无标签角色',
                description: '',
                emotionTags: <String>[],
              ),
            ],
            emotions: const <String>['通用'],
            initialVoiceId: 'voice_plain',
            initialEmotion: '通用',
          );
        },
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    expect(find.text('无标签角色'), findsOneWidget);
    expect(find.text('已选择'), findsOneWidget);
    expect(find.textContaining('情绪：'), findsNothing);
    expect(find.text('通用'), findsNothing);

    await tester.tap(find.text('确定'));
    final result = await sheetResult;

    expect(result?.voiceId, 'voice_plain');
    expect(result?.emotion, '');
  });

  testWidgets('voice sheet shows role emotion tags when available', (
    WidgetTester tester,
  ) async {
    final originalFactory = creationVoiceAuditionPlayerFactory;
    creationVoiceAuditionPlayerFactory = _FakeCreationVoiceAuditionPlayer.new;
    addTearDown(() {
      creationVoiceAuditionPlayerFactory = originalFactory;
    });
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<({String voiceId, String emotion})?>? sheetResult;
    await tester.pumpWidget(
      _VoiceSheetTestApp(
        onOpen: (context) {
          sheetResult = showCreationVoiceSheet(
            context,
            voices: const <VoiceRole>[
              VoiceRole(
                id: 'voice_happy',
                name: '有标签角色',
                description: '',
                emotionTags: <String>['开心'],
              ),
            ],
            emotions: const <String>['通用'],
            initialVoiceId: 'voice_happy',
            initialEmotion: '通用',
          );
        },
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    expect(find.text('有标签角色'), findsOneWidget);
    expect(find.text('情绪：开心'), findsOneWidget);
    expect(find.text('开心'), findsOneWidget);
    expect(find.text('通用'), findsNothing);

    await tester.tap(find.text('确定'));
    final result = await sheetResult;

    expect(result?.voiceId, 'voice_happy');
    expect(result?.emotion, '开心');
  });

  testWidgets('voice sheet shows backend tags and plays audition url', (
    WidgetTester tester,
  ) async {
    final originalFactory = creationVoiceAuditionPlayerFactory;
    late _FakeCreationVoiceAuditionPlayer player;
    creationVoiceAuditionPlayerFactory = () {
      player = _FakeCreationVoiceAuditionPlayer();
      return player;
    };
    addTearDown(() {
      creationVoiceAuditionPlayerFactory = originalFactory;
    });
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _VoiceSheetTestApp(
        onOpen: (context) {
          showCreationVoiceSheet(
            context,
            voices: const <VoiceRole>[
              VoiceRole(
                id: 'vod-clone-jieshuonan1',
                name: '专业解说男',
                description: '百度智能集锦推荐解说音色',
                emotionTags: <String>[],
                coverUrl:
                    'https://vodstatic1.exp.bcevod.com/voices/cover/man.png',
                gender: 'man',
                language: 'zh-CN',
                recommend: true,
                newVoice: true,
                sortOrder: 1,
                auditionUrl:
                    'https://vodstatic1.exp.bcevod.com/voices/sample_url/vod-clone-jieshuonan1.mp3',
              ),
            ],
            emotions: const <String>['通用'],
            initialVoiceId: 'vod-clone-jieshuonan1',
            initialEmotion: '',
          );
        },
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    expect(find.text('专业解说男'), findsOneWidget);
    expect(find.text('百度智能集锦推荐解说音色'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('新'), findsOneWidget);
    expect(find.text('男声'), findsOneWidget);

    await tester.tap(find.text('试听'));
    await tester.pump();

    expect(player.playedUrls, <String>[
      'https://vodstatic1.exp.bcevod.com/voices/sample_url/vod-clone-jieshuonan1.mp3',
    ]);
    expect(find.text('停止'), findsOneWidget);

    await tester.tap(find.text('停止'));
    await tester.pump();

    expect(player.stopCount, greaterThanOrEqualTo(1));
    expect(find.text('试听'), findsOneWidget);
  });

  testWidgets('more settings sheet uses diversified label and returns switch', (
    WidgetTester tester,
  ) async {
    tester.view
      ..physicalSize = const Size(375, 812)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<({bool diversifiedVersionsEnabled})?>? sheetResult;
    await tester.pumpWidget(
      _VoiceSheetTestApp(
        onOpen: (context) {
          sheetResult = showCreationMoreSettingsSheet(
            context,
            initialDiversifiedVersionsEnabled: false,
          );
        },
      ),
    );

    await tester.tap(find.text('打开弹层'));
    await tester.pumpAndSettle();

    expect(find.text('视频多样性'), findsOneWidget);
    expect(find.text('背景音乐'), findsNothing);
    expect(find.text('解说风格'), findsNothing);

    final switchFinder = find.byWidgetPredicate((widget) {
      return widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == AppAssets.iconSwitchOff;
    });
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    final result = await sheetResult;

    expect(result?.diversifiedVersionsEnabled, isTrue);
  });

  testWidgets('video access banner cancels before android permission request', (
    WidgetTester tester,
  ) async {
    _configureAndroidVideoPermissionTest(
      requestResult: PermissionStatus.granted,
    );
    final requested = <Permission>[];
    Access.debugPermissionRequestProvider = (permissions) async {
      requested.addAll(permissions);
      return <Permission, PermissionStatus>{
        for (final permission in permissions)
          permission: PermissionStatus.granted,
      };
    };

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.videos(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();

    expect(find.textContaining('存储权限说明'), findsOneWidget);
    expect(requested, isEmpty);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(requested, isEmpty);
    expect(await result, isFalse);
  });

  testWidgets('video access banner confirms before android video permission', (
    WidgetTester tester,
  ) async {
    final requested = <Permission>[];
    _configureAndroidVideoPermissionTest(
      requestResult: PermissionStatus.granted,
      onRequest: requested.addAll,
    );

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.videos(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();

    expect(find.textContaining('生成视频解说'), findsOneWidget);
    expect(requested, isEmpty);

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(requested, <Permission>[Permission.videos]);
    expect(await result, isTrue);
  });

  testWidgets('video access shows settings dialog after android denial', (
    WidgetTester tester,
  ) async {
    _configureAndroidVideoPermissionTest(
      requestResult: PermissionStatus.denied,
    );

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.videos(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(find.text('权限提示'), findsOneWidget);
    expect(find.text('请允许访问您的视频文件'), findsOneWidget);
  });

  testWidgets('save video on modern android skips media permission request', (
    WidgetTester tester,
  ) async {
    final requested = <Permission>[];
    Access.resetDebugOverrides();
    Access.debugTargetPlatform = TargetPlatform.android;
    Access.debugAndroidSdkIntProvider = () async => 33;
    Access.debugPermissionRequestProvider = (permissions) async {
      requested.addAll(permissions);
      return <Permission, PermissionStatus>{
        for (final permission in permissions)
          permission: PermissionStatus.granted,
      };
    };
    addTearDown(Access.resetDebugOverrides);

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.saveVideoToGallery(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();

    expect(requested, isEmpty);
    expect(find.textContaining('相册保存权限说明'), findsNothing);
    expect(await result, isTrue);
  });

  testWidgets('save video on android 9 asks storage permission after banner', (
    WidgetTester tester,
  ) async {
    final requested = <Permission>[];
    _configureSaveVideoPermissionTest(
      platform: TargetPlatform.android,
      sdkInt: 28,
      requestResult: PermissionStatus.granted,
      onRequest: requested.addAll,
    );

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.saveVideoToGallery(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();

    expect(find.textContaining('相册'), findsOneWidget);
    expect(requested, isEmpty);

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(requested, <Permission>[Permission.storage]);
    expect(await result, isTrue);
  });

  testWidgets('save video on ios asks add-only photo permission', (
    WidgetTester tester,
  ) async {
    final requested = <Permission>[];
    _configureSaveVideoPermissionTest(
      platform: TargetPlatform.iOS,
      requestResult: PermissionStatus.granted,
      onRequest: requested.addAll,
    );

    Future<bool>? result;
    await tester.pumpWidget(
      _AccessVideosTestApp(
        onOpen: (context) {
          result = Access.saveVideoToGallery(context);
        },
      ),
    );

    await tester.tap(find.text('申请视频权限'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();

    expect(requested, <Permission>[Permission.photosAddOnly]);
    expect(await result, isTrue);
  });
}

void _configureAndroidVideoPermissionTest({
  required PermissionStatus requestResult,
  void Function(List<Permission> permissions)? onRequest,
}) {
  Access.resetDebugOverrides();
  Access.debugTargetPlatform = TargetPlatform.android;
  Access.debugAndroidSdkIntProvider = () async => 33;
  Access.debugPermissionStatusProvider = (permissions) async {
    return permissions.map((_) => PermissionStatus.denied).toList();
  };
  Access.debugPermissionRequestProvider = (permissions) async {
    onRequest?.call(permissions);
    return <Permission, PermissionStatus>{
      for (final permission in permissions) permission: requestResult,
    };
  };
  addTearDown(() {
    Access.resetDebugOverrides();
  });
}

void _configureSaveVideoPermissionTest({
  required TargetPlatform platform,
  required PermissionStatus requestResult,
  int sdkInt = 33,
  void Function(List<Permission> permissions)? onRequest,
}) {
  Access.resetDebugOverrides();
  Access.debugTargetPlatform = platform;
  Access.debugAndroidSdkIntProvider = () async => sdkInt;
  Access.debugPermissionStatusProvider = (permissions) async {
    return permissions.map((_) => PermissionStatus.denied).toList();
  };
  Access.debugPermissionRequestProvider = (permissions) async {
    onRequest?.call(permissions);
    return <Permission, PermissionStatus>{
      for (final permission in permissions) permission: requestResult,
    };
  };
  addTearDown(Access.resetDebugOverrides);
}

final class _VoiceSheetTestApp extends StatelessWidget {
  const _VoiceSheetTestApp({required this.onOpen});

  final ValueChanged<BuildContext> onOpen;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return MaterialApp(
          theme: CustomTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: FilledButton(
                    onPressed: () => onOpen(context),
                    child: const Text('打开弹层'),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

final class _FakeCreationVoiceAuditionPlayer
    implements CreationVoiceAuditionPlayer {
  final StreamController<void> _completeController =
      StreamController<void>.broadcast();

  final List<String> playedUrls = <String>[];

  int stopCount = 0;

  bool disposed = false;

  @override
  Stream<void> get onComplete => _completeController.stream;

  @override
  Future<void> play(String url) async {
    playedUrls.add(url);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await _completeController.close();
  }
}

final class _WidgetRecordedRequest {
  const _WidgetRecordedRequest({required this.path, required this.data});

  final String path;
  final Object? data;
}

final class _SettingsDeleteAccountAdapter implements HttpClientAdapter {
  final List<String> paths = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    if (options.path == '/api/user/delete-request') {
      return _jsonResponse(<String, dynamic>{
        'code': 200,
        'message': '成功',
        'data': <String, dynamic>{'status': 'DELETE_REQUESTED'},
      });
    }
    return _jsonResponse(<String, dynamic>{
      'code': -404,
      'message': 'not found',
      'data': null,
    }, statusCode: 404);
  }

  ResponseBody _jsonResponse(
    Map<String, dynamic> response, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(response),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

GoRouter _paymentPageRouter({
  required String paymentPath,
  required String paymentRouteName,
  required Widget paymentPage,
  required String openButtonLabel,
}) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('支付来源页'),
                TextButton(
                  onPressed: () => context.pushNamed(paymentRouteName),
                  child: Text(openButtonLabel),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: paymentPath,
        name: paymentRouteName,
        builder: (context, state) => paymentPage,
      ),
    ],
  );
}

final class _WidgetPaymentProductAdapter implements HttpClientAdapter {
  final List<_WidgetRecordedRequest> requests = <_WidgetRecordedRequest>[];
  final Set<String> deletedOrderIds = <String>{};
  int pendingOrderStatus = 0;
  bool markDeletedOnDelete = true;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(
      _WidgetRecordedRequest(path: options.path, data: options.data),
    );
    return switch (options.path) {
      '/api/tbProduct/tbProductList' => _productList(options),
      '/api/tbOrder/creOrder' => _createOrder(options),
      '/api/tbOrder/reqPayment' => _requestPayment(),
      '/api/tbOrder/tbOrderList' => _orderList(),
      '/api/tbOrder/selectOne' => _orderDetail(options),
      '/api/tbOrder/upOrder' => _cancelOrder(options),
      '/api/tbOrder/delOrder' => _deleteOrder(options),
      '/api/user/profile' => _profile(),
      _ => _jsonResponse(<String, dynamic>{
        'code': -404,
        'message': 'not found',
        'data': null,
      }, statusCode: 404),
    };
  }

  ResponseBody _productList(RequestOptions options) {
    final type = int.tryParse('${options.queryParameters['type']}') ?? 1;
    final records = type == 1 ? _membershipProducts : _pointsProducts;
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'records': records,
        'total': records.length,
        'current': 1,
        'size': 20,
        'pages': 1,
      },
    });
  }

  ResponseBody _orderList() {
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'records': <Map<String, dynamic>>[
          <String, dynamic>{
            'orderId': 'PAY202606010001',
            'orderNo': 'PAY202606010001',
            'productId': 'vip_month',
            'productType': 1,
            'productName': '月卡套',
            'payType': 1,
            'payStatus': pendingOrderStatus,
            'totalAmount': 78,
            'createTime': '2026-06-01 10:30:00',
            'appPayInfo':
                'app_id=2026000000000000&biz_content=%7B%22out_trade_no%22%3A%22PAY202606010001%22%7D&sign=list-test',
            'del':
                markDeletedOnDelete &&
                    deletedOrderIds.contains('PAY202606010001')
                ? 1
                : 0,
          },
          <String, dynamic>{
            'orderId': 'PAY202606010002',
            'orderNo': 'PAY202606010002',
            'productId': 'points_30',
            'productType': 2,
            'productName': '30元积套',
            'payType': 1,
            'payStatus': 1,
            'payAmount': '30.00',
            'createTime': '2026-06-01 10:35:00',
            'del':
                markDeletedOnDelete &&
                    deletedOrderIds.contains('PAY202606010002')
                ? 1
                : 0,
          },
        ],
        'total': 2,
        'current': 1,
        'size': 50,
        'pages': 1,
      },
    });
  }

  ResponseBody _createOrder(RequestOptions options) {
    final data = Map<String, dynamic>.from(options.data as Map);
    final productId = '${data['id'] ?? ''}';
    final isPointsOrder = productId.startsWith('points_');
    final orderId = isPointsOrder ? 'PAY_SUCCESS_POINTS' : 'PAY_SUCCESS_MEMBER';
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'orderId': orderId,
        'orderNo': orderId,
        'userId': 'user_001',
        'appCode': 'narrate',
        'productId': productId,
        'productType': isPointsOrder ? 2 : 1,
        'productName': isPointsOrder ? '30元积套' : '月卡套',
        'totalAmount': isPointsOrder ? '30.00' : '78.00',
        'payType': data['type'] ?? 1,
        'payStatus': 0,
        'appPayInfo':
            'app_id=2026000000000000&biz_content=%7B%22out_trade_no%22%3A%22$orderId%22%7D&sign=create-test',
      },
    });
  }

  ResponseBody _requestPayment() {
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'orderId': 'PAY202606010001',
        'userId': 'user_001',
        'appCode': 'narrate',
        'productId': 'vip_month',
        'productType': 1,
        'cardType': 1,
        'productName': '月卡套',
        'totalAmount': '78.00',
        'payType': 'alipay',
        'appPayInfo':
            'app_id=2026000000000000&biz_content=%7B%22out_trade_no%22%3A%22PAY202606010001%22%7D&sign=test',
      },
    });
  }

  ResponseBody _orderDetail(RequestOptions options) {
    final orderId = '${options.queryParameters['id'] ?? 'PAY202606010001'}';
    final isPointsOrder =
        orderId == 'PAY_SUCCESS_POINTS' || orderId == 'PAY202606010002';
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'orderId': orderId,
        'orderNo': orderId,
        'productId': isPointsOrder ? 'points_30' : 'vip_month',
        'productType': isPointsOrder ? 2 : 1,
        'productName': isPointsOrder ? '30元积套' : '月卡套',
        'payType': 1,
        'payStatus': pendingOrderStatus,
        'totalAmount': isPointsOrder ? 30 : 78,
        'appPayInfo':
            'app_id=2026000000000000&biz_content=%7B%22out_trade_no%22%3A%22$orderId%22%7D&sign=test',
      },
    });
  }

  ResponseBody _cancelOrder(RequestOptions options) {
    final ids = (options.data as List).map((item) => '$item').toList();
    if (ids.contains('PAY202606010001')) {
      pendingOrderStatus = 2;
    }
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': '操作成功',
    });
  }

  ResponseBody _deleteOrder(RequestOptions options) {
    final ids = (options.data as List).map((item) => '$item').toList();
    deletedOrderIds.addAll(ids);
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': '操作成功',
    });
  }

  ResponseBody _profile() {
    return _jsonResponse(<String, dynamic>{
      'code': 200,
      'message': '成功',
      'data': <String, dynamic>{
        'id': '1',
        'phoneMasked': '138****0001',
        'inviteCode': 'ABC123',
        'pointsBalance': 88,
        'vipStatus': 'ACTIVE',
      },
    });
  }

  ResponseBody _jsonResponse(
    Map<String, dynamic> response, {
    int statusCode = 200,
  }) {
    return ResponseBody.fromString(
      jsonEncode(response),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}

  static const List<Map<String, dynamic>> _membershipProducts =
      <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'vip_month',
          'productName': '月卡套',
          'productType': 1,
          'cardType': 1,
          'price': 78,
          'memberDays': 30,
          'givePoints': 800,
          'pointsExpireDays': 30,
        },
        <String, dynamic>{
          'id': 'vip_quarter',
          'productName': '季卡套',
          'productType': 1,
          'cardType': 2,
          'price': 168,
          'memberDays': 90,
          'givePoints': 800,
          'pointsExpireDays': 90,
        },
      ];

  static const List<Map<String, dynamic>> _pointsProducts =
      <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'points_30',
          'productName': '30元积套',
          'productType': 2,
          'price': 30,
          'memberDays': 0,
          'givePoints': 300,
        },
        <String, dynamic>{
          'id': 'points_50',
          'productName': '50元积套',
          'productType': 2,
          'price': 50,
          'memberDays': 0,
          'givePoints': 500,
        },
      ];
}

final class _AccessVideosTestApp extends StatelessWidget {
  const _AccessVideosTestApp({required this.onOpen});

  final ValueChanged<BuildContext> onOpen;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: CustomTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () => onOpen(context),
                child: const Text('申请视频权限'),
              ),
            );
          },
        ),
      ),
    );
  }
}
