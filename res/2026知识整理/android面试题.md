# Android 面试题整理
---

## 目录（按主题）

| 分类 | 章节 |
|------|------|
| 动画 / UI 基础 | 01、10、25、29、34 |
| 线程 / 消息 / 后台 | 02、03、27、28 |
| Activity / Fragment | 04–08、26 |
| 数据与通信 | 09、11–13 |
| 兼容库与构建 | 14、21、33 |
| 稳定性与内存 | 15、19–20、22 |
| 图片与网络 | 16–17、30 |
| 虚拟机 | 18 |
| 原生与图形 | 23–25 |
| 工程化 | 31–32 |

---

## 01. Android 动画的种类及作用

- **视图动画（View Animation / 补间动画）**：`alpha` / `scale` / `translate` / `rotate`，作用于 `View` 绘制，不改变触摸区域与真实布局属性；API 简单。
- **属性动画（Property Animation）**：`ValueAnimator` / `ObjectAnimator`，可改任意属性，真正的数值变化，API 11+（现项目普遍可用）。
- **帧动画（Drawable Animation）**：逐帧 `AnimationDrawable`，适合简单序列帧。
- **作用**：提升交互反馈、引导注意力、状态过渡；复杂场景可配合 `AnimatorSet`、`Interpolator`。

---

## 02. 如何在 Android 中执行耗时操作

- **原则**：禁止在 **主线程（UI 线程）** 执行网络、大文件 IO、复杂计算，否则卡顿、ANR。
- **常见方式**：`Thread` + `Handler` / `runOnUiThread`；`HandlerThread`；`AsyncTask`（已废弃，老代码多见）；**Kotlin 协程**；`Executor` + 主线程切回；`WorkManager`（可延期、约束、持久化任务）。
- **IPC 场景**：重型工作放在 **Service / 独立进程** 等需另说绑定与进程间通信成本。

---

## 03. Handler 源码解析

- **模型**：`ThreadLocal<Looper>` 保证一线程一 `Looper`；`Looper.loop()` 从 `MessageQueue` 取 `Message`，交给 `target`（`Handler`）的 `dispatchMessage`。
- **入队**：`sendMessage` / `post` 最终 `enqueueMessage` 按时间插入队列；屏障消息、异步消息（`async`）与同步屏障属于进阶点。
- **切线程**：子线程准备 `Looper`（`Looper.prepare()` + `loop()`），或用主线程已有 Looper 的 `Handler` 的 `post` 回 UI。
- **泄漏**：非静态内部类 `Handler` 持有外部 `Activity` + 延迟消息未清空 → 典型内存泄漏；用 **静态内部类 + `WeakReference`** 或生命周期绑定取消回调。

---

## 04. 两个 Fragment 如何进行通信

- **通过宿主 Activity**：Activity 实现接口或由 Activity 转交回调（官方推荐、耦合可控）。
- **`FragmentResult` API**（AndroidX）：`setFragmentResultListener` / `setFragmentResult`，适合同 Activity 多 Fragment。
- **`ViewModel` 作用域 Activity**：共享数据，解耦 Fragment。
- **`EventBus` 等总线**：简单但全局，需注意注册/反注册与维护成本。

---

## 05. Activity 的生命周期

- **典型流程**：`onCreate` → `onStart` → `onResume`（可见可交互）→ `onPause` → `onStop` → `onDestroy`。
- **其他**：`onRestart`（从 stop 回到前台）；`onSaveInstanceState` / `onRestoreInstanceState`（配置变更或系统回收后恢复）；多窗口、画中画下 `onMultiWindowModeChanged` 等。
- **透明 / 对话框式 Activity**：可能只走到 `onPause` 不一定 `onStop`，备考时需区分场景。

---

## 06. Activity 之间如何进行通信

- **`Intent` + `startActivity`**：显式 / 隐式；`putExtras`（`Bundle`）传基本类型与 `Parcelable`。
- **`startActivityForResult` / Activity Result API**（现推荐 `registerForActivityResult`）：回传结果。
- **隐式 Intent**：`action` + `category` + `data` 匹配；需注意 Android 11+ 包可见性对查询组件的影响。
- **跨进程**：隐式/显式 + Multiprocess、AIDL、`Messenger` 等（按场景展开）。

---

## 07. 什么是 Fragment？它和 Activity 的关系

- **Fragment**：可复用的 UI 与逻辑单元，有自己的生命周期，但必须 **依附于 FragmentManager**（通常由 Activity 托管）。
- **关系**：Fragment **不是**四大组件；生命周期受宿主 Activity 影响；同一 Activity 可托管多个 Fragment（平板导航、单 Activity 多 Fragment 架构常见）。

---

## 08. 为什么只使用默认的构造方法来创建 Fragment

- **系统恢复**：配置变更或进程被杀后，框架通过**反射无参构造**重建 Fragment；带参构造无法被系统可靠恢复。
- **做法**：用 **`FragmentFactory` / `newInstance` 静态方法** + **`setArguments(Bundle)`** 传参；从 `getArguments()` 读取，保证重建后参数仍在。

---

## 09. Bundle 传递数据，为什么不用 HashMap 代替

- **跨组件 / 跨进程**：`Bundle` 底层与 **Binder 传输限制**一致，只允许框架允许的 **可序列化类型**（基本类型、`Parcelable`、`Serializable`、部分集合等），**parcel 化高效且类型安全**。
- **`HashMap`**：可含任意对象，**无法整体按 Android IPC 约定写入 Parcel**；若强行只装允许类型，也缺少与 Intent/`onSaveInstanceState` 等 API 的一致契约。
- **结论**：不是“能不能 new”，而是 **系统 API 与 IPC 协议约定用 Bundle**。

---

## 10. Activity、View 与 Window 的关系

- **Window**：抽象窗口，`PhoneWindow` 是具体实现；每个 Activity 持有一个 `Window`（`getWindow()`）。
- **DecorView**：`PhoneWindow` 的根 `View`，承载标题栏与内容区；`setContentView` 实质是把布局加入内容容器。
- **关系简述**：Activity 管理窗口与生命周期；Window 管窗口级行为（焦点、回调）；View 树负责绘制与触摸；**事件**从 `Window` → `DecorView` → 子 View 分发。

---

## 11. Serializable 与 Parcelable 的区别

| 维度 | Serializable | Parcelable |
|------|--------------|------------|
| 机制 | Java 标准，反射序列化对象图 | Android 专用，手写读写 Parcel |
| 性能 | 较慢，对象体积偏大 | 更快，适合 IPC 与 Intent |
| 使用 | `ObjectOutputStream` 等 | `writeToParcel` + `CREATOR` |
| 场景 | 持久化到文件、简单 Java 环境 | **Intent、Bundle、Binder 首选** |

Kotlin 可用 `@Parcelize` 减少样板代码。

---

## 12. Android 中的 Intent（显式与隐式）

- **显式**：指定 `ComponentName`（类），用于应用**内部**明确跳转。
- **隐式**：只声明 `action`、`category`、`data`（URI/MIME），由系统解析可处理组件；可弹出选择器；需 **Intent-filter** 匹配规则 **与** Android 11+ **包可见性**声明。
- **extras**：与显示/隐式正交，用于附加数据。

---

## 13. 广播与 EventBus 的区别

- **广播**：系统组件级机制，`BroadcastReceiver`；可**跨进程**（有序/无序）、系统事件（开机、网络）；注册分动态/静态（静态受限多）。
- **EventBus** 等：进程内**对象总线**，轻量、类型安全（可定义事件类）；**不替代**系统广播。
- **选型**：系统/跨应用 → 广播；应用内解耦 → `LiveData`/`Flow`/`ViewModel`/接口回调/EventBus（团队规范而定）。

---

## 14. 什么是 Support Library，为什么要引入？

- **含义**：Google **Android Support Library**（现多由 **AndroidX** 替代）向后移植新 API、提供兼容控件与工具类。
- **原因**：统一在旧版系统上使用 `RecyclerView`、`Fragment`、Material 等；修复平台差异；**不要**为每个 API 等级写分支。
- **现状**：新项目用 **AndroidX**，对应 `androidx.*` 包；Support Library 已迁移到 AndroidX 命名空间。

---

## 15. ANR 是什么？如何避免 ANR

- **定义**：**Application Not Responding**，主线程在超时时间内未处理完输入或广播等（具体时限如输入约 5s、广播约 10s，以官方文档为准）。
- **避免**：主线程不做耗时操作；减少主线程锁竞争；广播 `onReceive` 里尽快转后台线程；避免死锁与过度同步。
- **排查**：`traces.txt`、StrictMode、Systrace、主线程采样。

---

## 16. Bitmap 如何优化？三级缓存的思想与逻辑

- **Bitmap 优化**：**采样** `inSampleSize`；**复用** `inBitmap`（满足尺寸/格式条件）；**合适格式**（`RGB_565` 等）；及时 `recycle`（旧 API）/ 交给 GC（新）；列表里 **缩略图 + 取消未可见加载**。
- **三级缓存**：**内存缓存（LruCache）** → **磁盘缓存（DiskLruCache）** → **网络**；读取顺序由上到下，未命中则逐级加载并**回写**上级缓存。
- **目的**：减少解码次数与重复下载，降低 CPU 与流量消耗。

---

## 17. Glide 架构

- **要点**：面向生命周期的请求绑定（`RequestManager` 与 `Context`/`Fragment`）；**内存/磁盘/源**多级缓存与缓存策略；**线程池**解码在后台；**Registry** 扩展 `ModelLoader`、`ResourceDecoder`；与 **OkHttp** 等网络栈集成；GIF/缩略图等统一管线。
- **面试**：能描述 **Request → Engine → Decode → Transform → Target** 的大致数据流即可。

---

## 18. Dalvik 与 ART 的区别；Android 虚拟机

- **Dalvik**：JIT 为主时代；`.dex`；**解释执行 + 运行时 JIT**；偏省存储、启动与安装快。
- **ART**：**AOT**（安装时或混合 profile-guided 编译）、**更优 GC**、更成熟运行时；**性能与功耗模型不同**；现在设备均为 ART。
- **提法**：当前面试可关注 **dex 字节码、JIT/AOT、GC 演进、配置文件引导优化（PGO）** 等。

---

## 19. 内存泄漏

- **定义**：无用对象仍被引用链连着 GC Root，无法回收，内存持续上涨。
- **Android 常见**：`Context` 泄漏（静态持有 Activity）；`Handler` / `Callback` 未清理；匿名内部类持有外部类；`Bitmap` / 大集合未释放；`WebView` 使用不当；**未 unregister** 监听/广播。
- **工具**：LeakCanary、Android Studio Profiler；修复为 **断开引用、弱引用、生命周期感知组件**。

---

## 20. 内存溢出（OutOfMemory）是怎么发生的？

- **OOM**：申请内存时 **堆（或 Native）无法满足** 连续或大块分配，抛 `OutOfMemoryError`。
- **常见原因**：**大图**未经采样直接解码；内存泄漏堆积；**过多 Bitmap / 大数组**；Native 层泄漏（如 JNI）；线程栈过多等。
- **与泄漏关系**：泄漏不一定立刻 OOM，但会 **显著增加 OOM 概率**。

---

## 21. AAPT 是什么

- **Android Asset Packaging Tool**，资源打包工具（现多为 **AAPT2**）：**编译** `res` 下资源为二进制格式、生成 **`R.java`/`R.txt`**、打包 **resources.arsc**，参与 **APK** 构建链路。
- **考点**：资源 id、编译期优化、与 Gradle `aaptOptions`/命名冲突的关系。

---

## 22. 如何排除应用崩溃的原因

- **Java**：堆栈、复现路径、`try/catch` 边界是否合理、NPE/越界/生命周期。
- **Native**：**NDK 符号**、`tombstone`、`ndk-stack`、addr2line。
- **线上**：Firebase Crashlytics、Bugly 等；**符号表上传**；关键路径打日志与 **面包屑**。
- **流程**：稳定复现 → 本地 debug → 分层（应用 / 框架 / SO）→ 版本与 ROM 对比。

---

## 23. JNI 说明与编译

- **JNI**：Java/Kotlin 与 Native（C/C++）互调约定；`native` 方法 → `JNI_OnLoad` 动态注册或命名符号；注意 **`JNIEnv*` 线程本地**、**Local/Global 引用**生命周期。
- **编译**：CMake / ndk-build；`ABI` 过滤、`strip` 符号；与 **Gradle `externalNativeBuild`** 集成。

---

## 24. 什么是 NDK，它有什么用

- **NDK**：Native 开发套件，提供工具链、库与构建支持。
- **用途**：复用 C/C++ 库、性能敏感计算、音视频编解码、OpenGL/Vulkan、密码学、与嵌入式算法对接；**不必**全工程 NDK，按需下沉。

---

## 25. 什么是 SurfaceView

- **独立 Surface**：在独立 **Surface** 上绘制，可在**子线程**刷新，**不阻塞 View 层级**重绘；适合相机预览、视频、游戏画面。
- **对比 `TextureView`**：SurfaceView 合成层级与 **同步** 与 TextureView **不同**（TextureView 参与 View 变换更一致）；按场景选型。

---

## 26. 如何理解 Context

- **抽象**：访问环境全局信息与资源、启动组件、获取 `Service` 等的 **句柄**；`Application`、`Activity`、`Service` 等不同子类能力不同（如 **UI Theme** 仅 Activity 合适）。
- **泄漏**：**不要**长期持有 **Activity Context** 在单例里；无 UI 需求用 **ApplicationContext**（注意不能用于所有需要 window 的场景）。

---

## 27. Android 中可以用什么做后台操作

- **短时**：`WorkManager`、`JobScheduler`；前台 `Service`（通知栏可见）；`ForegroundService` API 随版本收紧需注意合规。
- **即时任务**：协程 / `Executor`；`IntentService`（已过时，可用 `WorkManager` + coroutine 替代思路）。
- **定位/下载等高敏感**：遵守 **后台启动限制、省电与白名单** 行为变更。

---

## 28. `onTrimMemory()` 方法是什么？

- **回调时机**：系统内存紧张时通知进程释放缓存，级别从 `TRIM_MEMORY_RUNNING_MODERATE` 到 **`UI_HIDDEN`、component、complete** 等。
- **作用**：**清图片缓存、断不可开连接、瘦身数据结构**，降低被杀概率与系统压力；与 `onLowMemory`（老进程整体）互补理解。

---

## 29. `LayoutInflater.inflate` 的意义与参数说明

- **作用**：把 **XML 布局**解析为 `View` 树。
- **常用重载**：`inflate(resource, root, attachToRoot)` —— **`attachToRoot=false`** 时 root 只用于 **生成 LayoutParams**，不把子 View 立刻 add 进 root（`RecyclerView`/`Fragment` 里常见）；**true** 则直接加入 root。

---

## 30. OkHttp 与 Retrofit 的区别与联系

- **OkHttp**：**HTTP 客户端**；连接池、拦截器、缓存、gzip、HTTPS；同步/异步 Call。
- **Retrofit**：**RESTful API 声明式封装**，底层默认 **OkHttp**；用接口 + 注解描述请求，负责参数、转换器（Gson/Moshi）、适配 Call（如 RxJava/Coroutines）。
- **关系**：Retrofit **依赖** OkHttp 发真实网络；可只说 Retrofit 是“类型安全的 API 层”。

---

## 31. 启动优化、速度优化等

- **冷启动**：减少 Application / 首 Activity `onCreate` 工作；**延迟初始化**（启动器后再 init）；统计 **第一帧**（`ReportFullyDrawn`、Systrace）。
- **布局**：减少过度绘制、合并布局、`ViewStub`、异步 inflate（谨慎）。
- **包体与类加载**：Multidex 成本；避免主线程大量反射与 IO。
- **运行时**：RecyclerView 缓存、图片、网络缓存；**内存/GC** 优化减少卡顿。

---

## 32. 插件化、热修复与组件化的区别

- **插件化**：**动态加载 APK/dex**，宿主调起插件内组件，解决 **大业务拆包、动态下发模块**（合规与系统限制多）。
- **热修复**：运行时替换 **类 / dex / 资源** 修复 bug，**不发版或小版本**；典型原理：Multidex、`ClassLoader`、Tinker、Sophix 等方案差异。
- **组件化**：工程 **模块化、接口驱动、独立编译**，未必动态加载；偏架构与 **构建效率**。
- **对比**：插件化偏 **动态安装模块**；热修复偏 **修 bug**；组件化偏 **工程拆分**。

---

## 33. APK 打包流程原理

- **简述**：**AAPT2** 编译资源 → `javac/kotlinc` 编译源码 → **dex**（`D8/R8`）→ **合并 dex 与资源** → **对齐 zipalign** → **`apksigner` 签名**。
- **工具链**：Proguard/R8 混淆收缩；CMake 产出 `.so`；中间产物在 `build/` 可对照理解。

---

## 34. View 相关面试题

- **测量布局绘制**：`measure` → `layout` → `draw`；`requestLayout` vs `invalidate`。
- **事件分发**：`dispatchTouchEvent`、`onInterceptTouchEvent`、`onTouchEvent`；滑动冲突（内外嵌套、横竖列表）。
- **自定义 View**：构造函数、`onMeasure`、`onDraw`、性能（避免 `onDraw` 创建对象）。
- **ListView/RecyclerView**：缓存与回收机制差异、ItemAnimator、`DiffUtil`。

---

## 复习建议

1. 源码类条目优先过一遍细节（Handler、Window、Glide、虚拟机、AAPT 等）。
2. **生命周期 + 线程模型 + Context + IPC（Intent/Bundle）** 构成 Android 基础必问闭环。
3. **内存**（泄漏 / OOM / Bitmap / onTrimMemory）与 **稳定性**（ANR / 崩溃）常和项目经验一起追问，准备 1～2 个真实排查案例更佳。
