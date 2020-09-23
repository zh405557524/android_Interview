# 一、四大组件

## activity 知识点

* 生命周期

  > 1、`onCreate` 、`onRestart`、`onStart`、`onResume`、`onPause`、`onStop`、`onDestroy`
  >
  > 2、`onPause` ->`onSaveInstanceState`、`onStart`->`onRestoreInstanceState`

* 启动模式

  > 1、`standard  `    标准模式、创建实例位于栈顶，谁启动就位于谁的栈顶
  >
  > 2、`singleTop` 栈顶复用模式 启动时，位于栈顶，复用，调用`onNewIntent` ,否则创建
  >
  > 3、`singleTask` 栈内复用模式  启动时，栈内存在 复用，上面实例清除 调用`onNewIntent` 否则创建
  >
  > 4、`singleInstance` 单例模式 寻找任务栈，存在直接复用，不存在创建任务栈，并将`activity`放入其中.

  


## activity面试题

* `Activity A `打开`Activity B` 按返回键的生命流程

  > A `onPause` -> B `onCreate` -> B `onStart`-> B `onResume` ->A `onStop` ->back ->B `onPause` -> A `onRestart` -> A `onStart` -> A `onResume` -> B `onStop` -> B `onDestroy`

## service 知识点

* 生命周期

  > 1 、`startService/stopService ` : `onCreate`-> `onStartCommand`->`ondestroy`
  >
  > 2、`bindService/unbindService`: `onCreate`->`onBind`->`onUnBind`->`onDestroy`
  >
  > 3、混合 同时使用  `onCreate` 只会执行一次，只有解除绑定后 `stopService` 才会生效

* `intentService`

  * 生命周期 `onCreate` ->`onStartCommand`->`onHandleIntent` ->`onDestroy` 
  * `onhandleIntent` 在子线程，并且任务执行完，则销毁。
  * 多次调用，耗时任务在 `onhandleIntent`中执行，第一个执行完，才执行第二个。

## service 面试题

* `startService`多次start会什么反应？ 会多次调用 `onStartCommand`

* `bindService` 多次`bind`会有什么反应？ 传入的`serviceConnection`参数是之前绑定的  无反应。

* 远程服务的创建过程

  * `step1` 在对应的文件目录下创建 `aidl `文件
  * `step2` 创建一个`service` ，并在内部实现`aidl `的接口函数，`onBind `返回这个实例。
  * `step3` 在`Android androidManifest` 设置该 `service` 对应的属性
  * `step4` 在client 来`bindservice` ，并在`serviceConnecet` 回调参数中 获取`onBind `返回的实例，来与`remote`进行交互
  * 保活，1 两个服务相互监听， 2 在断开服务链接 时 重新绑定， 3 使用死亡代理，service 死掉后，重新绑定。

* `service` 与 `intentService` 的区别

  * * `service`

      >  1、无法处理耗时任务，除非开启一个线程
      >
      >  2、长时间运行在后台，除非调用`stop`

    * `intentService`

      > 1、开启后 在`onHandleIntent`执行耗时操作，不会阻塞应用程序的主线程。
      >
      > 2、执行完任务后，自动停止
      >
      > 3、多次启动，耗时操作会以工作队列的方式在`onHandleIntent`回调中执行，并且，每次只会执行一个工作线程。

## 广播

* 特点：1 收到广播，无进程，自动创建 2 应用必须被打开过，广播才被执行。 3 强行停止后，不会自己创建进程，除非用户自己手动打开界面。
* 无序广播与有序广播。
  * 无序 注册可接受，不可中断、修改
  * 有序 按优先一级级传递，可中断、修改

* 动态广播，代码注册
* 静态广播，`androidMainfest` 注册，，开机，`sd`卡 。

## `ContentProvider`

* 管理对结构化的数据集方问。内部，实现了 增删改查四种操作。 `onCreate` 优先`appliaction`的创建。 `oncreate` 为什么在`application`之前

* 数据的升级

* `sql`语句

  * 创建表

    ~~~java
    CREATE TABLE <表名>(<列名> <数据类型>[列级完整性约束条件]
                      [,<列名> <数据类型>[列级完整性约束条件]]…);
    ~~~

  * 删除表`DROP TABLE <表名>;`

  * 清空表 `TRUNCATE TABLE <表名>;`

  * 修改表 

    ~~~java
    -- 添加列
    ALTER TABLE <表名> [ADD <新列名> <数据类型>[列级完整性约束条件]]
    -- 删除列
    ALTER TABLE <表名> [DROP COLUMN <列名>]
    -- 修改列
    ALTER TABLE <表名> [MODIFY COLUMN <列名> <数据类型> [列级完整性约束条件]]
    ~~~

  * 查询

    ~~~java
    SELECT [ALL | DISTINCT] <目标列表达式>[,<目标列表达式>]…
      FROM <表名或视图名>[,<表名或视图名>]…
      [WHERE <条件表达式>]
      [GROUP BY <列名> [HAVING <条件表达式>]]
      [ORDER BY <列名> [ASC|DESC]…]
    ~~~


## Fragment



	# 二、屏幕适配



	# 三、事件分发

> 事件分发 是指，用户手触摸屏幕所产生的一系列触摸事件，传递给view的一套流程
>
> 当`Actvity `收到触摸事件后，传递`ViewGrup`，`ViewGup`对事件进行分发，先判断是否分发，如果分发，事件结束；如果分发，再判断是否拦截，如果拦截，那么该`ViewGrup` 就对事件消费，在方法里面进行是否消费的判断，如果消费 执行对应代码后 事件结束，如果不消费，则分两种情况，当前的`ViewGrup` 是最外层的`ViewGroup`则事件结束，如果不是，则调用`ViewGroup`的父类的消息方法；这是`ViewGroup`对拦截的处理，如果不拦截，事件传递给View 的分发，先判断是否分发，如果不分发 就走父类的`onTouchEvent`，如果 分发，则走 当前`VIew` 的`onTouchEvent` ，如果消费则执行对应代码，如果不消费则传递给父类`ViewGroup`，的`onTouchEvent`处理，知道最外层的`ViewGroup`.
>
> 上面是一般事件的传递，当`ViewGroup` 对`down`事件进行拦截，那么接下来的move 跟up 事件，都会直接走`onTouchEvent`，不会再拦截
>
> 如果`ViewGroup`对down 事件不拦截，但对 move，up事件进行拦截，那么该事件会变成cancel 事件，传递给消费down事件的view，接下来的move跟up事件，就会走当前`ViewGroup`的`onTouchEvent`



* 相关面试问题
  * 如何判断是否拦截分发
  * `onTouchEvent`返回 `true` 或 `false` 是否能收到事件。
  * 父类如何判断子类是否消费。
  * 滑动冲突如何解决



	# 四、handler

* 流程

  > handler ，它是android消息机制的上层接口，它能将一个任务切换到handler 所在的线程去执行，常用的场景就是在子线程中做ui更新。
  >
  > 消息机制 主要包括: message、messageQueue、Handler、Looper这四个类，message 是需要传递的消息，可以传递数据；messageQueue 是消息队列，内部是通过一个单链表数据结构来维护的消息列表，主要功能是向消息池中 添加消息跟取走消息；handler 消息辅助类，主要是发送消息，和处理收到的消息；Loop  不断的执行循环 从 MessageQueue 中读取消息，按分发机制将消息发给目标。
  >
  > 首先，我们new handler  ，无参的handler 是不能子线程中 new 出来，因为子线程中 我们没创建好loop对象，调用Loop.prepare（）可以创建该线程的loop，然后调用Looper.loop（） ，进行消息循环。 
  >
  > 当我们的handler 创建好之后，封装好message对象，通过handler实例的发送消息的方法，将消息发送出去，handler 有很多发送消息的放过发，但是最终会调用 sendMessageAtTime 这个方法，里面 调用messageQueue 的enqueueMessage 这个方法 ，方法里面 做了两件事，一个是 消息按照时间顺序 添加到消息池中，另一个是调用nativeWake这个方法，讲线程唤醒，为什么要唤醒呢，因为再looper.loop的时候，不断循环从messageQueue中的消息获取消息，也就是调用了messageQueue.next 方法，这个方法里面 调用了一个本地方法 natviePollOnce 将线程睡眠了，唤醒线程后，loop会获取到消息池中的消息，message对象，接着调用 message .target.dispatchMessage ,也就是调用message 对应的handler对象的dispatchMessage 方法，里面调用handlerMessage方法，这个方法默认是空方法，由子类实现，子类收到消息后，就处理消息，这就是整个消息的传递。

* 面试相关问题

  * `LocalThread` 的理解

	# 五、view的绘制

* View绘制流程

  > View的绘制是从上往下一层层迭代下来的。decorView ->ViewGroup ->View,按照这个流程 依次 measure(测量)，layout(布局)，draw(绘制)。
  >
  > 先说测量，先调用measure()方法，进行一些逻辑处理，然后调用onMeasure()方法，然后在其中调用setMeasuredDimension() 设定View的宽高信息，完成View的测量操作，获得宽高的关键点在于 MeasureSpec这个类，它由两部分组成，一个是测量模式，另一个是测量尺寸大小，model 模式共分三类，第一种(unspecified)是不对view做限制，要多大，就有多大，第二种(exactly)对应对应layoutParams match_parent ,和具体的数值，这个view的大小是SpecSize 所指定的指，第三种(at_most)对应layoutParams 中的wrap_content.
  >
  > 测量完成后，进行布局摆放，也是自向而下的，不同的是ViewGroup 先在layout中确定自己的布局，然后再onLayout() 方法中调用子View的layout方法，让子View布局。测量时Viewgroup 一般是先测量子View 的大小，然后再确定自身大小。
  >
  > 最后是draw ，View 的绘制过程一般遵循下面几个：1 绘制背景 2 绘制自己 3 绘制子类 4 绘制装饰。
  >
  > 无论是ViewGroup 还是单一的VIew 都是需要实现这套流程，不同的是，在ViewGroup中，实现了dispatchDraw 方法，在单一VIew 中，不需要。定义View 一般要重写onDraw 方法，在其中绘制不同样式。
  >
  > 如果要实现自定义View 无外乎 onMeasure ,onLayout,onDraw 这个三个方法
  >
  > onMeasure 方法中:单一View，一般重写此方法,针对wrap_conent 情况，规定View默认的大小值。ViewGroup若不重写，就会执行单子View 相同逻辑，不会测量子VIew，一般会重写onMeasure()方法，循环测量子View。
  >
  > onlayout 单一VIew，不需要实现，ViewGroup必须实现，对子view进行布局
  >
  > onDraw view 或Viewgroup 都需要重写，因为是一个空方法。

* `Paint`

  * 概念: 画笔，保存绘制几何图形，文本，和位图的的样式和颜色

  * `api`：设置 颜色/透明度/锯齿/描边效果/边宽度/圆角效果/拐角风格/渲染器/图层模式/颜色过滤器/滤镜/文本缩放倍数/字体大小/对齐方式/下划线

    > 1、`setColor` 、`setARGB`设置颜色
    >
    > 2、`setAlpha` 设置透明度
    >
    > 3、 `setAntiAlias` 设置是否抗锯齿
    >
    > 4、`setStyle` //设置描边效果 有三种 fill 填充/ stroke 描边 / fill_and_stroke 填充并描边
    >
    > 5、`setStrokeWidth` 设置描边宽度
    >
    > 6、`setStrokeCap` 设置圆角效果  //三种 默认 /round 圆角/square 方形
    >
    > 7、`setStrokeJoin` 设置拐角风格 三种  MITER 尖角/ ROUND 切除尖角/BEVEL 圆角
    >
    > 8、

* `Shader`

* `Canvas`

  * 概念：画布，通过画笔绘制几何图形、文本、路径和位图

  * `API`

    * 1、绘制集合图形、文本、位图

    * 2、位置，形状变化

    * 3、状态保存和恢复

      > 1、`save()`保存状态
      >
      > 2、`restore()` 返回最新状态，上一个保存的状态
      >
      > 3、`restoreToCount(state)` 返回指定的状态 ，state为`save()`的返回值

      

* 

	# 六、动画

* 帧动画

* 补间动画

* 属性动画

  * 使用

    ~~~java
    Button btn = findViewById(R.id.btn);
    ObjectAnimator anim = ObjectAnimator.ofFloat(btn,"alpha",0f,1f);//透明度
    ObjectAnimator anim = ObjectAnimator.ofFloat(btn,"translationY",0,100f);//移动
    ObjectAnimator anim = ObjectAnimator.ofFloat(btn,"scaleX",0,1.0f);//缩放
    anim.setRepeatCount(ObjectAnimator.INFINITE);//无限重复
    anim.setRepeatMode(ObjectAnimator.RESTART);
    anim.setDuration(1000);
    ObjectAnimator anim = ObjectAnimator.ofFloat(btn,"alpha",0f,1f);//透明度
    anim.start();
    ~~~

    >  调用`ObjectAnimator`的静态方法 `onFloat`,传递发送改变的`VIew`，和要做的操作，数值的改变的起始值。返回一个`ObjectAnimator`对象，设置时间，次数，然后调用start启动


	# 七、bitmap
	# 八、LruCache原理
	# 九、虚拟机编译过程
	# 十、进程优先级
	# 十一、context
	# 十二、权限处理
	# 十三、版本差异

android 版本差异

* 4.4

  > 1. 支持全屏模式，也就是常说的沉浸式 
  >
  >    2. 虚拟按键可隐藏
  >       3. 为了加强webView 的功能，google 引入了chromiun内核。

* 5.0

  > 1. ART androidRunTime 取代 dalvik 成为平台默认设置，art采用预先编译技术，改进垃圾回收机制与调试支持。
  > 2. 添加 MaterialDesign 设计规范
  > 3. 禁用隐士意图启动服务，运行时会直接抛出异常。
  > 4. 移除了对锁定屏幕小部件的支持

* 6.0

  > 1.移除了 Apache 的http 支持包，需要手动引入
  >
  > 2.移除对设备本地硬件标识符的编程方问权限，需要申请权限。
  >
  > 3.运行权限管理，把权限分为三组  1 特殊权限，每次冷启动都会重置状态，不建议申请  2 敏感权限 运行时申请，没有设配会直接抛出异常 许可状态会保存(日历，相机，定位，录音，电话，短信，存储，网络)。

* 7.0

  > 1.支持应用分屏
  >
  > 2.删除 三个常用隐士广播，网络状态，拍照，录像的广播，因为这些广播可能会一次唤醒多个应用的后台进程，消耗内存和电量。
  >
  > 3.优化SurfaceView，使其在视频播放和3d方面表现优于TextureView.
  >
  > 4.引用了新的应用签名方案，APk signature sheme v2.它能提供更快的应用安装时间和更多针对未授权apk文件更改的保护

* 8.0

  > 1.自适应图标
  >
  > 2.添加两个权限，允许 接听呼入电话跟 允许应用读取设备中存储的电话号码。
  >
  > 3.新的广播接收器限制导致静态广播无法正常接受，应使用动态广播代替静态广播
  >
  > 4.申请了`SYSTEM_ALERT_WINDOW`权限的应用需要在其他应用和系统窗口上方显示提醒窗口时只能使用`TYPE_APPLICATION_OVERLAY`类型，之前的`TYPE_PHONE` `TYPE_PRIORITY_PHONE` `TYPE_SYSTEM_ALERT` `TYPE_SYSTEM_OVERLAY` `TYPE_SYSTEM_ERROR`不再生效
  >
  > 5.在 Android 8.0 之前，如果应用在运行时请求权限并且被授予该权限，系统会将同一权限组且在Manifest中注册的其他权限也一起授予应用。此行为在8.0被纠正：系统只会授予应用明确请求的权限。然而，一旦用户为应用授予某个权限，则所有后续对该权限组中权限的请求都将被自动批准。

* 9.0

  > 1.限制明文流量的网络请求，非加密的流量请求都会被系统禁止掉。
  >
  > 解决方案，
  >
  > ```xml
  > <?xml version="1.0" encoding="utf-8"?>
  > <network-security-config>
  > <base-config cleartextTrafficPermitted="true" />
  > </network-security-config>
  > ```
  >
  > 在manifest清单文件application节点配置`android:networkSecurityConfig="@xml/network_security_config"`

* 10

  > 1 TelephonyManger getDeviedID 需要申请权限。

# 十四、其他

* anr超时
  * ui 5s
  * service 前台 20s  后台 200s
  * 广播 前台 10s  后台60s
* 

