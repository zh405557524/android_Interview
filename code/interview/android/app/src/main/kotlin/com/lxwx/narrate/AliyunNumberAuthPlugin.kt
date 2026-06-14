package com.lxwx.narrate

import android.app.Activity
import android.app.Application
import android.app.Dialog
import android.content.Context
import android.content.pm.ActivityInfo
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.ViewGroup
import android.view.Window
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ProgressBar
import android.widget.Toast
import com.mobile.auth.gatewayauth.AuthUIConfig
import com.mobile.auth.gatewayauth.PhoneNumberAuthHelper
import com.mobile.auth.gatewayauth.PreLoginResultListener
import com.mobile.auth.gatewayauth.ResultCode
import com.mobile.auth.gatewayauth.TokenResultListener
import com.mobile.auth.gatewayauth.model.TokenRet
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class AliyunNumberAuthPlugin(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private var helper: PhoneNumberAuthHelper? = null
    private var configuredAuthInfo = ""
    private var pendingLoginResult: MethodChannel.Result? = null
    private var foregroundActivity: Activity? = activity
    private var loadingDialog: Dialog? = null
    private val loginCompleted = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())
    private var loginRequestId = 0
    private val lifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) = Unit
        override fun onActivityStarted(activity: Activity) = Unit
        override fun onActivityResumed(activity: Activity) {
            foregroundActivity = activity
        }
        override fun onActivityPaused(activity: Activity) = Unit
        override fun onActivityStopped(activity: Activity) = Unit
        override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) = Unit
        override fun onActivityDestroyed(activity: Activity) {
            if (foregroundActivity === activity) {
                foregroundActivity = this@AliyunNumberAuthPlugin.activity
            }
        }
    }

    init {
        activity.application.registerActivityLifecycleCallbacks(lifecycleCallbacks)
    }

    fun register() {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configure" -> configure(call, result)
                "checkEnv" -> checkEnv(result)
                "accelerateLoginPage" -> accelerateLoginPage(result)
                "getLoginToken" -> getLoginToken(result)
                "finishLogin" -> finishLogin(call, result)
                "cancelLogin" -> {
                    dismissLoadingDialog()
                    quitLoginPageSafely()
                    completeLogin(response("cancelled", "CANCELLED", "已取消一键登录"))
                    result.success(response("cancelled", "CANCELLED", "已取消一键登录"))
                }
                "getVersion" -> result.success(
                    response("available", "OK", PhoneNumberAuthHelper.getVersion()),
                )
                else -> result.notImplemented()
            }
        } catch (error: Throwable) {
            handleSdkException(call.method, result, error)
        }
    }

    private fun configure(call: MethodCall, result: MethodChannel.Result) {
        val authInfo = call.argument<String>("authSdkInfo")?.trim().orEmpty()
        Log.i(LOG_TAG, "configure authInfoLen=${authInfo.length}")
        if (authInfo.isEmpty()) {
            configuredAuthInfo = ""
            Log.w(LOG_TAG, "configure 失败: AUTH_INFO_EMPTY")
            result.success(response("unavailable", "AUTH_INFO_EMPTY", "阿里云号码认证未配置"))
            return
        }

        if (configuredAuthInfo == authInfo && helper != null) {
            Log.i(LOG_TAG, "configure 已缓存，跳过")
            result.success(response("available", "OK", "SDK 已配置"))
            return
        }

        configuredAuthInfo = authInfo
        helper = PhoneNumberAuthHelper.getInstance(activity, emptyListener()).also {
            it.getReporter()?.setLoggerEnable(false)
            it.setAuthSDKInfo(authInfo)
            it.setAuthPageUseDayLight(true)
            it.keepAuthPageLandscapeFullSreen(true)
            it.keepAllPageHideNavigationBar()
            it.expandAuthPageCheckedScope(true)
        }
        Log.i(LOG_TAG, "configure 成功")
        result.success(response("available", "OK", "SDK 已配置"))
    }

    private fun checkEnv(result: MethodChannel.Result) {
        Log.i(LOG_TAG, "checkEnv 开始")
        val authHelper = ensureConfigured(result) ?: return
        val completed = AtomicBoolean(false)
        authHelper.setAuthListener(object : TokenResultListener {
            override fun onTokenSuccess(token: String?) {
                if (!completed.compareAndSet(false, true)) return
                val tokenRet = parseToken(token)
                val code = tokenRet?.code.orEmpty()
                val available = code == ResultCode.CODE_ERROR_ENV_CHECK_SUCCESS ||
                    code == ResultCode.CODE_SUCCESS
                Log.i(
                    LOG_TAG,
                    "checkEnv onTokenSuccess code=$code available=$available msg=${tokenRet?.msg}",
                )
                result.success(
                    response(
                        if (available) "available" else "unavailable",
                        code.ifEmpty { "UNKNOWN" },
                        tokenRet?.msg ?: if (available) "环境可用" else "当前环境不支持一键登录",
                    ),
                )
            }

            override fun onTokenFailed(token: String?) {
                if (!completed.compareAndSet(false, true)) return
                val tokenRet = parseToken(token)
                Log.w(
                    LOG_TAG,
                    "checkEnv onTokenFailed code=${tokenRet?.code} msg=${tokenRet?.msg} raw=$token",
                )
                result.success(
                    response(
                        "unavailable",
                        tokenRet?.code ?: "CHECK_ENV_FAILED",
                        tokenRet?.msg ?: "当前环境不支持一键登录",
                    ),
                )
            }
        })
        authHelper.checkEnvAvailable(PhoneNumberAuthHelper.SERVICE_TYPE_LOGIN)
    }

    private fun accelerateLoginPage(result: MethodChannel.Result) {
        val authHelper = ensureConfigured(result) ?: return
        authHelper.accelerateLoginPage(DEFAULT_TIMEOUT_MS, object : PreLoginResultListener {
            override fun onTokenSuccess(token: String?) {
                val tokenRet = parseToken(token)
                result.success(
                    response(
                        "available",
                        tokenRet?.code ?: ResultCode.CODE_SUCCESS,
                        tokenRet?.msg ?: "预取成功",
                    ),
                )
            }

            override fun onTokenFailed(code: String?, message: String?) {
                result.success(
                    response(
                        "unavailable",
                        code ?: "PRE_LOGIN_FAILED",
                        message ?: "一键登录预取失败",
                    ),
                )
            }
        })
    }

    private fun getLoginToken(result: MethodChannel.Result) {
        val authHelper = ensureConfigured(result) ?: return
        loginRequestId += 1
        val requestId = loginRequestId
        pendingLoginResult = result
        loginCompleted.set(false)
        configureAuthPage(authHelper)
        authHelper.setAuthListener(object : TokenResultListener {
            override fun onTokenSuccess(token: String?) {
                val tokenRet = parseToken(token)
                when (tokenRet?.code) {
                    ResultCode.CODE_START_AUTHPAGE_SUCCESS,
                    ResultCode.CODE_ERROR_USER_LOGIN_BTN,
                    ResultCode.CODE_ERROR_USER_CHECKBOX,
                    ResultCode.CODE_ERROR_USER_PROTOCOL_CONTROL,
                    ResultCode.CODE_START_AUTH_PRIVACY,
                    ResultCode.CODE_AUTH_PRIVACY_CLOSE,
                    ResultCode.CODE_CLICK_AUTH_PRIVACY_CONFIRM,
                    ResultCode.CODE_CLICK_AUTH_PRIVACY_WEBURL -> return
                    ResultCode.CODE_SUCCESS -> {
                        val providerToken = tokenRet.token.orEmpty()
                        authHelper.setAuthListener(null)
                        if (providerToken.isEmpty()) {
                            dismissLoadingDialog()
                            quitLoginPageSafely()
                            completeLogin(
                                response("error", "TOKEN_EMPTY", "一键登录授权令牌为空"),
                            )
                            return
                        }
                        showLoadingDialog()
                        completeLogin(
                            response(
                                "token",
                                tokenRet.code,
                                tokenRet.msg ?: "授权成功",
                                providerToken,
                            ),
                        )
                    }
                    else -> {
                        dismissLoadingDialog()
                        quitLoginPageSafely()
                        completeLogin(
                            response(
                                "error",
                                tokenRet?.code ?: "UNKNOWN",
                                tokenRet?.msg ?: "一键登录失败，请使用短信验证码登录",
                            ),
                        )
                    }
                }
            }

            override fun onTokenFailed(token: String?) {
                val tokenRet = parseToken(token)
                dismissLoadingDialog()
                runCatching { authHelper.quitLoginPage() }.onFailure {
                    Log.w(LOG_TAG, "getLoginToken quitLoginPage 失败", it)
                }
                authHelper.setAuthListener(null)
                val code = tokenRet?.code ?: "LOGIN_TOKEN_FAILED"
                completeLogin(
                    response(
                        if (isCancelCode(code)) "cancelled" else if (isUnavailableCode(code)) "unavailable" else "error",
                        code,
                        tokenRet?.msg ?: "一键登录失败，请使用短信验证码登录",
                    ),
                )
            }
        })
        authHelper.getLoginToken(activity, DEFAULT_TIMEOUT_MS)
        mainHandler.postDelayed({
            if (requestId != loginRequestId || loginCompleted.get()) {
                return@postDelayed
            }
            Log.w(LOG_TAG, "getLoginToken watchdog timeout")
            dismissLoadingDialog()
            quitLoginPageSafely()
            runCatching { authHelper.setAuthListener(null) }
            completeLogin(
                response(
                    "unavailable",
                    "LOGIN_TOKEN_TIMEOUT",
                    "一键登录超时，请使用短信验证码登录",
                ),
            )
        }, DEFAULT_TIMEOUT_MS + WATCHDOG_GRACE_MS)
    }

    private fun finishLogin(call: MethodCall, result: MethodChannel.Result) {
        val success = call.argument<Boolean>("success") ?: false
        val message = call.argument<String>("message")?.trim().orEmpty()
        activity.runOnUiThread {
            runCatching {
                if (success) {
                    dismissLoadingDialog()
                    quitLoginPageSafely()
                    result.success(response("available", "OK", "一键登录成功"))
                    return@runOnUiThread
                }

                dismissLoadingDialog()
                quitLoginPageSafely()
                if (message.isNotEmpty()) {
                    Toast.makeText(hostActivity(), message, Toast.LENGTH_SHORT).show()
                }
                result.success(
                    response(
                        "error",
                        "LOGIN_FAILED",
                        message.ifEmpty { "一键登录失败，请稍后重试" },
                    ),
                )
            }.onFailure { error ->
                handleSdkException("finishLogin", result, error)
            }
        }
    }

    private fun configureAuthPage(authHelper: PhoneNumberAuthHelper) {
        authHelper.removeAuthRegisterXmlConfig()
        authHelper.removeAuthRegisterViewConfig()
        authHelper.removePrivacyAuthRegisterViewConfig()
        authHelper.removePrivacyRegisterXmlConfig()
        authHelper.userControlAuthPageCancel()
        authHelper.setUIClickListener { code, _, json ->
            when (code) {
                ResultCode.CODE_ERROR_USER_CANCEL,
                ResultCode.CODE_ERROR_USER_SWITCH,
                ResultCode.CODE_ERROR_USER_CONTROL_CANCEL_BYBTN,
                ResultCode.CODE_ERROR_USER_CONTROL_CANCEL_BYKEY -> {
                    dismissLoadingDialog()
                    quitLoginPageSafely()
                    completeLogin(response("cancelled", code, "已取消一键登录"))
                }
                ResultCode.CODE_ERROR_USER_LOGIN_BTN -> {
                    if (json?.contains("\"isChecked\":false") == true) {
                        helper?.privacyAnimationStart()
                        helper?.checkBoxAnimationStart()
                    } else {
                        showLoadingDialog()
                    }
                }
            }
        }

        val orientation = if (Build.VERSION.SDK_INT == Build.VERSION_CODES.O) {
            ActivityInfo.SCREEN_ORIENTATION_BEHIND
        } else {
            ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT
        }

        authHelper.setAuthUIConfig(
            AuthUIConfig.Builder()
                .setNavColor(BACKGROUND)
                .setStatusBarColor(BACKGROUND)
                .setBottomNavColor(BACKGROUND)
                .setLightColor(false)
                .setNavText("手机号码登录")
                .setNavTextColor(TEXT_PRIMARY)
                .setNavTextSizeDp(17)
                .setPageBackgroundDrawable(ColorDrawable(BACKGROUND))
                .setLogoHidden(true)
                .setSloganText("运营商提供认证服务")
                .setSloganTextColor(TEXT_PRIMARY)
                .setSloganTextSizeDp(13)
                .setSloganOffsetY(222)
                .setNumberColor(TEXT_PRIMARY)
                .setNumberSizeDp(32)
                .setNumberTextSpace(0.3f)
                .setNumFieldOffsetY(172)
                .setLogBtnText("一键登录")
                .setLogBtnTextColor(Color.BLACK)
                .setLogBtnTextSizeDp(16)
                .setLogBtnWidth(315)
                .setLogBtnHeight(56)
                .setLogBtnOffsetY(286)
                .setLogBtnBackgroundDrawable(buttonDrawable(PRIMARY))
                .setSwitchAccHidden(false)
                .setSwitchAccText("切换账号")
                .setSwitchAccTextColor(PRIMARY)
                .setSwitchAccTextSizeDp(14)
                .setSwitchOffsetY(358)
                .setPrivacyState(true)
                .setPrivacyBefore("我已阅读并同意")
                .setPrivacyEnd("")
                .setVendorPrivacyPrefix("《")
                .setVendorPrivacySuffix("》")
                .setAppPrivacyColor(TEXT_SECONDARY, PRIMARY)
                .setPrivacyOperatorColor(PRIMARY)
                .setPrivacyTextSizeDp(12)
                .setProtocolGravity(Gravity.CENTER)
                .setPrivacyMargin(30)
                .setPrivacyOffsetY_B(72)
                .setLogBtnToastHidden(true)
                .setHiddenLoading(true)
                .setProtocolShakePath("authsdk_anim_loading")
                .setCheckBoxShakePath("authsdk_anim_loading")
                .setScreenOrientation(orientation)
                .create(),
        )
    }

    private fun showLoadingDialog() {
        runOnMain {
            runCatching {
                if (loadingDialog?.isShowing == true) {
                    return@runCatching
                }

                val host = hostActivity()
                val side = dp(host, 96)
                val content = FrameLayout(host).apply {
                    background = GradientDrawable().apply {
                        shape = GradientDrawable.RECTANGLE
                        cornerRadius = dp(host, 12).toFloat()
                        setColor(0xF0040505.toInt())
                    }
                }
                content.addView(
                    ProgressBar(host).apply {
                        isIndeterminate = true
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            indeterminateTintList = ColorStateList.valueOf(PRIMARY)
                        }
                    },
                    FrameLayout.LayoutParams(dp(host, 38), dp(host, 38), Gravity.CENTER),
                )

                loadingDialog = Dialog(host).apply {
                    requestWindowFeature(Window.FEATURE_NO_TITLE)
                    setCancelable(false)
                    setCanceledOnTouchOutside(false)
                    setContentView(content, ViewGroup.LayoutParams(side, side))
                    setOnDismissListener {
                        if (loadingDialog === this) {
                            loadingDialog = null
                        }
                    }
                    show()
                    window?.apply {
                        setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
                        setDimAmount(0.18f)
                        addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                    }
                }
            }.onFailure { error ->
                loadingDialog = null
                Log.e(LOG_TAG, "showLoadingDialog 失败", error)
            }
        }
    }

    private fun dismissLoadingDialog() {
        runOnMain {
            loadingDialog?.dismiss()
            loadingDialog = null
        }
    }

    private fun runOnMain(action: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            action()
        } else {
            activity.runOnUiThread(action)
        }
    }

    private fun hostActivity(): Activity {
        val candidate = foregroundActivity
        val destroyed = candidate != null &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1 &&
            candidate.isDestroyed
        return if (candidate != null && !candidate.isFinishing && !destroyed) {
            candidate
        } else {
            activity
        }
    }

    private fun ensureConfigured(result: MethodChannel.Result): PhoneNumberAuthHelper? {
        val authHelper = helper
        if (configuredAuthInfo.isEmpty() || authHelper == null) {
            Log.w(LOG_TAG, "ensureConfigured 失败: AUTH_NOT_CONFIGURED")
            result.success(response("unavailable", "AUTH_NOT_CONFIGURED", "阿里云号码认证未初始化"))
            return null
        }
        return authHelper
    }

    private fun completeLogin(value: Map<String, Any>) {
        if (!loginCompleted.compareAndSet(false, true)) return
        val result = pendingLoginResult
        pendingLoginResult = null
        activity.runOnUiThread {
            runCatching {
                result?.success(value)
            }.onFailure { error ->
                Log.e(LOG_TAG, "completeLogin 回传 Flutter 失败", error)
            }
        }
    }

    private fun handleSdkException(
        method: String,
        result: MethodChannel.Result,
        error: Throwable,
    ) {
        Log.e(LOG_TAG, "$method 调起阿里云一键登录 SDK 失败", error)
        dismissLoadingDialog()
        quitLoginPageSafely()
        runCatching { helper?.setAuthListener(null) }
        val payload = response(
            "unavailable",
            "SDK_EXCEPTION",
            "一键登录暂不可用，请使用短信验证码登录",
        )
        if (method == "getLoginToken" && pendingLoginResult != null) {
            completeLogin(payload)
            return
        }
        runCatching {
            result.success(payload)
        }.onFailure { callbackError ->
            Log.e(LOG_TAG, "$method 异常回传 Flutter 失败", callbackError)
        }
    }

    private fun quitLoginPageSafely() {
        runCatching {
            helper?.quitLoginPage()
        }.onFailure { error ->
            Log.w(LOG_TAG, "quitLoginPage 失败", error)
        }
    }

    private fun parseToken(token: String?): TokenRet? {
        if (token.isNullOrBlank()) return null
        return runCatching { TokenRet.fromJson(token) }.getOrNull()
    }

    private fun response(
        status: String,
        code: String,
        message: String,
        token: String? = null,
    ): Map<String, Any> {
        val data = mutableMapOf<String, Any>(
            "status" to status,
            "code" to code,
            "message" to message,
        )
        if (!token.isNullOrBlank()) {
            data["token"] = token
        }
        return data
    }

    private fun buttonDrawable(color: Int): StateListDrawable {
        val normal = rounded(color)
        val pressed = rounded(PRIMARY_PRESSED)
        val disabled = rounded(PRIMARY_DISABLED)
        return StateListDrawable().apply {
            addState(intArrayOf(-android.R.attr.state_enabled), disabled)
            addState(intArrayOf(android.R.attr.state_pressed), pressed)
            addState(intArrayOf(), normal)
        }
    }

    private fun rounded(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dp(activity, 18).toFloat()
            setColor(color)
        }
    }

    private fun dp(context: Context, value: Int): Int {
        return (value * context.resources.displayMetrics.density + 0.5f).toInt()
    }

    private fun isCancelCode(code: String): Boolean {
        return code == ResultCode.CODE_ERROR_USER_CANCEL ||
            code == ResultCode.CODE_ERROR_USER_SWITCH ||
            code == ResultCode.CODE_ERROR_USER_CONTROL_CANCEL_BYBTN ||
            code == ResultCode.CODE_ERROR_USER_CONTROL_CANCEL_BYKEY
    }

    private fun isUnavailableCode(code: String): Boolean {
        return code == ResultCode.CODE_ERROR_NO_SIM_FAIL ||
            code == ResultCode.CODE_ERROR_NO_MOBILE_NETWORK_FAIL ||
            code == ResultCode.CODE_ERROR_OPERATOR_UNKNOWN_FAIL ||
            code == ResultCode.CODE_ERROR_FUNCTION_DEMOTE ||
            code == ResultCode.CODE_ERROR_FUNCTION_LIMIT ||
            code == ResultCode.CODE_ERROR_FUNCTION_TIME_OUT ||
            code == ResultCode.CODE_ERROR_ANALYZE_SDK_INFO ||
            code == ResultCode.CODE_ERROR_ENV_CHECK_FAIL ||
            code == ResultCode.CODE_ERROR_INVALID_PARAM ||
            code == ResultCode.CODE_ERROR_NETWORK ||
            code == ResultCode.CODE_ERROR_FEATURE_INVALID ||
            code == ResultCode.CODE_ERROR_SDK_INFO_INVALID
    }

    private fun emptyListener(): TokenResultListener {
        return object : TokenResultListener {
            override fun onTokenSuccess(token: String?) = Unit
            override fun onTokenFailed(token: String?) = Unit
        }
    }

    companion object {
        private const val LOG_TAG = "AliyunAuth"
        private const val CHANNEL_NAME = "narrate/aliyun_number_auth"
        private const val DEFAULT_TIMEOUT_MS = 8000
        private const val WATCHDOG_GRACE_MS = 2000L
        private const val BACKGROUND = 0xFF080A0D.toInt()
        private const val PRIMARY = 0xFFD7FF47.toInt()
        private const val PRIMARY_PRESSED = 0xD1D7FF47.toInt()
        private const val PRIMARY_DISABLED = 0x61D7FF47
        private const val TEXT_PRIMARY = 0xFFF6F8FA.toInt()
        private const val TEXT_SECONDARY = 0xC7AAB2C0.toInt()
    }
}
