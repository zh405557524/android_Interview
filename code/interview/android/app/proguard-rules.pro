# Flutter release 包启用 R8 混淆时，保留阿里云号码认证 SDK 及三大运营商依赖。
# 一键登录 SDK 会通过反射、JSON 序列化和 native 方法解析内部模型，混淆这些类会导致
# 授权页打开、环境检测或 token 解析在正式包中异常。
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,*Annotation*,EnclosingMethod

# 号码认证 SDK 内置界面继承 AppCompatActivity，官方要求混淆时保留 AppCompat 基类能力。
-keep class androidx.appcompat.app.AppCompatActivity
-keep class androidx.core.content.ContextCompat { *; }

-keep class com.mobile.auth.** { *; }
-dontwarn com.mobile.auth.**

-keep class com.nirvana.** { *; }
-dontwarn com.nirvana.**

-keep class cn.com.chinatelecom.** { *; }

-keep class com.cmic.sso.sdk.** { *; }
-dontwarn com.cmic.sso.sdk.utils.**

-keep class com.cmic.gen.sdk.** { *; }
-dontwarn com.cmic.gen.sdk.**

-keep class com.unicom.online.account.shield.** { *; }
-dontwarn com.unicom.online.account.kernel.**

-keep class com.alicom.tools.serialization.** { *; }
-keep class com.alicom.tools.networking.** { *; }
-keep class * implements com.alicom.tools.serialization.JSONer { *; }
-keep class * implements com.nirvana.tools.jsoner.Jsoner { *; }

-keepclasseswithmembernames class * {
    native <methods>;
}

# 自定义 MethodChannel 桥接类保留名称和成员，方便 release 崩溃日志定位到一键登录链路。
-keep class com.lxwx.narrate.AliyunNumberAuthPlugin { *; }
