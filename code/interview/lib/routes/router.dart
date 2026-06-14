part of 'index.dart';

abstract final class CustomRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final RouteObservers observer = RouteObservers();

  static void popOrMain(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.goNamed(RouteName.main);
  }

  static final GoRouter config = GoRouter(
    initialLocation: '/',
    navigatorKey: navigatorKey,
    observers: <NavigatorObserver>[observer],
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: RouteName.main,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.main,
          child: const MainPage(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: RouteName.login,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.login,
          child: AuthPage(inviteCode: state.uri.queryParameters['inviteCode']),
        ),
      ),
      GoRoute(
        path: '/knowledge',
        name: RouteName.knowledge,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.knowledge,
          child: const KnowledgePage(),
        ),
      ),
      GoRoute(
        path: '/knowledge/categories/:id',
        name: RouteName.knowledgeCategory,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.knowledgeCategory,
          child: KnowledgePage(categoryId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/knowledge/points/:id',
        name: RouteName.knowledgePoint,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.knowledgePoint,
          child: KnowledgePointPage(pointId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/mock',
        name: RouteName.mockInterview,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.mockInterview,
          child: const MockInterviewPage(),
        ),
      ),
      GoRoute(
        path: '/review',
        name: RouteName.review,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.review,
          child: const ReviewPage(),
        ),
      ),
      GoRoute(
        path: '/profile',
        name: RouteName.offerProfile,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.offerProfile,
          child: const OfferProfilePage(),
        ),
      ),
      GoRoute(
        path: '/creation/video',
        name: RouteName.creationVideo,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.creationVideo,
          child: const CreationPage(),
        ),
      ),
      GoRoute(
        path: '/home-cases/:id',
        name: RouteName.homeCaseDetail,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.homeCaseDetail,
          child: HomeCaseDetailPage(
            caseId: state.pathParameters['id'] ?? '',
            initialCase: state.extra is HomeCase
                ? state.extra as HomeCase
                : null,
          ),
        ),
      ),
      GoRoute(
        path: '/works/:id',
        name: RouteName.workDetail,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.workDetail,
          child: WorkDetailPage(workId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/membership',
        name: RouteName.membership,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.membership,
          child: const MembershipPage(),
        ),
      ),
      GoRoute(
        path: '/task-center',
        name: RouteName.taskCenter,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.taskCenter,
          child: const TaskCenterPage(),
        ),
      ),
      GoRoute(
        path: '/payment/orders',
        name: RouteName.paymentOrders,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.paymentOrders,
          child: const PaymentOrdersPage(),
        ),
      ),
      GoRoute(
        path: '/redeem-code',
        name: RouteName.redeemCode,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.redeemCode,
          child: const RedeemCodePage(),
        ),
      ),
      GoRoute(
        path: '/points/recharge',
        name: RouteName.pointsRecharge,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.pointsRecharge,
          child: const PointsRechargePage(),
        ),
      ),
      GoRoute(
        path: '/points/ledger',
        name: RouteName.pointsLedger,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.pointsLedger,
          child: const PointsLedgerPage(),
        ),
      ),
      GoRoute(
        path: '/invite',
        name: RouteName.invite,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.invite,
          child: const InvitePage(),
        ),
      ),
      GoRoute(
        path: '/invite/bind',
        name: RouteName.inviteBind,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteBind,
          child: const InviteBindPage(),
        ),
      ),
      GoRoute(
        path: '/invite/records',
        name: RouteName.inviteRecords,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteRecords,
          child: const InviteRecordsPage(),
        ),
      ),
      GoRoute(
        path: '/invite/ledgers',
        name: RouteName.inviteLedgers,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteLedgers,
          child: const InviteLedgersPage(),
        ),
      ),
      GoRoute(
        path: '/invite/withdrawal',
        name: RouteName.inviteWithdrawal,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteWithdrawal,
          child: const InviteWithdrawalPage(),
        ),
      ),
      GoRoute(
        path: '/invite/withdrawals',
        name: RouteName.inviteWithdrawals,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteWithdrawals,
          child: const InviteWithdrawalRecordsPage(),
        ),
      ),
      GoRoute(
        path: '/invite/materials',
        name: RouteName.inviteMaterials,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteMaterials,
          child: const InviteMaterialsPage(),
        ),
      ),
      GoRoute(
        path: '/invite/rules',
        name: RouteName.inviteRules,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.inviteRules,
          child: const InviteRulesPage(),
        ),
      ),
      GoRoute(
        path: '/settings',
        name: RouteName.settings,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.settings,
          child: const SettingsPage(),
        ),
      ),
      GoRoute(
        path: '/settings/account-security',
        name: RouteName.accountSecurity,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.accountSecurity,
          child: const AccountSecurityPage(),
        ),
      ),
      GoRoute(
        path: '/feedback',
        name: RouteName.feedback,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.feedback,
          child: const FeedbackPage(),
        ),
      ),
      GoRoute(
        path: '/webview',
        name: RouteName.webview,
        pageBuilder: (context, state) => CupertinoPage<void>(
          key: state.pageKey,
          name: RouteName.webview,
          child: StaticPageView(
            pageKey: state.uri.queryParameters['key'] ?? 'user-agreement',
          ),
        ),
      ),
    ],
  );
}
