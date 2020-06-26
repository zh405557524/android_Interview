# 一、android四大组件与基础知识

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

* 启动流程    

  

## activity面试题

* `Activity A `打开`Activity B` 按返回键的生命流程

  > A `onPause` -> B `onCreate` -> B `onStart`-> B `onResume` ->A `onStop` ->back ->B `onPause` -> A `onRestart` -> A `onStart` -> A `onResume` -> B `onStop` -> B `onDestroy`

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

## 进程

## anr

* anr超时
  * ui 5s
  * service 前台 20s  后台 200s
  * 广播 前台 10s  后台60s
* 







****



# 二、事件分发、handler、自定义view

# 事件分发

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

# handler 

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



# 自定View

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

# 动画

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

  

****





# 三、性能优化

* 布局优化

  * 减少布局文件层级
  * RelatvieLayout 和linearLayout都可以使用时，优先考虑使用 LinearLayout
  * 采用标签 和ViewStub
  * 避免过度绘制

* 绘制优化

  * onDraw 不要创建局部对象
  * 不还耗时任务

* 内存泄漏优化

  * 在开发过程避免有内存泄漏的代码
    * 不被需要的内存空间会被回收
    * 2种方法分辨是否有用 1.引用计数 新增+1 释放-1 为0 清除   2. 可达性分析，对象是否有被外部引用，没有则清除。
    * 代码中会中存在逻辑不在使用，但是还存在引用，无法被回收。
    * 集合类泄漏 、单例/静态变量造成的内存泄露、匿名内-
    * 部类/非静态内部类、资源未关闭造成的内存泄露
  * 通过分析工具 比如mat 找出潜在的内存泄露，然后解决。
  * 还可以 使用 LeakCanary 来检测android 的内存泄漏。

* 响应速度优化

  * 避免在主线程中做耗时操作
  * 通过anr 日志分析，找到耗时的地方，在/data/anr/ traces.txt 文件里面。

* listView/RecycleView 及Bitmap优化

  * 使用ViewHolder 模式来提高效率。
  * 耗时操作放在子线程中
  * 图片进行压缩。避免oom出现。

* 线程优化

  采用线程池，或者使用handlerThread.

* 其他性能建议

  * 避免过度的创建对象
  * 不过过度使用枚举
  * 常量用static final 来修饰
  * 使用一些android 特有的数据结构，比如 SparseArray
  * 适当采用软引用和弱引用
  * 采用内存缓存和磁盘缓存
  * 尽量采用静态内部类，这样可以内存泄漏

* 内存泄漏处理

  * 集合类泄漏

    > 集合如果只是添加元素，而没有相应的删除机制，会导致内存被占用，如果是一个全局性的变量，例如一个静态属性的map集合，没有删除机制会导致内存增增不减，我们做缓存时要多留一些心眼

  * 单例造成的泄漏

    > 例如单例中的成员变量 传入了 actvity对象，会导致actvity 不会被回收。正确的做法是不传入 context，非要传入就传application ，这个生命周期跟应用一样长。

  * 非静态内部类 创建静态实例 

    > 例如在actvity 中 ，创建一个非静态内部类的一个静态实例，因为非静态内部类 会持有外部引用，该实例又是一个静态的那么它的生周期跟应用一样，持有actvity引用的静态实例，会导致actvity 内存资源不能正常回收，正确的做法是 使用静态内部类，或将这个实例封装成一个单例。

  * 匿名内部类

    > 例如在actvity 中创建 runnable 而runnable 的线程生命周期比actvity 生命周期长的话，runnable会持有actvity的引用，那么会导致actvity的内存泄漏。

  * handler 造成的内存泄漏

    > 创建handler 时，如果不是静态 会持有actvity 的引用
    >
    > handler 是属于 TLS(线程本地存储区) 变量，跟actvity的生命周期是不一致的，所以会造成actvity的内存泄漏，将handler 声明成 静态的就可以了，actvity 的context 可以采用 弱引用的方式传入。

  * 尽量避免使用static 成员变量

    > 如果 成员变量 被声明成static  那么生命周期与app进程一致，切到后台后，内存不会被释放，占内存较大的后台会优先被回收，如果做了保活，会造成app在后台频繁重启，这样时很耗电量与流量，解决方法 一时尽量避免 静态成员变量，二 时将 静态成员变量的生命周期管理起来。

  * 资源未关闭造成的内存泄漏

    > braodcastrReceiver, ContentObserver,file,游标 Cursor,Stream,BItmap 等资源的使用，应该在actvtiy 销毁时及时关闭或注销，否则这些资源将不会被回收，造成内存泄漏

  * 一些不良代码造成的内存压力

    * 例如 构建 Adapter 时，不使用缓存的 convertView ，每次创建 converView ，会造成内存压力，导致内存溢出，或者对大图片不进行压缩。



****



# 四、进程间通信

# bindler

* 1、概述

  * 1.1binder时一种进程间通信机制，基于开源的OpenBinder实现。
  * 1.2android的4大组件之间的通信依赖Binder IPC机制.系统对应用层的服务：AMS、PMS都是基于Binder IPC机制来实现。
  * 1.3linux 已有的ipc ：管道、消息队列、共享内存、socket。binder只需要一次数拷贝，而ssocket/管道/消息队列需要两次。binder 基于c/s架构，稳定性好。binder为每个app分配uid，进程的uid是鉴别进程身份的重要标志。（性能、稳定、安全)

* 2、linux下传统的进程通信原理

  * 2.1基本概念

    * 进程隔离

      > 1、操作系统中，进程与进程内存是不共享的
      >
      > 2、不同进程数据交互需要采用IPC机制。

    * 进程空间划分:用户空间(User Space)/内核空间(Kernel Space)

      > 1、内核空间是系统内核运行的空间，用户空间是用户程序运行的空间（1G内核/3G用户）
      >
      > 2.它们之间是隔离的。

    * 系统调用:用户态/内核态

      > 1.用户空间对内核空间进行访问，借助系统调用来实现。
      >
      > 2.linux 两级保护机制:0级供系统内核使用  ，3级供用户程序使用。
      >
      > 3.当一个任务(进程)执行系统调用而陷入内核代码中执行时，称进程处于内核运行态(内核态)。此时处理器处于特权级最高的(0级)内核代码中执行。执行的内核代码会使用当前进程的内核栈。每个进程都有自己的内核栈。
      >
      > 4.当进程执行用户自己的代码的时候，我们称其处于用户运行态(用户态)。此时处理器在特权级最低的(3级)用户代码中运行。
      >
      > 5.系统调用主要通过如下两个函数来实现
      >
      > copy_from_user()//将数据从用户空间拷贝到内核空间。
      >
      > copy_to_user() //将数据从内核空间拷贝到用户空间。

  * 2.2 linux下的传统ipc通信原理

    > 1.消息发送方：数据 ---放入--->内存缓存区中 ----系统调用----> 内核态 ---分配空间--->内核缓存区 -------copy_from_user-------->用户空间的内存缓存区拷贝到内核空间缓冲区中。
    >
    > 2.消息接受方: 用户空间开辟一块内存缓冲区-----copy_to_user----->将数据从内核缓冲区拷贝到接受进程的内存缓冲区。
    >
    > 缺点：
    >
    > 1.性能低下，一次数据传递需要经历：内存缓冲区--->内核缓冲区----->内存缓冲区，需要2次数据拷贝。
    >
    > 2.接受数据的缓冲区由数据接受进程提供，但是接受进程并不知道需要多大的空间来存放将来传递过来的数据，因此只能开辟尽可能达的内存空间或者先调用API接受消息头获取消息体的大小，这种做法不是浪费空间就是浪费时间。
    >
    > 
    >
    > 通常的做法是消息发送方将要发送的数据存放在内存缓存区中，通过系统调用进入内核态。然后内核程序在内核空间分配内存，开辟一块内核缓存区，调用 copy_from_user() 函数将数据从用户空间的内存缓存区拷贝到内核空间的内核缓存区中。同样的，接收方进程在接收数据时在自己的用户空间开辟一块内存缓存区，然后内核程序调用 copy_to_user() 函数将数据从内核缓存区拷贝到接收进程的内存缓存区。这样数据发送方进程和数据接收方进程就完成了一次数据传输，我们称完成了一次进程间通信。

* 3、binder 跨进程通信原理

  * 3.1  动态内核可加载模块 && 内存映射

    * 动态内核可加载模块

      > 1.传统ipc机制 (管道，socket) 都是内核的一部分,binder不是linux系统内核的一部分,
      >
      > 2.linux的 动态内核可加载模块 的机制。模块是具有独立功能的程序，它可以被单独编译，但是不能独立运行。它在运行时被链接到内核做为内核的一部分运行。android系统通过动态添加一个内核模块运行在内核空间。负责各个用户进程通过binder实现通信的内核就叫 Binder 驱动（binder dirver）。

    * 内存映射

      > 1.binder ipc 内存映射通过 mmap()来实现，mmap()是操作系统中一种内存映射的方法。
      >
      > 2.将用户空间的一块内存区域映射到内核空间，
      >
      > 3.映射关系建立后，用户对这块内存区域的修改可以直接反应到内核空间；反之内核空间对这段区域的修改也能直接反应到用户空间。
      >
      > 4.内存映射减少数据拷贝次数。

  * 3.2 Binder IPC 实现原理

    * mmap()  内存映射

      > 1.mmap()通常是用在有物理介质的文件系统上。
      >
      > 2.一般读取磁盘上的数据 需要 两次拷贝(磁盘->内核空间->用户空间)；mmap 通过物理介质和用户空间之间建立映射，减少拷贝次数。
      >
      > 3.binder 不存在物理介质，binder使用mmap(),用来在内核空间创建数据接受的缓存空间。

    * 完整的BInder IPC 通信过程通常是这样:

      > 1.首先binder驱动 在内核空间创建了一个**数据接受缓存区**；
      >
      > 2.接着在内核空间开辟一块**内核缓存区**，建立**内核缓存区**和内核中**数据接受缓存区**之间的映射关系，以及内核中数据接受缓存区和**接受进程用户空间地址**的映射关系。
      >
      > 3.发送方进程通过系统调用copy_from_user()将数据copy到**内核缓存区**，由于内核缓存区和接受进程的用户空间存在内存映射，因此也就相当于把数据发送到了接受进程的用户空间，这样便完成了一次进程进程间的通信。

* 4、Binder 通信模型

  * 4.1client/server/serviceManger/驱动
    * client、server、serviceManger运行在用户空间，binder驱动在内核空间。serviceManger和binder 由系统提供，client和server由应用程序实现
    * client、server和ServiceManager均是通过系统调用open、mmap和ioctl来访问设备文件/dev/binder，从而实现binder 驱动的交互来间接的实现跨进程通信。
  * 4.2 binder 通信过程
    * 1、首先一个进程使用 BINDER_SET_CONTEXT_MGR 命令通过binder驱动将自己注册成为 ServiceManger；
    * 2、server 通过驱动向serverManger 中注册Binder (Server中的bidner 实体)，表明可以对外提供服务。驱动为这个binder创建位于内核中的实体节点以及ServiceManger对实体的引用，将名字以及新建的引用打包传给ServiceManger，ServiceManger将其填入查找表。
    * 3、client通过名字，在binder驱动的帮助下从ServiceMager中获取到对Binder实体的引用，通过这个引用就能实现和Server进程的通信。
  * 4.3 Binder 通信中的代理模式
    * A进程获取b进程时的objet 时，驱动会返回一个跟object一样的代理对象，具有跟object一样的方法。 
    * 当binder 驱动接受到A 进程的消息后，发现这是个代理对象(objectProxy)就去查询自己维护的表单，一查发现这个是B进程object的代理对象。于是就会去通知B进程调用object的方法，并要求B进程把返回的结果发给自己。当驱动拿到B进程的返回结果后 就转发给A进程，这样一次通信就完成了。
  * 4.4 Binder 的完整定义
    * 从进程间通信的角度看，Binder是一种进程间通信机制；
    * 从server 进程的角度看Binder 指的是Server 中的BInder 实体对象。
    * 从client 进程的角度看，Binder指的是对Binder代理对象，是Binder实体对象的一个远程代理
    * 从传输过程的角度看，Binder 是一个可跨进程传输的对象；Binder驱动会对这个跨越进程边界的对象一点点特殊处理，自动完成代理对象和本地对象之间的转换。
  * 线程池
    * 客户端与binder建立链接 是有线程池做管理，当一个进程与binder的连接数大于16时，会被阻塞。

* 5、Binder四个重要对象

  * IBinder

    > 只要实现了这个接口 就具备了跨进程的能力

  * IInterface

    > server端具备什么样的能力，具备什么样的功能。

  * Binder

    > binder 的本地类，代理类

  * Stub

    > binder 的本地对象，server端给client的代理类

  * 一次binder android 的调用。

* 6、binder服务端的添加，删除

* 7、binder数据传输

* 

## AIDL

* 1、aidl的创建过程
  * step1 在对应的文件目录下创建 aidl 文件
  * step2 创建一个service ，并在内部实现aidl 的接口函数，onBind 返回这个实例。
  * step3 在Android androidManifest 设置该service 对应的属性
  * step4 在client 来bindservice ，并在serviceConnecet 回调参数中 获取onBind 返回的实例，来与remote进行交互
  * 保活，1 两个服务相互监听， 2 在断开服务链接 时 重新绑定， 3 使用死亡代理，service 死掉后，重新绑定。
* 



# 五、frarwork层原理

## 1、开机流程

## 2、system_service

## 3、PackageServiceManager

## 4、ActivityServiceManager

## 5、WindowServiceManger

## 6、Activity启动流程

## 7、Service启动流程

## 8、广播启动流程

## 9、内容提供者启动流程



****

# 六、编译

* 打包

  > 1. 打包资源文件，生成R.java文件  androidManifest.xmlres的资源变成二进制文件，
  > 2. 处理aidl文件，生成相应的java文件
  > 3. 编译项目源代码，生产class文件
  > 4. 转换所有的class文件，生成classe.dex文件
  > 5. 打包生产apk文件，assets的资源没有编译
  > 6. 对apk文件进行签名
  > 7. 对签名后的apk文件进行对齐处理，将apk包中所有资源文件距离文件起始偏移为4字节整数倍，这样通过内存映射方问apk文件时的速度会更快。对齐的作用就是减少运行时内存的使用

* v1 v2 v3 签名的区别

  > v1 方案：基于 JAR 签名。 - v2 方案：APK 签名方案 v2，在 Android 7.0 引入。 - v3 方案：APK 签名方案v3，在 Android 9.0 引入。
  >
  > 其中，v1 到 v2 是颠覆性的，主要是为了解决 JAR 签名方案的安全性问题，而到了 v3 方案，其实结构上并没有太大的调整，可以理解为 v2 签名方案的升级版。

  * v1签名

    > 签名过程:
    >
    > 1.首先使用SHA1算法对apk中每个文件生产摘要保存在MANIFEST.MF文件中
    >
    > 2.使用SHA1算法对MANIFEST.MF 做二次摘要生成CERT.SF文件。
    >
    > 3.使用私钥对CERT.SF签名，签名结果与公钥、证书一起打包
    >
    > 4.将以上文件保存在META-INF文件夹中
    >
    > 验证过程: 签名验证时发送在apk的安装过程中，一共分为三步:
    >
    > 1.检查APK中包含的所有文件，对应的摘要值与MANIFEST.MF文件中记录的值一致。
    >
    > 2.使用证书文件(RSA文件) 检验签名文件(SF文件) 没有被修改过
    >
    > 3.使用签名文件(SF 文件) 检验MF文件没有被修改过。
    >
    > 

  * v2签名

    > v2 签名会在原先 APK 块中增加了一个新的块（签名块），新的块存储了签名、摘要、签名算法、证书链和额外属性等信息，这个块有特定的格式。
    >
    > 总之，就是把 APK 按照 1M 大小分割，分别计算这些分段的摘要，最后把这些分段的摘要在进行计算得到最终的摘要也就是 APK 的摘要。然后将 APK 的摘要 + 数字证书 + 其他属性生成签名数据写入到 APK Signing Block 区块。
    >
    > 

  * v3 签名

    > 与v2签名相似，不同的是添加了新的证书(Attr块)，在这个新块中，会记录我们之前的签名信息以及新的签名信息，以密钥转轮的方案，来做签名的替换和升级。这意味着，只要旧签名证书在手，我们就可以通过它在新的 APK 文件中，更改签名。

* apk 安装过程（安装其实就是把apk文件copy到对应的目录）

  * data/app/包名------安装时把apk文件复制到此目录，---可以将文件取出并安装，喝我们本身的apk是一样的
  * data/data/包名------开辟存放应用程序的文件内数据的文件夹包括我们应用的so库，缓存文件
  * 将apk中的dex文件安装到data/dalvik-cache目录下(dex文件时dealvik虚拟机的可执行文件，其大小约位原始apk文件大小的四分之一)

* 

























































