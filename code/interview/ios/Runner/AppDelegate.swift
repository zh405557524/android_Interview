import Flutter
import Network
import UIKit
import AliyunNumberAuth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    requestLocalNetworkAccessIfNeeded()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// iOS 14+ 访问局域网 HTTP 需用户授权本地网络；通过 Bonjour 浏览触发系统弹窗。
  private func requestLocalNetworkAccessIfNeeded() {
    guard #available(iOS 14.0, *) else {
      return
    }

    let browser = NWBrowser(
      for: .bonjour(type: "_http._tcp", domain: nil),
      using: .tcp
    )
    browser.stateUpdateHandler = { state in
      if case .ready = state {
        browser.cancel()
      }
    }
    browser.start(queue: DispatchQueue.global(qos: .utility))
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      browser.cancel()
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "AliyunNumberAuthPlugin"
    ) {
      AliyunNumberAuthPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "AppUpdatePlugin"
    ) {
      let channel = FlutterMethodChannel(
        name: "narrate/app_update",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getChannel":
          result("default")
        case "openUrl":
          guard
            let arguments = call.arguments as? [String: Any],
            let rawUrl = arguments["url"] as? String,
            let url = URL(string: rawUrl.trimmingCharacters(in: .whitespacesAndNewlines))
          else {
            result(false)
            return
          }
          UIApplication.shared.open(url) { opened in
            result(opened)
          }
        case "installApk":
          result(false)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
}
