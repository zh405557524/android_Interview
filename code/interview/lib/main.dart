import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'global.dart';
import 'routes/index.dart';
import 'theme.dart';
import 'widgets/index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(CustomTheme.systemStyle);
  await Global.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: Global.appName,
          debugShowCheckedModeBanner: false,
          theme: CustomTheme.dark,
          themeMode: ThemeMode.dark,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale.fromSubtags(languageCode: 'zh'),
            Locale.fromSubtags(languageCode: 'en'),
          ],
          routerConfig: CustomRouter.config,
          builder: (context, child) {
            return CustomToast.init(
              context: context,
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.noScaling),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            )(context, child);
          },
        );
      },
    );
  }
}
