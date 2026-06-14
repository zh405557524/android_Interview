#import "AliyunNumberAuthPlugin.h"

#import <ATAuthSDK_D/ATAuthSDK.h>
#import <UIKit/UIKit.h>

static NSString *const AliyunNumberAuthChannelName = @"narrate/aliyun_number_auth";
static NSTimeInterval const AliyunNumberAuthTimeout = 3.0;

@interface AliyunNumberAuthPlugin ()
@property(nonatomic, assign) BOOL configured;
@property(nonatomic, copy) NSString *authInfo;
@property(nonatomic, strong) UIView *loadingOverlay;
@property(nonatomic, assign) NSInteger loginRequestId;
@end

@implementation AliyunNumberAuthPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:AliyunNumberAuthChannelName
                                  binaryMessenger:[registrar messenger]];
  AliyunNumberAuthPlugin *instance = [[AliyunNumberAuthPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"configure" isEqualToString:call.method]) {
    [self configureWithCall:call result:result];
  } else if ([@"checkEnv" isEqualToString:call.method]) {
    [self checkEnvWithResult:result];
  } else if ([@"accelerateLoginPage" isEqualToString:call.method]) {
    [self accelerateLoginPageWithResult:result];
  } else if ([@"getLoginToken" isEqualToString:call.method]) {
    [self getLoginTokenWithResult:result];
  } else if ([@"finishLogin" isEqualToString:call.method]) {
    [self finishLoginWithCall:call result:result];
  } else if ([@"cancelLogin" isEqualToString:call.method]) {
    [self dismissLoadingDialogWithCompletion:nil];
    [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
    result([self responseWithStatus:@"cancelled" code:@"CANCELLED" message:@"已取消一键登录"]);
  } else if ([@"getVersion" isEqualToString:call.method]) {
    result([self responseWithStatus:@"available"
                               code:@"OK"
                            message:[[TXCommonHandler sharedInstance] getVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)configureWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSDictionary *arguments = [call.arguments isKindOfClass:NSDictionary.class] ? call.arguments : @{};
  NSString *authInfo = [self stringValue:arguments[@"authSdkInfo"]];
  if (authInfo.length == 0) {
    self.configured = NO;
    self.authInfo = @"";
    result([self responseWithStatus:@"unavailable"
                               code:@"AUTH_INFO_EMPTY"
                            message:@"阿里云号码认证未配置"]);
    return;
  }

  if (self.configured && [self.authInfo isEqualToString:authInfo]) {
    result([self responseWithStatus:@"available" code:@"OK" message:@"SDK 已配置"]);
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TXCommonHandler sharedInstance] setAuthSDKInfo:authInfo
                                          complete:^(NSDictionary *_Nonnull resultDic) {
                                            __strong typeof(weakSelf) self = weakSelf;
                                            if (!self) {
                                              return;
                                            }
                                            NSString *code = [self resultCodeFromDictionary:resultDic];
                                            NSString *message = [self messageFromDictionary:resultDic
                                                                               fallback:@"SDK 鉴权失败"];
                                            BOOL success = [code isEqualToString:PNSCodeSuccess];
                                            self.configured = success;
                                            self.authInfo = success ? authInfo : @"";
                                            result([self responseWithStatus:(success ? @"available" : @"unavailable")
                                                                       code:code
                                                                    message:(success ? @"SDK 已配置" : message)]);
                                          }];
}

- (void)checkEnvWithResult:(FlutterResult)result {
  if (![self ensureConfiguredWithResult:result]) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TXCommonHandler sharedInstance] checkEnvAvailableWithAuthType:PNSAuthTypeLoginToken
                                                         complete:^(NSDictionary *_Nullable resultDic) {
                                                           __strong typeof(weakSelf) self = weakSelf;
                                                           if (!self) {
                                                             return;
                                                           }
                                                           NSString *code = [self resultCodeFromDictionary:resultDic];
                                                           BOOL available = [code isEqualToString:PNSCodeSuccess];
                                                           result([self responseWithStatus:(available ? @"available" : @"unavailable")
                                                                                      code:code
                                                                                   message:[self messageFromDictionary:resultDic fallback:@"当前环境不支持一键登录"]]);
                                                         }];
}

- (void)accelerateLoginPageWithResult:(FlutterResult)result {
  if (![self ensureConfiguredWithResult:result]) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  [[TXCommonHandler sharedInstance] accelerateLoginPageWithTimeout:AliyunNumberAuthTimeout
                                                          complete:^(NSDictionary *_Nonnull resultDic) {
                                                            __strong typeof(weakSelf) self = weakSelf;
                                                            if (!self) {
                                                              return;
                                                            }
                                                            NSString *code = [self resultCodeFromDictionary:resultDic];
                                                            BOOL available = [code isEqualToString:PNSCodeSuccess] ||
                                                                [code isEqualToString:PNSCodeCallPreLoginInAuthPage];
                                                            result([self responseWithStatus:(available ? @"available" : @"unavailable")
                                                                                       code:code
                                                                                    message:[self messageFromDictionary:resultDic fallback:@"一键登录预取失败"]]);
                                                          }];
}

- (void)getLoginTokenWithResult:(FlutterResult)result {
  if (![self ensureConfiguredWithResult:result]) {
    return;
  }

  UIViewController *controller = [self topViewController];
  if (!controller) {
    result([self responseWithStatus:@"error"
                               code:@"NO_VIEW_CONTROLLER"
                            message:@"无法打开一键登录授权页"]);
    return;
  }

  TXCustomModel *model = [self customModel];
  __weak typeof(self) weakSelf = self;
  __block BOOL completed = NO;
  self.loginRequestId += 1;
  NSInteger requestId = self.loginRequestId;
  [[TXCommonHandler sharedInstance] getLoginTokenWithTimeout:AliyunNumberAuthTimeout
                                                  controller:controller
                                                       model:model
                                                    complete:^(NSDictionary *_Nonnull resultDic) {
                                                      __strong typeof(weakSelf) self = weakSelf;
                                                      if (!self || completed) {
                                                        return;
                                                      }

                                                      NSString *code = [self resultCodeFromDictionary:resultDic];
                                                      if ([code isEqualToString:PNSCodeSuccess]) {
                                                        NSString *token = [self stringValue:resultDic[@"token"]];
                                                        completed = YES;
                                                        if (token.length == 0) {
                                                          [self dismissLoadingDialogWithCompletion:nil];
                                                          [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                                                          result([self responseWithStatus:@"error"
                                                                                     code:@"TOKEN_EMPTY"
                                                                                  message:@"一键登录授权令牌为空"]);
                                                          return;
                                                        }
                                                        [self showLoadingDialogWithMessage:@"登录中..."];
                                                        result([self responseWithStatus:@"token"
                                                                                   code:code
                                                                                message:@"授权成功"
                                                                                  token:token]);
                                                        return;
                                                      }

                                                      if ([code isEqualToString:PNSCodeLoginControllerPresentSuccess] ||
                                                          [code isEqualToString:PNSCodeLoginControllerClickCheckBoxBtn] ||
                                                          [code isEqualToString:PNSCodeLoginControllerClickProtocol] ||
                                                          [code isEqualToString:PNSCodeLoginClickPrivacyAlertView] ||
                                                          [code isEqualToString:PNSCodeLoginPrivacyAlertViewClose] ||
                                                          [code isEqualToString:PNSCodeLoginPrivacyAlertViewClickContinue] ||
                                                          [code isEqualToString:PNSCodeLoginPrivacyAlertViewPrivacyContentClick]) {
                                                        return;
                                                      }

                                                      if ([code isEqualToString:PNSCodeLoginControllerClickLoginBtn]) {
                                                        if ([self isPrivacyCheckedFromDictionary:resultDic]) {
                                                          [self showLoadingDialogWithMessage:@"登录中..."];
                                                        }
                                                        return;
                                                      }

                                                      if ([code isEqualToString:PNSCodeLoginControllerClickCancel] ||
                                                          [code isEqualToString:PNSCodeLoginControllerClickChangeBtn] ||
                                                          [code isEqualToString:PNSCodeLoginControllerSuspendDisMissVC] ||
                                                          [code isEqualToString:PNSCodeLoginControllerDeallocVC]) {
                                                        completed = YES;
                                                        [self dismissLoadingDialogWithCompletion:nil];
                                                        [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                                                        result([self responseWithStatus:@"cancelled"
                                                                                   code:code
                                                                                message:@"已取消一键登录"]);
                                                        return;
                                                      }

                                                      completed = YES;
                                                      NSString *status = [self isUnavailableCode:code] ? @"unavailable" : @"error";
                                                      [self dismissLoadingDialogWithCompletion:nil];
                                                      [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                                                      result([self responseWithStatus:status
                                                                                 code:code
                                                                              message:[self messageFromDictionary:resultDic fallback:@"一键登录失败，请使用短信验证码登录"]]);
                                                    }];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((AliyunNumberAuthTimeout + 2.0) * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
                   __strong typeof(weakSelf) self = weakSelf;
                   if (!self || completed || requestId != self.loginRequestId) {
                     return;
                   }
                   completed = YES;
                   [self dismissLoadingDialogWithCompletion:nil];
                   [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
                   result([self responseWithStatus:@"unavailable"
                                              code:@"LOGIN_TOKEN_TIMEOUT"
                                           message:@"一键登录超时，请使用短信验证码登录"]);
                 });
}

- (void)finishLoginWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSDictionary *arguments = [call.arguments isKindOfClass:NSDictionary.class] ? call.arguments : @{};
  BOOL success = [arguments[@"success"] respondsToSelector:@selector(boolValue)] ? [arguments[@"success"] boolValue] : NO;
  NSString *message = [self stringValue:arguments[@"message"]];

  if (success) {
    [self dismissLoadingDialogWithCompletion:^{
      [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
      result([self responseWithStatus:@"available" code:@"OK" message:@"一键登录成功"]);
    }];
    return;
  }

  [self dismissLoadingDialogWithCompletion:^{
    if (message.length > 0) {
      [self showToastWithMessage:message];
    }
    [[TXCommonHandler sharedInstance] cancelLoginVCAnimated:YES complete:nil];
    result([self responseWithStatus:@"error"
                               code:@"LOGIN_FAILED"
                            message:(message.length > 0 ? message : @"一键登录失败，请稍后重试")]);
  }];
}

- (BOOL)ensureConfiguredWithResult:(FlutterResult)result {
  if (self.configured) {
    return YES;
  }
  result([self responseWithStatus:@"unavailable"
                             code:@"AUTH_NOT_CONFIGURED"
                          message:@"阿里云号码认证未初始化"]);
  return NO;
}

- (BOOL)isUnavailableCode:(NSString *)code {
  NSSet<NSString *> *codes = [NSSet setWithArray:@[
    PNSCodeNoSIMCard,
    PNSCodeNoCellularNetwork,
    PNSCodeUnknownOperator,
    PNSCodeInterfaceDemoted,
    PNSCodeInterfaceLimited,
    PNSCodeInterfaceTimeout,
    PNSCodeDecodeAppInfoFailed,
    PNSCodePhoneBlack,
    PNSCodeCarrierChanged,
    PNSCodeEnvCheckFail,
    PNSCodeLoginControllerPresentFailed,
    PNSCodeGetOperatorInfoFailed,
  ]];
  return [codes containsObject:code];
}

- (TXCustomModel *)customModel {
  TXCustomModel *model = [[TXCustomModel alloc] init];
  UIColor *background = [self colorWithHex:0x080A0D];
  UIColor *surface = [self colorWithHex:0x12161D];
  UIColor *primary = [self colorWithHex:0xD7FF47];
  UIColor *textPrimary = [self colorWithHex:0xF6F8FA];
  UIColor *textSecondary = [self colorWithHex:0xAAB2C0];

  model.supportedInterfaceOrientations = UIInterfaceOrientationMaskPortrait;
  model.preferredStatusBarStyle = UIStatusBarStyleLightContent;
  model.backgroundColor = background;
  model.navColor = background;
  model.navTitle = [[NSAttributedString alloc] initWithString:@"手机号码登录"
                                                   attributes:@{
                                                     NSForegroundColorAttributeName : textPrimary,
                                                     NSFontAttributeName : [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold],
                                                   }];
  model.navBackImage = [self backImageWithColor:textPrimary];
  model.navBackButtonFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    return CGRectMake(12.0, frame.origin.y, 44.0, 44.0);
  };

  model.logoImage = [self brandLogoImageWithBackground:surface foreground:primary];
  model.logoFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat side = 88.0;
    CGFloat y = MAX(92.0, screenSize.height * 0.14);
    return CGRectMake((superViewSize.width - side) / 2.0, y, side, side);
  };

  model.numberColor = textPrimary;
  model.numberFont = [UIFont systemFontOfSize:32 weight:UIFontWeightSemibold];
  model.numberFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat width = frame.size.width > 0 ? frame.size.width : MIN(260.0, superViewSize.width);
    CGFloat height = frame.size.height > 0 ? frame.size.height : 44.0;
    CGFloat y = MAX(230.0, screenSize.height * 0.34);
    return CGRectMake((superViewSize.width - width) / 2.0, y, width, height);
  };

  model.sloganText = [[NSAttributedString alloc] initWithString:@"运营商提供认证服务"
                                                     attributes:@{
                                                       NSForegroundColorAttributeName : textPrimary,
                                                       NSFontAttributeName : [UIFont systemFontOfSize:13 weight:UIFontWeightMedium],
                                                     }];
  model.sloganFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat y = MAX(278.0, screenSize.height * 0.395);
    return CGRectMake(0.0, y, superViewSize.width, 24.0);
  };

  UIImage *normalButton = [self roundedImageWithColor:primary size:CGSizeMake(315.0, 56.0) radius:18.0];
  UIImage *disabledButton = [self roundedImageWithColor:[primary colorWithAlphaComponent:0.38]
                                                   size:CGSizeMake(315.0, 56.0)
                                                 radius:18.0];
  UIImage *highlightButton = [self roundedImageWithColor:[primary colorWithAlphaComponent:0.82]
                                                    size:CGSizeMake(315.0, 56.0)
                                                  radius:18.0];
  model.loginBtnBgImgs = @[ normalButton, disabledButton, highlightButton ];
  model.loginBtnText = [[NSAttributedString alloc] initWithString:@"一键登录"
                                                       attributes:@{
                                                         NSForegroundColorAttributeName : UIColor.blackColor,
                                                         NSFontAttributeName : [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold],
                                                       }];
  model.loginBtnFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat width = MIN(315.0, superViewSize.width - 60.0);
    CGFloat y = MAX(338.0, screenSize.height * 0.485);
    return CGRectMake((superViewSize.width - width) / 2.0, y, width, 56.0);
  };
  model.showLoginLoading = NO;
  model.autoHideLoginLoading = YES;

  model.changeBtnTitle = [[NSAttributedString alloc] initWithString:@"切换账号"
                                                         attributes:@{
                                                           NSForegroundColorAttributeName : primary,
                                                           NSFontAttributeName : [UIFont systemFontOfSize:14 weight:UIFontWeightMedium],
                                                         }];
  model.changeBtnFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat y = MAX(430.0, screenSize.height * 0.60);
    return CGRectMake((superViewSize.width - 120.0) / 2.0, y, 120.0, 44.0);
  };

  model.privacyColors = @[ [textSecondary colorWithAlphaComponent:0.78], primary ];
  model.privacyOperatorColor = primary;
  model.privacyFont = [UIFont systemFontOfSize:12];
  model.privacyOperatorFont = [UIFont systemFontOfSize:12];
  model.privacyAlignment = NSTextAlignmentCenter;
  model.privacyPreText = @"我已阅读并同意";
  model.privacySufText = @"";
  model.privacyOperatorPreText = @"《";
  model.privacyOperatorSufText = @"》";
  model.privacyLineSpaceDp = 4.0;
  model.checkBoxIsChecked = YES;
  model.checkBoxWH = 18.0;
  model.checkBoxVerticalCenter = YES;
  model.expandAuthPageCheckedScope = YES;
  model.privacyFrameBlock = ^CGRect(CGSize screenSize, CGSize superViewSize, CGRect frame) {
    CGFloat width = MIN(315.0, superViewSize.width - 40.0);
    CGFloat height = 54.0;
    CGFloat bottom = 96.0;
    return CGRectMake((superViewSize.width - width) / 2.0,
                      superViewSize.height - bottom - height,
                      width,
                      height);
  };

  return model;
}

- (void)showLoadingDialogWithMessage:(NSString *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    if (self.loadingOverlay) {
      return;
    }

    UIViewController *controller = [self topViewController];
    if (!controller) {
      return;
    }

    UIColor *primary = [self colorWithHex:0xD7FF47];
    UIView *overlay = [[UIView alloc] init];
    overlay.translatesAutoresizingMaskIntoConstraints = NO;
    overlay.backgroundColor = UIColor.clearColor;
    overlay.alpha = 0.0;
    overlay.userInteractionEnabled = YES;

    UIView *box = [[UIView alloc] init];
    box.translatesAutoresizingMaskIntoConstraints = NO;
    box.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.94];
    box.layer.cornerRadius = 12.0;
    box.layer.masksToBounds = YES;

    UIActivityIndicatorView *indicator = nil;
    if (@available(iOS 13.0, *)) {
      indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
      indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    indicator.color = primary;
    [indicator startAnimating];

    [controller.view addSubview:overlay];
    [overlay addSubview:box];
    [box addSubview:indicator];
    [NSLayoutConstraint activateConstraints:@[
      [overlay.topAnchor constraintEqualToAnchor:controller.view.topAnchor],
      [overlay.leadingAnchor constraintEqualToAnchor:controller.view.leadingAnchor],
      [overlay.trailingAnchor constraintEqualToAnchor:controller.view.trailingAnchor],
      [overlay.bottomAnchor constraintEqualToAnchor:controller.view.bottomAnchor],
      [box.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
      [box.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
      [box.widthAnchor constraintEqualToConstant:96.0],
      [box.heightAnchor constraintEqualToConstant:96.0],
      [indicator.centerXAnchor constraintEqualToAnchor:box.centerXAnchor],
      [indicator.centerYAnchor constraintEqualToAnchor:box.centerYAnchor],
    ]];

    self.loadingOverlay = overlay;
    [UIView animateWithDuration:0.16 animations:^{
      overlay.alpha = 1.0;
    }];
  });
}

- (void)dismissLoadingDialogWithCompletion:(void (^_Nullable)(void))completion {
  dispatch_async(dispatch_get_main_queue(), ^{
    UIView *overlay = self.loadingOverlay;
    self.loadingOverlay = nil;
    if (!overlay) {
      if (completion) {
        completion();
      }
      return;
    }
    [UIView animateWithDuration:0.16
        animations:^{
          overlay.alpha = 0.0;
        }
        completion:^(__unused BOOL finished) {
          [overlay removeFromSuperview];
          if (completion) {
            completion();
          }
        }];
  });
}

- (BOOL)isPrivacyCheckedFromDictionary:(NSDictionary *)dictionary {
  id value = dictionary[@"isChecked"];
  if (!value) {
    value = dictionary[@"checked"];
  }
  if (!value || value == NSNull.null) {
    return YES;
  }
  if ([value respondsToSelector:@selector(boolValue)]) {
    return [value boolValue];
  }
  NSString *text = [self stringValue:value].lowercaseString;
  if ([text isEqualToString:@"false"] || [text isEqualToString:@"0"]) {
    return NO;
  }
  return YES;
}

- (void)showToastWithMessage:(NSString *)message {
  if (message.length == 0) {
    return;
  }

  dispatch_async(dispatch_get_main_queue(), ^{
    UIViewController *controller = [self topViewController];
    UIView *container = controller.view ?: UIApplication.sharedApplication.keyWindow;
    if (!container) {
      return;
    }

    UIView *toast = [[UIView alloc] init];
    toast.translatesAutoresizingMaskIntoConstraints = NO;
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.78];
    toast.layer.cornerRadius = 10.0;
    toast.layer.masksToBounds = YES;
    toast.alpha = 0.0;

    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = message;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;

    [container addSubview:toast];
    [toast addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
      [toast.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
      [toast.bottomAnchor constraintEqualToAnchor:container.safeAreaLayoutGuide.bottomAnchor constant:-96.0],
      [toast.widthAnchor constraintLessThanOrEqualToAnchor:container.widthAnchor constant:-56.0],
      [toast.heightAnchor constraintGreaterThanOrEqualToConstant:44.0],
      [label.topAnchor constraintEqualToAnchor:toast.topAnchor constant:12.0],
      [label.leadingAnchor constraintEqualToAnchor:toast.leadingAnchor constant:16.0],
      [label.trailingAnchor constraintEqualToAnchor:toast.trailingAnchor constant:-16.0],
      [label.bottomAnchor constraintEqualToAnchor:toast.bottomAnchor constant:-12.0],
    ]];

    [UIView animateWithDuration:0.18
                     animations:^{
                       toast.alpha = 1.0;
                     }
                     completion:^(__unused BOOL finished) {
                       [UIView animateWithDuration:0.18
                                             delay:1.8
                                           options:UIViewAnimationOptionCurveEaseInOut
                                        animations:^{
                                          toast.alpha = 0.0;
                                        }
                                        completion:^(__unused BOOL finished) {
                                          [toast removeFromSuperview];
                                        }];
                     }];
  });
}

- (UIViewController *)topViewController {
  UIWindow *keyWindow = nil;
  if (@available(iOS 13.0, *)) {
    NSSet<UIScene *> *connectedScenes = UIApplication.sharedApplication.connectedScenes;
    for (UIScene *scene in connectedScenes) {
      if (![scene isKindOfClass:UIWindowScene.class] ||
          scene.activationState != UISceneActivationStateForegroundActive) {
        continue;
      }
      UIWindowScene *windowScene = (UIWindowScene *)scene;
      for (UIWindow *window in windowScene.windows) {
        if (window.isKeyWindow) {
          keyWindow = window;
          break;
        }
      }
      if (keyWindow) {
        break;
      }
    }
  }
  if (!keyWindow) {
    keyWindow = UIApplication.sharedApplication.keyWindow;
  }

  UIViewController *controller = keyWindow.rootViewController;
  while (controller.presentedViewController) {
    controller = controller.presentedViewController;
  }
  if ([controller isKindOfClass:UINavigationController.class]) {
    controller = ((UINavigationController *)controller).visibleViewController;
  }
  if ([controller isKindOfClass:UITabBarController.class]) {
    controller = ((UITabBarController *)controller).selectedViewController;
  }
  return controller;
}

- (NSDictionary<NSString *, id> *)responseWithStatus:(NSString *)status
                                                code:(NSString *)code
                                             message:(NSString *)message {
  return [self responseWithStatus:status code:code message:message token:nil];
}

- (NSDictionary<NSString *, id> *)responseWithStatus:(NSString *)status
                                                code:(NSString *)code
                                             message:(NSString *)message
                                               token:(NSString *)token {
  NSMutableDictionary<NSString *, id> *response = [@{
    @"status" : status ?: @"error",
    @"code" : code ?: @"UNKNOWN",
    @"message" : message ?: @"",
  } mutableCopy];
  if (token.length > 0) {
    response[@"token"] = token;
  }
  return response;
}

- (NSString *)resultCodeFromDictionary:(NSDictionary *)dictionary {
  NSString *code = [self stringValue:dictionary[@"resultCode"]];
  return code.length > 0 ? code : @"UNKNOWN";
}

- (NSString *)messageFromDictionary:(NSDictionary *)dictionary fallback:(NSString *)fallback {
  NSString *message = [self stringValue:dictionary[@"msg"]];
  if (message.length == 0) {
    message = [self stringValue:dictionary[@"message"]];
  }
  return message.length > 0 ? message : fallback;
}

- (NSString *)stringValue:(id)value {
  if ([value isKindOfClass:NSString.class]) {
    return [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  }
  if ([value respondsToSelector:@selector(stringValue)]) {
    return [value stringValue];
  }
  return @"";
}

- (UIColor *)colorWithHex:(NSUInteger)hex {
  CGFloat red = ((hex >> 16) & 0xFF) / 255.0;
  CGFloat green = ((hex >> 8) & 0xFF) / 255.0;
  CGFloat blue = (hex & 0xFF) / 255.0;
  return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (UIImage *)roundedImageWithColor:(UIColor *)color size:(CGSize)size radius:(CGFloat)radius {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
  [color setFill];
  [path fill];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (UIImage *)brandLogoImageWithBackground:(UIColor *)background foreground:(UIColor *)foreground {
  CGSize size = CGSizeMake(88.0, 88.0);
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  CGRect rect = CGRectMake(0.0, 0.0, size.width, size.height);
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:24.0];
  [background setFill];
  [path fill];

  NSDictionary *attributes = @{
    NSForegroundColorAttributeName : foreground,
    NSFontAttributeName : [UIFont systemFontOfSize:26.0 weight:UIFontWeightBold],
  };
  NSString *text = @"剧说";
  CGSize textSize = [text sizeWithAttributes:attributes];
  CGRect textRect = CGRectMake((size.width - textSize.width) / 2.0,
                               (size.height - textSize.height) / 2.0,
                               textSize.width,
                               textSize.height);
  [text drawInRect:textRect withAttributes:attributes];

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (UIImage *)backImageWithColor:(UIColor *)color {
  CGSize size = CGSizeMake(24.0, 24.0);
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:CGPointMake(15.5, 5.0)];
  [path addLineToPoint:CGPointMake(8.5, 12.0)];
  [path addLineToPoint:CGPointMake(15.5, 19.0)];
  path.lineWidth = 2.4;
  path.lineCapStyle = kCGLineCapRound;
  path.lineJoinStyle = kCGLineJoinRound;
  [color setStroke];
  [path stroke];
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@end
