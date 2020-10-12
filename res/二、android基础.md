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
>
  > 
  >
  > Activity的堆栈管理以ActivityRecord为单位,所有的ActivityRecord都放在一个List里面.可以认为一个ActivityRecord就是一个Activity栈

* onSaveInstanceState (Bundle outState)

  >当某个activity变得“容易”被系统销毁时，该activity的onSaveInstanceState就会被执行，除非该activity是被用户主动销毁的，例如当用户按BACK键的时候。
  >
  >注意上面的双引号，何为“容易”？言下之意就是该activity还没有被销毁，而仅仅是一种可能性。这种可能性有哪些？通过重写一个activity的所有生命周期的onXXX方法，包括onSaveInstanceState和onRestoreInstanceState方法，我们可以清楚地知道当某个activity（假定为activity A）显示在当前task的最上层时，其onSaveInstanceState方法会在什么时候被执行，有这么几种情况：
  >
  >1、当用户按下HOME键时。
  >
  >这是显而易见的，系统不知道你按下HOME后要运行多少其他的程序，自然也不知道activity A是否会被销毁，故系统会调用onSaveInstanceState，让用户有机会保存某些非永久性的数据。以下几种情况的分析都遵循该原则
  >
  >2、长按HOME键，选择运行其他的程序时。
  >
  >3、按下电源按键（关闭屏幕显示）时。
  >
  >4、从activity A中启动一个新的activity时。
  >
  >5、屏幕方向切换时，例如从竖屏切换到横屏时。（如果不指定configchange属性） 在屏幕切换之前，系统会销毁activity A，在屏幕切换之后系统又会自动地创建activity A，所以onSaveInstanceState一定会被执行
  >
  >总而言之，onSaveInstanceState的调用遵循一个重要原则，即当系统“未经你许可”时销毁了你的activity，则onSaveInstanceState会被系统调用，这是系统的责任，因为它必须要提供一个机会让你保存你的数据（当然你不保存那就随便你了）。另外，需要注意的几点：
  >
  >1.布局中的每一个View默认实现了onSaveInstanceState()方法，这样的话，这个UI的任何改变都会自动地存储和在activity重新创建的时候自动地恢复。但是这种情况只有在你为这个UI提供了唯一的ID之后才起作用，如果没有提供ID，app将不会存储它的状态。
  >
  >2.由于默认的onSaveInstanceState()方法的实现帮助UI存储它的状态，所以如果你需要覆盖这个方法去存储额外的状态信息，你应该在执行任何代码之前都调用父类的onSaveInstanceState()方法（super.onSaveInstanceState()）。 既然有现成的可用，那么我们到底还要不要自己实现onSaveInstanceState()?这得看情况了，如果你自己的派生类中有变量影响到UI，或你程序的行为，当然就要把这个变量也保存了，那么就需要自己实现，否则就不需要。
  >
  >3.由于onSaveInstanceState()方法调用的不确定性，你应该只使用这个方法去记录activity的瞬间状态（UI的状态）。不应该用这个方法去存储持久化数据。当用户离开这个activity的时候应该在onPause()方法中存储持久化数据（例如应该被存储到数据库中的数据）。
  >
  >4.onSaveInstanceState()如果被调用，这个方法会在onStop()前被触发，但系统并不保证是否在onPause()之前或者之后触发。
  >
  >

* onRestoreInstanceState (Bundle outState)

  > 至于onRestoreInstanceState方法，需要注意的是，onSaveInstanceState方法和onRestoreInstanceState方法“不一定”是成对的被调用的，（本人注：我昨晚调试时就发现原来不一定成对被调用的！）
  >
  > onRestoreInstanceState被调用的前提是，activity A“确实”被系统销毁了，而如果仅仅是停留在有这种可能性的情况下，则该方法不会被调用，例如，当正在显示activity A的时候，用户按下HOME键回到主界面，然后用户紧接着又返回到activity A，这种情况下activity A一般不会因为内存的原因被系统销毁，故activity A的onRestoreInstanceState方法不会被执行
  >
  > 另外，onRestoreInstanceState的bundle参数也会传递到onCreate方法中，你也可以选择在onCreate方法中做数据还原。 还有onRestoreInstanceState在onstart之后执行。 

* 


## activity面试题

* `Activity A `打开`Activity B` 按返回键的生命流程

  > A `onPause` -> B `onCreate` -> B `onStart`-> B `onResume` ->A `onStop` ->back ->B `onPause` -> A `onRestart` -> A `onStart` -> A `onResume` -> B `onStop` -> B `onDestroy`
  
* **Activity缓存方法**

  > 有a、b两个Activity，当从a进入b之后一段时间，可能系统会把a回收，这时候按back，执行的不是a的onRestart而是onCreate方法，a被重新创建一次，这是a中的临时数据和状态可能就丢失了。
  >
  > 可以用Activity中的onSaveInstanceState()回调方法保存临时数据和状态，这个方法一定会在活动被回收之前调用。方法中有一个Bundle参数，putString()、putInt()等方法需要传入两个参数，一个键一个值。数据保存之后会在onCreate中恢复，onCreate也有一个Bundle类型的参数。

* **Intent的使用方法，可以传递哪些数据类型。**

  > 通过查询Intent/Bundle的API文档，我们可以获知，Intent/Bundle支持传递基本类型的数据和基本类型的数组数据，以及String/CharSequence类型的数据和String/CharSequence类型的数组数据。而对于其它类型的数据貌似无能为力，其实不然，我们可以在Intent/Bundle的API中看到Intent/Bundle还可以传递Parcelable（包裹化，邮包）和Serializable（序列化）类型的数据，以及它们的数组/列表数据。
  >
  > 所以要让非基本类型和非String/CharSequence类型的数据通过Intent/Bundle来进行传输，我们就需要在数据类型中实现Parcelable接口或是Serializable接口。

* 

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
  
* **IntentService的使用场景与特点。**

  > > IntentService是Service的子类，是一个异步的，会自动停止的服务，很好解决了传统的Service中处理完耗时操作忘记停止并销毁Service的问题
  >
  > 优点：
  >
  > - 一方面不需要自己去new Thread
  > - 另一方面不需要考虑在什么时候关闭该Service
  >
  > onStartCommand中回调了onStart，onStart中通过mServiceHandler发送消息到该handler的handleMessage中去。最后handleMessage中回调onHandleIntent(intent)。

* **为什么在Service中创建子线程而不是Activity中**

  > 这是因为Activity很难对Thread进行控制，当Activity被销毁之后，就没有任何其它的办法可以再重新获取到之前创建的子线程的实例。而且在一个Activity中创建的子线程，另一个Activity无法对其进行操作。但是Service就不同了，所有的Activity都可以与Service进行关联，然后可以很方便地操作其中的方法，即使Activity被销毁了，之后只要重新与Service建立关联，就又能够获取到原有的Service中Binder的实例。因此，使用Service来处理后台任务，Activity就可以放心地finish，完全不需要担心无法对后台任务进行控制的情况。

* **Service的两种启动方法，有什么区别**

  > 1.在Context中通过`public boolean bindService(Intent service,ServiceConnection conn,int flags)` 方法来进行Service与Context的关联并启动，并且Service的生命周期依附于Context(**不求同时同分同秒生！但求同时同分同秒屎！！**)。
  >
  > 2.通过` public ComponentName startService(Intent service)`方法去启动一个Service，此时Service的生命周期与启动它的Context无关。
  >
  > 3.要注意的是，whatever，**都需要在xml里注册你的Service**，就像这样:
  >
  > ```
  > <service
  >         android:name=".packnameName.youServiceName"
  >         android:enabled="true" />
  > ```

* **目前能否保证service不被杀死**

  > **Service设置成START_STICKY**
  >
  > - kill 后会被重启（等待5秒左右），重传Intent，保持与重启前一样
  >
  > **提升service优先级**
  >
  > - 在AndroidManifest.xml文件中对于intent-filter可以通过`android:priority = "1000"`这个属性设置最高优先级，1000是最高值，如果数字越小则优先级越低，**同时适用于广播**。
  > - 【结论】目前看来，priority这个属性貌似只适用于broadcast，对于Service来说可能无效
  >
  > **提升service进程优先级**
  >
  > - Android中的进程是托管的，当系统进程空间紧张的时候，会依照优先级自动进行进程的回收
  > - 当service运行在低内存的环境时，将会kill掉一些存在的进程。因此进程的优先级将会很重要，可以在startForeground()使用startForeground()将service放到前台状态。这样在低内存时被kill的几率会低一些。
  > - 【结论】如果在极度极度低内存的压力下，该service还是会被kill掉，并且不一定会restart()
  >
  > **onDestroy方法里重启service**
  >
  > - service +broadcast 方式，就是当service走onDestory()的时候，发送一个自定义的广播，当收到广播的时候，重新启动service
  > - 也可以直接在onDestroy()里startService
  > - 【结论】当使用类似口口管家等第三方应用或是在setting里-应用-强制停止时，APP进程可能就直接被干掉了，onDestroy方法都进不来，所以还是无法保证
  >
  > **监听系统广播判断Service状态**
  >
  > - 通过系统的一些广播，比如：手机重启、界面唤醒、应用状态改变等等监听并捕获到，然后判断我们的Service是否还存活，别忘记加权限
  > - 【结论】这也能算是一种措施，不过感觉监听多了会导致Service很混乱，带来诸多不便
  >
  > **在JNI层,用C代码fork一个进程出来**
  >
  > - 这样产生的进程,会被系统认为是两个不同的进程.但是Android5.0之后可能不行
  >
  > **root之后放到system/app变成系统级应用**
  >
  > **大招: 放一个像素在前台(手机QQ)**

## 广播

* 特点：1 收到广播，无进程，自动创建 2 应用必须被打开过，广播才被执行。 3 强行停止后，不会自己创建进程，除非用户自己手动打开界面。

* 无序广播与有序广播。
  * 无序 注册可接受，不可中断、修改
  * 有序 按优先一级级传递，可中断、修改

* 动态广播，代码注册

* 静态广播，`androidMainfest` 注册，，开机，`sd`卡 。

* **广播(Broadcast Receiver)的两种动态注册和静态注册有什么区别。**

  > - 静态注册：在AndroidManifest.xml文件中进行注册，当App退出后，Receiver仍然可以接收到广播并且进行相应的处理
  > - 动态注册：在代码中动态注册，当App退出后，也就没办法再接受广播了

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

* 生命周期

  * Created: onAttach -> onCreate -> onCreateView -> onActivityCreated
  * Started: onStart
  * resumed:OnResume
  * Paused: onPause
  * Stop: onStop
  * Destoryed:onDestroyView->onDestroy->onDetach

  > 注意和Activity的相比的区别,按照执行顺序
  >
  > - onAttach(),onDetach()
  > - onCreateView(),onDestroyView()

  - onAttach(Activity) 当Fragment与Activity发生关联的时候调用
  - onCreateView(LayoutInflater, ViewGroup, Bundle) 创建该Fragment的视图
  - onActivityCreated(Bundle) 当Activity的onCreated方法返回时调用
  - onDestroyView() 与onCreateView方法相对应，当该Fragment的视图被移除时调用
  - onDetach() 与onAttach方法相对应，当Fragment与Activity取消关联时调用



### 其他

* **Android的数据存储形式。**

  > - SQLite：SQLite是一个轻量级的数据库，支持基本的SQL语法，是常被采用的一种数据存储方式。 Android为此数据库提供了一个名为SQLiteDatabase的类，封装了一些操作数据库的api
  > - SharedPreference： 除SQLite数据库外，另一种常用的数据存储方式，其本质就是一个xml文件，常用于存储较简单的参数设置。
  > - File： 即常说的文件（I/O）存储方法，常用语存储大数量的数据，但是缺点是更新数据将是一件困难的事情。
  > - ContentProvider: Android系统中能实现所有应用程序共享的一种数据存储方式，由于数据通常在各应用间的是互相私密的，所以此存储方式较少使用，但是其又是必不可少的一种存储方式。例如音频，视频，图片和通讯录，一般都可以采用此种方式进行存储。每个Content Provider都会对外提供一个公共的URI（包装成Uri对象），如果应用程序有数据需要共享时，就需要使用Content Provider为这些数据定义一个URI，然后其他的应用程序就通过Content Provider传入这个URI来对数据进行操作。

* **如何判断应用被强杀**

  > 在Application中定义一个static常量，赋值为－1，在欢迎界面改为0，如果被强杀，application重新初始化，在父类Activity判断该常量的值。

* **应用被强杀如何解决**

  > 如果在每一个Activity的onCreate里判断是否被强杀，冗余了，封装到Activity的父类中，如果被强杀，跳转回主界面，如果没有被强杀，执行Activity的初始化操作，给主界面传递intent参数，主界面会调用onNewIntent方法，在onNewIntent跳转到欢迎页面，重新来一遍流程。

* **Json有什么优劣势。**

* **怎样退出终止App**

* **Asset目录与res目录的区别**

  > res 目录下面有很多文件，例如 drawable,mipmap,raw 等。res 下面除了 raw 文件不会被压缩外，其余文件都会被压缩。同时 res目录下的文件可以通过R 文件访问。Asset 也是用来存储资源，但是 asset 文件内容只能通过路径或者 AssetManager 读取。

* **Android怎么加速启动Activity**

  > 分两种情况，启动应用 和 普通Activity 启动应用 ：Application 的构造方法，onCreate 方法中不要进行耗时操作，数据预读取(例如 init 数据) 放在异步中操作 启动普通的Activity：A 启动B 时不要在 A 的 onPause 中执行耗时操作。因为 B 的 onResume 方法必须等待 A 的 onPause 执行完成后才能运行

* **Android内存优化方法**

  > **ListView优化，及时关闭资源，图片缓存等等。**

* **Android中弱引用与软引用的应用场景。**





# 二、屏幕适配

* 基础篇

  * 屏幕尺寸

    > 含义：手机对角线的物理尺寸
    > 单位：英寸（inch），1英寸=2.54cm
    > Android手机常见的尺寸有5寸、5.5寸、6寸等等

  * 屏幕分辨率(px)

    > 含义：手机在横向、纵向上的像素点数总和,一般描述成屏幕的"宽x高”=AxB
    >  单位：px（pixel），1px=1像素点
    >  UI设计师的设计图会以px作为统一的计量单位
    >  Android手机常见的分辨率：320x480、480x800、720x1280、1080x1920、2560x1440

  * 屏幕像素密度(dpi)

    > 屏幕像素密度是指每英寸上的像素点数，单位是dpi，即“dot per inch”的缩写。屏幕像素密度与屏幕尺寸和屏幕分辨率有关，在单一变化条件下，屏幕尺寸越小、分辨率越高，像素密度越大，反之越小。

  * 三者关系

    >![img](https://upload-images.jianshu.io/upload_images/11207183-0e8a67329cb00d37.png?imageMogr2/auto-orient/strip|imageView2/2/w/360/format/webp)
    >
    >例如：假设一部手机的分辨率是1080x1920（px），屏幕大小是5寸，问该手机的像素密度是多少？

  * 

* 







#  三、事件分发

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

* **View与View Group分类。**

* **自定义View过程**

  > **onMeasure()、onLayout()、onDraw()。**
  >
  > 如何自定义控件：
  >
  > 1. 自定义属性的声明和获取
  >    - 分析需要的自定义属性
  >    - 在res/values/attrs.xml定义声明
  >    - 在layout文件中进行使用
  >    - 在View的构造方法中进行获取
  > 2. 测量onMeasure
  > 3. 布局onLayout(ViewGroup)
  > 4. 绘制onDraw
  > 5. onTouchEvent
  > 6. onInterceptTouchEvent(ViewGroup)
  > 7. 状态的恢复与保存

  

* **View树绘制流程**

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

* **下拉刷新实现原理**

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
  
* **动画有哪两类，各有什么特点？三种动画的区别**

  > - tween 补间动画。通过指定View的初末状态和变化时间、方式，对View的内容完成一系列的图形变换来实现动画效果。 Alpha Scale Translate Rotate。
  > - frame 帧动画 AnimationDrawable 控制 animation-list xml布局
  > - PropertyAnimation 属性动画



# 七、bitmap

* **Bitmap的四种属性，与每种属性队形的大小。**







# 八、LruCache原理
# 九、虚拟机编译过程
# 十、进程优先级
# 十一、context

**Context区别**

> - Activity和Service以及Application的Context是不一样的,Activity继承自ContextThemeWraper.其他的继承自ContextWrapper
> - 每一个Activity和Service以及Application的Context都是一个新的ContextImpl对象
> - getApplication()用来获取Application实例的，但是这个方法只有在Activity和Service中才能调用的到。那么也许在绝大多数情况下我们都是在Activity或者Service中使用Application的，但是如果在一些其它的场景，比如BroadcastReceiver中也想获得Application的实例，这时就可以借助getApplicationContext()方法，getApplicationContext()比getApplication()方法的作用域会更广一些，任何一个Context的实例，只要调用getApplicationContext()方法都可以拿到我们的Application对象。
> - Activity在创建的时候会new一个ContextImpl对象并在attach方法中关联它，Application和Service也差不多。ContextWrapper的方法内部都是转调ContextImpl的方法
> - 创建对话框传入Application的Context是不可以的
> - 尽管Application、Activity、Service都有自己的ContextImpl，并且每个ContextImpl都有自己的mResources成员，但是由于它们的mResources成员都来自于唯一的ResourcesManager实例，所以它们看似不同的mResources其实都指向的是同一块内存
> - Context的数量等于Activity的个数 + Service的个数 + 1，这个1为Application



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
  >
  > - MaterialDesign设计风格
  > - 支持多种设备
  > - 支持64位ART虚拟机

* 6.0

  > 1.移除了 Apache 的http 支持包，需要手动引入
  >
  > 2.移除对设备本地硬件标识符的编程方问权限，需要申请权限。
  >
  > 3.运行权限管理，把权限分为三组  1 特殊权限，每次冷启动都会重置状态，不建议申请  2 敏感权限 运行时申请，没有设配会直接抛出异常 许可状态会保存(日历，相机，定位，录音，电话，短信，存储，网络)。
  >
  > - 大量漂亮流畅的动画
  > - 支持快速充电的切换
  > - 支持文件夹拖拽应用
  > - 相机新增专业模式

  

* 7.0

  > 1.支持应用分屏
  >
  > 2.删除 三个常用隐士广播，网络状态，拍照，录像的广播，因为这些广播可能会一次唤醒多个应用的后台进程，消耗内存和电量。
  >
  > 3.优化SurfaceView，使其在视频播放和3d方面表现优于TextureView.
  >
  > 4.引用了新的应用签名方案，APk signature sheme v2.它能提供更快的应用安装时间和更多针对未授权apk文件更改的保护
  >
  > - 分屏多任务
  > - 增强的Java8语言模式
  > - 夜间模式

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

* **anr超时**
  * ui 5s
  * service 前台 20s  后台 200s
  * 广播 前台 10s  后台60s
* **Android长连接，怎么处理心跳机制。**
* **SurfaceView和TextureView的比较**

