# 一、常见问题

* handler

  > handler ，它是android消息机制的上层接口，它能将一个任务切换到handler 所在的线程去执行，常用的场景就是在子线程中做ui更新。
  >
  > 消息机制 主要包括: message、messageQueue、Handler、Looper这四个类，message 是需要传递的消息，可以传递数据；messageQueue 是消息队列，内部是通过一个单链表数据结构来维护的消息列表，主要功能是向消息池中 添加消息跟取走消息；handler 消息辅助类，主要是发送消息，和处理收到的消息；Loop  不断的执行循环 从 MessageQueue 中读取消息，按分发机制将消息发给目标。
  >
  > 首先，我们new handler  ，无参的handler 是不能子线程中 new 出来，因为子线程中 我们没创建好loop对象，调用Loop.prepare（）可以创建该线程的loop，然后调用Looper.loop（） ，进行消息循环。 
  >
  > 当我们的handler 创建好之后，封装好message对象，通过handler实例的发送消息的方法，将消息发送出去，handler 有很多发送消息的放过发，但是最终会调用 sendMessageAtTime 这个方法，里面 调用messageQueue 的enqueueMessage 这个方法 ，方法里面 做了两件事，一个是 消息按照时间顺序 添加到消息池中，另一个是调用nativeWake这个方法，讲线程唤醒，为什么要唤醒呢，因为再looper.loop的时候，不断循环从messageQueue中的消息获取消息，也就是调用了messageQueue.next 方法，这个方法里面 调用了一个本地方法 natviePollOnce 将线程睡眠了，唤醒线程后，loop会获取到消息池中的消息，message对象，接着调用 message .target.dispatchMessage ,也就是调用message 对应的handler对象的dispatchMessage 方法，里面调用handlerMessage方法，这个方法默认是空方法，由子类实现，子类收到消息后，就处理消息，这就是整个消息的传递。
  >
  > 
  
* 事件传递机制

  >  事件分发 是指，用户手触摸屏幕所产生的一系列触摸事件，传递给view的一套流程
  >
  > 当Actvity 收到触摸事件后，传递ViewGrup，ViewGup对事件进行分发，先判断是否分发，如果分发，事件结束；如果分发，再判断是否拦截，如果拦截，那么该ViewGrup 就对事件消费，在方法里面进行是否消费的判断，如果消费 执行对应代码后 事件结束，如果不消费，则分两种情况，当前的ViewGrup 是最外层的ViewGroup则事件结束，如果不是，则调用ViewGroup的父类的消息方法；这是ViewGroup对拦截的处理，如果不拦截，事件传递给View 的分发，先判断是否分发，如果不分发 就走父类的onTouchEvent，如果 分发，则走 当前VIew 的onTouchEvent ，如果消费则执行对应代码，如果不消费则传递给父类ViewGroup，的onTouchEvent处理，知道最外层的ViewGroup.
  >
  > 上面是一般事件的传递，当ViewGroup 对down事件进行拦截，那么接下来的move 跟up 事件，都会直接走onTouchEvent，不会再拦截
  >
  > 如果ViewGroup对down 事件不拦截，但对 move，up事件进行拦截，那么该事件会变成cancel 事件，传递给消费down事件的view，接下来的move跟up事件，就会走当前ViewGroup的onTouchEvent
  >
  > 
  
* View 绘制流程

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

* 滑动冲突的解决

  > 1、方向不同的冲突。listView与ViewPage 出现冲突，根据滑动是水平滑动还是竖直滑动来判断由谁来拦截事件，判断滑动方向的方法是：比较水平方向和竖直方向滑动距离的大小，或者滑动路径和水平方向的夹角，或者根据水平方向和竖直方向的速度差。
  >
  > 2、方向相同的冲突。这种情况的滑动冲突，无法根据滑动的角度判断，一般都是根据业务需要来进行判断。
  > 3、上面两种复合的情况，跟具体的业务 来做对应的处理。

* 进程通讯

  * intent ->binder
  * 文件共享
  * Messeneger
  * aidl
  * CotnentProvider
  * socket

* 进程保活

  * 开启一个像素的Activity

  * 使用前台服务

  * 多进程相互唤醒

  * 系统服务捆绑

  * socket 如何做到进程保活

    > 1.保活实现原理：在ndk层，fork()一个子进程，子进程作为一个socket的服务端，应用进程(父进程)作为socket的客户端，客户端与服务端使用socket进行连接，正常情况下客户端并不向服务端发送任何数据，read()函数一直阻塞，当客户端被kill之后，连接就会断开，read()函数被执行，然后使用execlp()函数执行am startservice命令重启服务。 .
    > 根据个人对linux的系统的了解，所谓进程保活就是在进程被kill之后，能够重新开启服务，使用其它方式应该也是可以的，如使用信号量机制，进程是可以注册监听某些信号量和屏蔽某些信号的，当接收到自己被kill的信号的时候，可以重启服务。

* 线程通信

  * handler
  * runOnUIThread
  * View.post()
  * AsyncTask

* http和https的区别、基础什么协议、get与post的区别

  * http是超文本协议传输，信息是明文传输。https则是具有安全性的ssl加密传输协议
  * http的连接很简单，是无状态的。Https协议是由SSL+Http协议构建的可进行加密传输、身份认证的网络协议，比http协议安全

* 单例模式(创建的安全方式)

  * 双重锁模式
  * 静态内部类单例模式
  * 枚举

* service和IntentService 的区别、什么情况使用service、进程保活。

  * service 长期存在的 intentService 执行完任务后 会自动销毁
  * service 代码执行时在主线程 intenntservice 在onHandleIntent 执行的代码是在子线程。可以做耗时操作。
  * service 在需要长期使用，但不要界面，在后台运行就可以使用服务。比如播放器，检查sd，或者定位之类的功能
  * 批量执行任务时，如果对性能开销有严格要求时，可以考虑使用IntentService

* launcher启动流程

* System启动流程

  > 当系统引导程序启动 Linux 内核时，内核会加载各种数据结构和驱动程序，有了驱动之后，开始启动android 系统 并加载用户级别第一个进程 init,init 里面 加载 init.rc 文件，接着调用App_Main.cpp 里面启动 zygote 进程 并加载 java类 ZygoteInit ，  里面加载SystemServer 这个类，里面启动了各种系统服务(例如AMS,PMS,WMS)，接着调用asm的方法 systemReady，在这个任务里面，启动SystemUI 跟laucher。

* actvity 的启动流程

  > 当点击launcher 界面图标时，launcher 会向ams 发起开启 actvity 的请求，ams 会查这个应用的进程是否已经创建了，如果没有创建，就通过socket的方式，通知zygote 去创建进程，就时调用Proceed.start 方法，这时会把actvtiyThread 类名传递过去，zygote 创建新进程后就调用它的main方法，接着调用 启动actvity的方法，经过一系列复杂的调用最终，调用actvtiyThread 的performLauncheActvity 将actvity 显示到前台。

* glide各大图片框架的区别

  > picasso 与glide 区别在于 picasso 比glide体积下，且图像质量比glide高，glide速度比picasso快，glide 长处处理大型图片流如gif、video。
  >
  > fresco 5.0以下非常好，但是它的不足是体积太大，

* ffmpeg 支持 h264、aac、pcm，也支持一些常见的格式，例如mp3、mp4、flv、hls、webm 的解码

* 性能优化

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
    * 采用线程池，或者使用handlerThread.
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

* 热更新原理与插件化原理

  > 热更新技术 主要分两种一个是 native 层，一个java 层，tinker 是属于java 层替换，andfix 是native hook 技术。说下tinker 的原理，它是将新旧app 进行对比生成dex分包，里面是需要替换的class类 。
  >
  > 说下 android 的cloassloader 的流程，遇到需要触发加载类的指令的时候，去对应的dex包中 加载对应的class，类初始化时会检测该类已经被验证过，如果未验证 就进行验证，tinker 主要是在加载类的时候，进行替换，然后通过校验。andfix 主要是native层的在方法区 讲有bug 的方法替换成无bug 的方法。
  >
  > 插件化，是通过反射 将apik的路径 加入到AssetManager中，在通过宿主中的actvity 专门加载插件中的actvity。

* Matrix 原理

* 网络链接socket ，tcp，udp

  > 网络我们分 应用层 ，传输层，网络，网络接口。tcp 跟upd 是传输层协议，socket 不是协议，他是应用与传输层通信的中间软件抽象层，是一组调用接口 是 tcp/ip 协议的api 。
  >
  > 传输层的tpc 是基于网络层的pi协议，应用的http 是基于传输层的tcp协议 ，socket 是提供一个针对tcp或者udp的编程接口

* tpc 与udp的区别

  * tcp 需要将传输的文件分段 传输 简历会话 可靠传输 流量控制 比如 方问 网页，发送邮件，下载。都是用的tcp 协议
  * udp 一个数据就能完成数据通讯 不分段 不需要建立会话  不需要流量控制  不可靠输出  例如 请求dns ，qq聊天发送消息，还比如特殊的 直播推流。
  
* tcp 三次握手与4次挥手

  * 传输连接有三个阶段,即：连接建立、数据传送和连接释放
  * TCP 连接的建立都是采用客户服务器方式 
  * 主动发起连接建立的应用进程叫做客户(client)
  * 被动等待连接建立的应用进程叫做服务器(server) 

  * 先手客户端发送一个 同步数据包 ，tcp 首部(同步标记)(SYN)是 1 ，确认标记(ACK)是0，序号是一个数值，服务端受到这个数据包 就知道是一个主动发起连接的数据包，服务器会发送一个数据包进行回应，首部是1，确认标记是 1 ，序号是 服务器指定的数值，确认号(ack) 是客户端的数值+1，接着客户端发送一个数据包给服务端，确认标记 是1，序号是 客户端指定的数值+1,确认号是服务端数值+1.这样就成功建立一个tpc连接，客户端与服务器开始进行数据传输。
  * 两次就可以确定通信为什么需要三次，因为，在网络不好的情况下，客户端会发多次建立连接的请求，服务端多次响应服务端的请求，但是，客户端收到过一次确认数据包后，会不认这个确认，但服务端会一直等待 客户端的数据传输，这样会造成资源浪费，所以需要第三个数据包的确认。
  * 通信结束后，需要释放连接，客户端发送一个数据包给服务器 FIN = 1,服务器收到这个数据包后，给客户端一个确认，客户端不在发送数据给服务端，但是服务端会发送数据给客户端，当服务端数据发送完了，会发送一个数据包，FIN = 1，客户端会给你服务器一个确认包，然后他们不会发送数据了，连接就释放了。服务器会关掉连接，客户端会等待 2个报文传输时间，也就是4分钟。因为客户端发送给服务端的确认包，会丢失，如果客户端关闭了，那么服务器发送给客户端的关闭包，客户端就不会做处理，服务器就不会关闭，造成资源的浪费。

* SystemUI

  > 

* 视频显示到屏幕的过程

  > 当我们拿到视频数据后，先进行解协议，一般是mpeg4 协议，然后解封装，MP4，rmvb 是封装格式，解完封装拿到 压缩的音视频数据，然后对音视频进行解码，视频一般是h264 ，音频一般是acc ，这样就拿到原始的视频数据，然后渲染到surfaceView里面
  
* anr超时

  * ui 5s
  * service 前台 20s  后台 200s
  * 广播 前台 10s  后台60s

* jni 原理

  * jni的注册

  * jni的调用过程

  * system.load过程

    > System.loadLIbrary ->Runtime.loadLIbrary  ->Runtime.doLoad ->nativeLoad()-->ART虚拟机`java_lang_Runtime.cc`
    >
    > 总之，System.loadLibrary()的作用就是调用相应库中的JNI_OnLoad()方法。

* jni 调用过程

  > 1.首先在CMake文件 设置 jni库的名称，以及该库关联的c文件代码。
  >
  > 2.在java 代码通过System.load()加载对应的jni库，它最终是调用Java类 Runtime 里面的一个nativeLoad 方法 进入ART虚拟机，打开个so库文件，并查看so文件并调用 其 JNI_OnLoad() 函数指针。调用androidRuntime的注册jni的函数将该so库中的 java与c的映射数组 注册到jni中。
  >
  > 3.我们在java 中创建一个native 的方法，在c代码中创建一个相互对应的方法。在这个方法中，可以调用c层代码。
  
* jni 如何调用 java 方法

  > 1 首先通过jniEnv 的方法 findClass() 拿到java 的class对象。
  >
  > 2 通过getMethodID,传入对应的class，方法名，和返回值 获取到JmethodID 对象
  >
  > 3 实例化这个class，得到时候话对象jobject
  >
  > 4 调用jniEnv 的CallStringMethod(CallLong)传入实例化对象与方法对象，这样就成功调用了java的方法，并获得返回值。

* jni使用中的注意事项

  > 1 jni 与c 数据传递，将java数据转换成c能使用的数据，都是本地引用，存入jni的本地数据库中，需要释放。
  >
  > 2 c的对象可以通过强转来转递给java （jlong），在java 传递c 层 ，再强转回来。
  >
  > 3 jni 使用大量 java层 数据对象时，需及时释放，jni的本地引用数据库，只有512个

* 视频流与音频流

  * 视频流

    > 首先我们打开视频文件，会得到视频流和音频流，找到视频流，获取视频流的解码参数(宽度，高度)，拿到解码器(h264)   ，打开解码器 进行解码 得到yuv数据包 ，然后转成rgb数据，进行渲染绘制在屏幕上。

  * 音频流

    > 首先我们打开音频文件，找到音频流，找到解码器 ，通过解码器读取数据包，解压缩数据，通过解码器获取 采样率，声道布局，和采样格式 转成统一的 输出数据，再写入扬声器中
    
  * 音视频同步的实现方式
  
    > 以音频的时间为准，打开视频文件后，会得到视频流跟音频流，通过对应的解码器，给音频流跟视频流进行解码，会得到解压后的数据，ffmpeg里面 是一个 AVFrame 的对象，通过这个对象，都可以拿到 对应的pts，跟time_base;pts 是时间进度，time_base是时间刻度，表示每一份pts的时间是多少，通过pts跟time_base 就可以算出当前帧的时间是多少，然后拿音频流的时间跟视频的时间 进行比较，视频的时间超前，就放慢速度，视频渲染时的睡眠时间加长，如果，视频时间落后了，那么就减少等待时间，如果落后的时间过长，直接丢弃，进入最新解码帧。

## 二、android 基础问题

### 四大组件

#### Actvity

* 典型生命周期，与异常情况的生命周期

  * 典型生命周期

    * onCreate:  创建 初始化  加载布局资源 
    * onRestart: 重启启动，从不可见变为可见  按home 键
    * onStart：启动 已出现不可见
    * onResume：获取焦点，可见，前台显示
    * onPause：失去焦点，正在停止，  不做耗时操作，
    *  onStop: 停止，进入后台，不可见，位于后台，可做稍微耗时
    * onStop：销毁，回收工作，资源回收

  * 异常情况的生命周期

    * onSaveInstanceState

      > 被异常杀死的时候，会调用这个方法，
      >
      > 1 横竖屏切换  onPause -> onSaveInstanceState->onStop -> onDestroy->onCreate->onStart->onRestoreInstanceState->onResume 
      >
      > 2 资源内存不足导致优先级低的activity 被杀死
      >
      > 1)前台actvity		resumed（活动状态）
      >
      > 2)可见非前台Actvity ，弹出对话框
      >
      > 3) 后台activity ,执行了stop （停止状态）

* activity 的启动模式

  * 任务栈

    > actvity的管理采用任务栈的形式，后进先出

  * 标准模式 standard  创建实例位于栈顶，谁启动 就位于谁的栈顶

    > service or application 启动 activity  设置 FLAG_ACTVITY_NEW_TASK 5.0之前放入Intent 的task ，5.0之后 新建task

  * 栈顶复用模式 singleTop 位于栈顶 复用 调用 onNewIntent，否则创建。

    > taskAffinity 可以指定 actvity 放入的栈，没有指定 就是 application的taskAffinity ，默认是包名。

  * 栈内复用模式 sinleTask  寻找对应的栈 ，不存在则创建，栈内寻找actvity 实例，不存在 则创建 ，存在 在 此actvity 实例之上 actvity 杀死 清除出栈，重用 该实例，调用 onNewIntent

    > 主界面，只要返回主界面，不管开了多少actvity 都会被清楚，主界面退出应用，保证所有的actvity 都被销毁。

  * 单例模式  创建 新的任务栈，新建actvity 放入栈中，如果存在，复用该是实例。

* actvtiy的启动 流程

* A actvity 到B activity的生命流程  

  * A onPause -> B  onCreate -> onStart -> onRusume-> B onStop

#### Fragment

* 与activity相比有什么特点  轻量级ui ，快速切换

* 生命周期

  * onAttach fragment 与 actvity 发生关联
  * onCreate  
  * onCrateView  创建fragment 的视图
  * onActvityCreated  actvtiy onCreated 方法 回调 
  * onStart
  * onResume 
  * onPause
  * onStop
  * onDestroyView  当fragment 的视图被移除时调用
  * ondestroy
  * onDetach   fragment 与actvity 取消关联

* 回退栈

  > FragmentTransaction.addToBackStack 添加到回退栈

* 与activity的通讯

  * actvity保证 fragment 的引用
  * 通过 getFragemntManger.findramentByTag（id） 获取到fragment对象

  * fragment 中 getActvity 获取对应的实例

#### Service

* 进程的优先级

* service 的启动流程

  * startService   onCreate ->onStartCommand-> onDestroy  多次startService 会多次调用  每次触发onStartCommand 
  * bindService  onCreate-> onBind-> onUnBind -> ondestroy  bind的service 依附它的content  。多次bind 不会触发。
  * 混合，被绑定 和start   onCreate 只会被绑定一次，只有 解除绑定后StopService 才会生效。

* 使用实例

  * 不可交互的后台服务 

    > 普通的service ,startService 打开 。生命周期  onCreate 、onStartCommand、onDestory

  * 可交互的后台服务

    > bindService 开启，生命周期 onCreate 、onBind、onUnBind、onDestroy  bindService  第二参数， serviceConnection 的回调，可以获取service 中 onBind 的返回值，这样可以调用后台服务类的方法，实现交互。

  * 混合型服务  可独立，可绑定的后台服务。

  * 前台服务

    > 在service 上创建 一个notification，然后使用Service 的startForeground 方法 即可启动为前台服务。

* 远程服务的创建过程，服务死掉了，保活机制。

  * step1 在对应的文件目录下创建 aidl 文件
  * step2 创建一个service ，并在内部实现aidl 的接口函数，onBind 返回这个实例。
  * step3 在Android androidManifest 设置该service 对应的属性
  * step4 在client 来bindservice ，并在serviceConnecet 回调参数中 获取onBind 返回的实例，来与remote进行交互
  *  保活，1 两个服务相互监听， 2 在断开服务链接 时 重新绑定， 3 使用死亡代理，service 死掉后，重新绑定。

* intentService的使用

* 为什么要用服务

* 如何保证服务不被杀死

#### 广播

* 特点：1 收到广播，无进程，自动创建 2 应用必须被打开过，广播才被执行。 3 强行停止后，不会自己创建进程，除非用户自己手动打开界面。
* 无序广播与有序广播。
  * 无序 注册可接受，不可中断、修改
  * 有序 按优先一级级传递，可中断、修改

* 动态广播，代码注册
* 静态广播，androidMainfest 注册，，开机，sd卡 。

#### contentProvider

* 管理对结构化的数据集方问。内部，实现了 增删改查四种操作。 onCreate 优先appliaction的创建。 oncreate 为什么在application之前

#### 消息机制

#### 事件分发

#### binder

#### 线程与进程



### 三、kotlin 

* mvvm 的了解

  * mvvm 是mvc 的改进版。
* mvc ，m 是数据层  v 视图层，c 是控制层  数据 与视图交互控制，随着业务的复杂化，视图交互越来越复杂，会导致Controller 越来越臃肿，修改bug，或者梳理业务逻辑 就比较麻烦。
  
  * view 层 视图展示层，包含 ui,UIViewController ，View 层是可以持有VIewModel的
* ViewModel 层，视图适配器，暴露属性 与View 元素显示内容或者元素状态一一对应，ViewModel层是可以持有Model的。
  
  * model层： 数据模型层， 网络请求，或者数据操作 封装成model，对外提供操作接口。
* DataBinding： View和ViewModel之间做双向数据绑定，如果没有双向绑定那么 mvc的差异就不是很大。
  
* mvvm中如何做双向绑定

  ​	

  * 1、在`androidManifext.xml`文件中设置  `dataBinding {enabled = true}`

  * 2、建立一个java bean，是model层。例如一个简单的UserInfo类,属性用`ObservableFiled`修饰

  * 3、建立一个LoginViewModel类，是VM层，构造方法 实例化 UserInfo类赋值给成员变量，并与相关的xml文件进行绑定。

  * 4、最外层需要用<layout 嵌套起来。并配置 data ->variable信息；

    ~~~ xml
    <data>
            <variable
                name="user"
       type="com.xm.mvvmdemo.Model.LoginViewModel"/>
        </data>
    ~~~

    与对应的LoginViewModel绑定。

    然后在andriod的组件中，定义对应的属性,例如 EditText中的 text = LoginViewModel.User.name，

    比如addTextChangedListener 设置成 LoginViewModel.User.nameInputListener；

  * 5、在actvity的onCreate中，将setContentView 去掉，改成  `ActivityMvvmLoginBinding binding = DataBindingUtil.setContentView(this, R.layout.activity_mvvm_login);`  实例化VM 并将 上面的对象传递给VM

  * 5、这样当EditText 里面的数值发生改变，MV能监听到，从而改变model的值。

  * 当我们在LoginViewModel,修改userInfo的值的时候，View也会发送相应的改变。

* databinding的绑定原理

  * apt预编译方式-按照databinding的标准 写xml文件后，在build的时候会动态生成一个class文件，并将我们的布局拆分成两个xml文件，一个是android os进行渲染 一个是交给databind 处理，这样做是为了快速获取xml文件所有的控件信息。
  * databinding的文件，首先是有个绝对路径，然后就是Android 布局控件对应的标签，这样做是为了快速找到布局组件进行显示。
  * 生成的class 文件，会对xml中的控件做监听，View发生改变会给model重新赋值，相应的，model赋值时，发送通知会通知view重新赋值。

* 


### 四、Android apk 相关问题

* android 版本差异

  * 4.4

    > 1. 支持全屏模式，也就是常说的沉浸式 
    >
    >    		 2. 虚拟按键可隐藏
    >       		 3. 为了加强webView 的功能，google 引入了chromiun内核。

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
    >   解决方案，
    >
    > ```xml
    > <?xml version="1.0" encoding="utf-8"?>
    >   <network-security-config>
    >   <base-config cleartextTrafficPermitted="true" />
    > </network-security-config>
    > ```
    >
    > 在manifest清单文件application节点配置`android:networkSecurityConfig="@xml/network_security_config"`

  * 10

    > 1 TelephonyManger getDeviedID 需要申请权限。

  * 

* 多渠道打包

* apk 打包过程

  > 1. 打包资源文件，生成R.java文件  androidManifest.xmlres的资源变成二进制文件，
  > 2. 处理aidl文件，生成相应的java文件
  > 3. 编译项目源代码，生产class文件
  > 4. 转换所有的class文件，生成classe.dex文件
  > 5. 打包生产apk文件，assets的资源没有编译
  > 6. 对apk文件进行签名
  > 7. 对签名后的apk文件进行对齐处理，将apk包中所有资源文件距离文件起始偏移为4字节整数倍，这样通过内存映射方问apk文件时的速度会更快。对齐的作用就是减少运行时内存的使用
  >
  > 

* v1 v2 v3 签名的区别

  >v1 方案：基于 JAR 签名。 - v2 方案：APK 签名方案 v2，在 Android 7.0 引入。 - v3 方案：APK 签名方案v3，在 Android 9.0 引入。
  >
  >其中，v1 到 v2 是颠覆性的，主要是为了解决 JAR 签名方案的安全性问题，而到了 v3 方案，其实结构上并没有太大的调整，可以理解为 v2 签名方案的升级版。
  >
  >

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



## 五、框架相关

## ok源码分析

### 一、OSI 七层模型介绍

* 七层模式

  * 应用层 -> 可见的终端应用

    > 应用终端，例如浏览器

  * 表示层 -> 计算机识别的信息转变人可以的信息

    > 将数据转成人能看懂的信息，例如 视频，图片，文字

  * 会话层 -> 传输端口和接受端口建立会话

    > 一个设备与另外一个设备建立链接

  * 传输层 -> 传输数据的协议与端口

  * 网络层 -> IP地址

  * 数据链路层 -> 交换机传输

  * 物理层 -> 具体物理设备

* TCP/IP参考模型

  * 应用层

    > http,https

  * 传输层

    > upd/tcp

  * 网络层

  * 主机至网络层

* http 1.0/1.1

  * 1.0 请求 响应 断开
  * 1.1 建立长连接，请求 响应 请求 响应  断开

* htt get request 

  * 1 请求头之 请求行
  * 2 请求头之请求属性集

* http post 

  * 1 请求头之 请求行
  * 2 请求头之请求属性集
  * 3 请求体长度
  * 4 请求的类型

### 二、OKHttp 主线程的源码阅读

* 相关类

  * okHttpClient
  * Request
  * Response
  * Call
  * Callback

* 主流程 

  * 1 创建 okHttpClient 对象

    ~~~java
     OkHttpClient okHttpClient = new OkHttpClient.Builder().build();
    ~~~

    * builder 的构造方法

      ~~~java
      dispatcher = new Dispatcher();
            protocols = DEFAULT_PROTOCOLS;
            connectionSpecs = DEFAULT_CONNECTION_SPECS;
            eventListenerFactory = EventListener.factory(EventListener.NONE);
            proxySelector = ProxySelector.getDefault();
            cookieJar = CookieJar.NO_COOKIES;
            socketFactory = SocketFactory.getDefault();
            hostnameVerifier = OkHostnameVerifier.INSTANCE;
            certificatePinner = CertificatePinner.DEFAULT;
            proxyAuthenticator = Authenticator.NONE;
            authenticator = Authenticator.NONE;
            connectionPool = new ConnectionPool();
            dns = Dns.SYSTEM;
            followSslRedirects = true;
            followRedirects = true;
            retryOnConnectionFailure = true;
            connectTimeout = 10_000;
            readTimeout = 10_000;
            writeTimeout = 10_000;
            pingInterval = 0;
      ~~~

      * 可在build 之前设置参数。

  

  * 2 创建 requset类，通过httpClient .newCall（），获取Call 类(RealCall)

  * 3 发起网络请求

    * 同步网络请求

      * 源码

      ~~~java
      @Override public Response execute() throws IOException {
        synchronized (this) {
          if (executed) throw new IllegalStateException("Already Executed");  // (1)
          executed = true;
        }
        try {
          client.dispatcher().executed(this);                                 // (2)
          Response result = getResponseWithInterceptorChain();                // (3)
          if (result == null) throw new IOException("Canceled");
          return result;
        } finally {
          client.dispatcher().finished(this);                                 // (4)
        }
      }
      ~~~

      * 这里做了4件事

        > 1.检查这个call 释放已经执行了，每个call 只能被执行一次，如果想要一个完全一样的call，可以利用call#clone方法进行克隆
        >
        > 2.利用client.dispatcher().executed(this) 来进行实际执行dispatcher
        >
        > 3.调用getResponseWithInterceptorChain()函数获取HTTP返回结果，从函数可以看出，这一步还会进行一系列拦截操作。
        >
        > 4.最后还要通知dispatcher 自己已经执行完毕。

      * 真正做网络请求的是  `getResponseWithInterceptorChain()` 这个方法。`Interceptor` 是OkHttp 最核心的一个东西，它不是只负责拦截请求进行一些额外的处理，实际上它把实际的网络请求、缓存、透明压缩等功能都统一了起来，每一个功能都是一个`Interceptor` ,它们再连接成一个`Interceptor.Chain`  ,环环相扣，最终圆满完成一个网络请求。

      * `Interceptor.Chain` 的分布依次是:

        1.在配置`OkHttpClient` 时设置的 `interceptors`

        > log日志拦截，自定义的拦截器，添加公告参数参数。

           2.负责失败重试以及重定向的`RetryAndFollowUpInterceptor` 

        3. 负责把用户构造的请求转换为发送服务器的请求、把服务器返回的响应转换为用户友好的响应的`BridgeInterceptor`;
        4. 负责读取缓存直接返回、更新缓存的`CacheInterceptor`;
        5. 负责和服务器建立连接的`connetInterceptor`
        6. 配置`OkHttpClient` 时设置的`networkInterceptors`;
        7. 负责向服务器发送请求数据、从服务器读取响应数据`CallServerInterceptor`;

      * 位置决定了功能，最后一个`Interceptor` 一定负责和服务器实际通讯的，重定向、缓存等一定时实际通讯之前的。

      * 责任链模式在这个`Interceptor` 链条中得到了很好的实践

        > 它包含了一些命令对象和一系列的处理对象，每个处理对象决定它额能处理哪些命令对象，它也知道如何将它不能处理的命令对象传递过改链中的下一个处理对象。该模式还描述了该处理链的末尾添加新的处理对象的方法。

      * 对于把`Request` 变成 `Response` 这件事来说，每个`Interceptor` 都可能完成这件事，所以我们循着链条让每个 `Interceptor` 自行决定能否完成任务以及怎么完成任务。这样一来，完成网络请求这件事就彻底从`RealCall` 类中剥离出来，简化了各自的责任和逻辑。

      * 建立连接:`ConnectInterceptor`

        ~~~java
        @Override public Response intercept(Chain chain) throws IOException {
          RealInterceptorChain realChain = (RealInterceptorChain) chain;
          Request request = realChain.request();
          StreamAllocation streamAllocation = realChain.streamAllocation();
        
          // We need the network to satisfy this request. Possibly for validating a conditional GET.
          boolean doExtensiveHealthChecks = !request.method().equals("GET");
          HttpCodec httpCodec = streamAllocation.newStream(client, doExtensiveHealthChecks);
          RealConnection connection = streamAllocation.connection();
        
          return realChain.proceed(request, streamAllocation, httpCodec, connection);
        }
        ~~~

        实际是创建了一个`HttpCodec`对象 ，它里面是用`OKio` 对`Socket` 的读写操作进行封装。

      * 发送和接受数据:`CallServerInterceptor`

        ~~~java
        @Override public Response intercept(Chain chain) throws IOException {
          HttpCodec httpCodec = ((RealInterceptorChain) chain).httpStream();
          StreamAllocation streamAllocation = ((RealInterceptorChain) chain).streamAllocation();
          Request request = chain.request();
        
          long sentRequestMillis = System.currentTimeMillis();
          httpCodec.writeRequestHeaders(request);
        
          if (HttpMethod.permitsRequestBody(request.method()) && request.body() != null) {
            Sink requestBodyOut = httpCodec.createRequestBody(request, request.body().contentLength());
            BufferedSink bufferedRequestBody = Okio.buffer(requestBodyOut);
            request.body().writeTo(bufferedRequestBody);
            bufferedRequestBody.close();
          }
        
          httpCodec.finishRequest();
        
          Response response = httpCodec.readResponseHeaders()
              .request(request)
              .handshake(streamAllocation.connection().handshake())
              .sentRequestAtMillis(sentRequestMillis)
              .receivedResponseAtMillis(System.currentTimeMillis())
              .build();
        
          if (!forWebSocket || response.code() != 101) {
            response = response.newBuilder()
                .body(httpCodec.openResponseBody(response))
                .build();
          }
        
          if ("close".equalsIgnoreCase(response.request().header("Connection"))
              || "close".equalsIgnoreCase(response.header("Connection"))) {
            streamAllocation.noNewStreams();
          }
          // 省略部分检查代码
        
          return response;
        }
        ~~~

        > 主干部分是:
        >
        > 1.向服务器发送request header
        >
        > 2.如果有request body,就向服务器发送；
        >
        > 3.读取response header,先构造一个Response 对象
        >
        > 4.如果有 response body，就在上面的基础加上body构造一个新的response 对象

    * 异步网络请求

      >
      >
  
* ### 返回数据的获取
  
* ### HTTP 缓存
  
* 总结
  

​	okHttp是一个网络请求框架，它封装好了对网络请求的操作,优点有：支持允许所有访问同一主机的请求共享一个socket,利用连接池减少请求延迟，支持GZIP压缩，响应缓存减少重复请求。首先，通过`OkHttpClient.Builder()`这个类 采用构建者模式,配置并初始化好对应的数据，获取`OkHttpClient` 对象；接着通过`Request.Builder()`设置网络参数相关参数，如何请求模式，网络地址，请求参数，得到`Request` 对象，调用`OkHttpClient` 的`newCall`方法得到Call对象，它是一个接口 RealCall实现了这个接口。有两种调用网络请求的方式，同步请求与异步请求，异步是比同步多开一个线程，最后都是调用 `RealCall`的 `getResponseWithInterceptorChain`方法。这个是真正的开始做网络请求，它采用拦截器的方式，应该说是采用责任链的方式，把实际的网络请求、缓存、透明压缩等共功能都统一起来，每一个功能都只是一个`interceptor`,他们再连接成一个`Interceptor.Chain` 环环相扣，最终圆满完成一次网络请求，我们在每个`Interceptor`自行决定是否完成任务，或者交给下一个`Interceptor`去完成任务，这样网络请求的逻辑由链条控制，与外界隔离(与事件分发机制很像)。`Interceptor`的执行是有顺序的，优先执行的是由`OkHttpClient`设置的`interceptors`，也就是我们自定义设置的`interceptors`,例如日志拦截器，或者添加参数的拦截器。第二个是负责失败重试以及重定向的`RetryAndFollowUpInteptor`,第三个是负责把用户构造的请求转换为发送到服务器的请求、把服务器返回的响应转换为用户友好的响应`BrideInterceptor`;第四个是负责读取缓存直接返回、更新缓存的`CacheInterceptor`;第五个是负责和服务器建立连接的`ConnectInterceptor`;第六个是 配置`OkHttpClient`时的`networkInterceptors`;第七个时 负责向服务器发送请求数据、从服务器读取响应数据的`CallServerInterceptor`。总结下就是，先执行用户设置在`okhttpclient`里面的拦截器，接着执行负责重试的 `RetryAndFollowUpInterceptor` 里面是一个while 循环，直到获取到正确的`Response`对象，或者抛出异常，才结束这个循环。接着是`BridgeInterceptor` 设置请求头、请求属性集和请求体。然后是`CacheInterceptor` 先从cache 类里面获取 数据，判断是否需要请求网络，如果不需要请求网络，直接将数据返回，如果需要;接下来就是 负责和服务器建立连接的 `connectInterceptor`,它实际是创建了一个 `httpCodec`对象，调用`RealConnection` 进行连接，并交由接下来的步骤去使用，`httpCodec` 它是利用`Okio`对`socket`的读写操作进行封装。接着是 配置`okhttpClient`设置的`networkInterceptor` 由我们设置的，例如拿到服务端数据做一些额外的操作，最后是负责向服务器发送数据、从服务器读取响应数据的 `CallServerInterceptor`,主要是4步 1 向服务端发送 request header,如果有request body,就向服务端发送，读取 response header ，先构造一个 presponse 对象，如果有 reponse body,就在上面的基础上 加上 body 构造一个新的 response对象，得到response 依次沿上面得调用顺序返回，最终将response 返回给 RealCall调用的地方。




## Glide 源码分析

简单来说，glide 框架分为4个部分，1、内存缓存,图片加载数据时依次从 活动缓存，内存缓存，磁盘缓存，中获取数据 2、外部资源加载，当内存缓存中，
无法获取到数据时，会去外部加载资源，网络数据跟本地数据。 3、bitmap复用池，当一个bitmap 被回收后，bitmap的资源会被释放，但占用的内存会存放在
内存中，当磁盘缓存需要创建内存时，会优先在复用池中获取数据。4、生命周期的管理,application的context 是无法做管理的，但是activity的context 是可以的，创建一个fragment 添加到activity中，
fragment的生命跟activity的生命周期进行绑定了。添加监听，会glide的内存进行相应的处理。
具体流程，就是Glide.with 传入context，通过GlideBuild创建glide对象，和资源请求的管理类也就是(RequestManger),requestManger类，在静态代码库创建了具体的资源加载类
并与context的生命周期进行监听,最后将requestManger的对象返回给外部，接着调用load()传入具体的图片加载地址，将地址传递给里面，
init()的时候，开始从内存加载数据，如果没有会去加载外部资源，加载完成后，将图片显示出来。



## **Retrofit** 解析





# 六、Android Framwork层

## 1、binder

binder 是一种andriod的一种进程通信机制，android的大四组件之前的通讯，系统对应用层的服务：AMS、PMS都是基于 Binder IPC 机制来实现的。操作系统，进程与进程内存是不共享的，进程空间一般是划分为用户空间 跟 内核空间，内核空间是系统的内存空间，用户空间是一般是指软件的内存空间，用户空间对内核空间的访问，需要借助系统调用来实现，主要是通过 copy_form_user和copy_to_user(),这两个函数来实现，一个是将数据从用户空间拷贝到内核空间，另外一个是将数据从内核空间拷贝到用户空间。传统的进程通讯有管道、消息队列、内存共享、socket等，android采用的进程通讯是binder ipc，binder ipc 是基于c/s架构，稳定性好，采用内存映射的方式进行数据拷贝，效率比其他进程通信效率要高，binder为每个app分配uid，保证了其安全性。
	binder ipc 跨进程通信原理，android 系统通过动态加载binder内核模块运行在内核空间，采用内存映射的方式 将用户空间的一块内存区域映射到内核空间，当映射关系建立，用户对这块内存区域的修改可以直接反应到内核空间，反之内核空间对这段区域的修改也能反应到用户空间，那么一次binder ipc 通信过程 通常是这个样子：1 首先binder 驱动在内核空间创建一个数据接受缓存区；2 接着在内核空间开辟一块内核缓存区，建立内核缓存区和内核中数据接受缓冲区之间的映射关系，以及内核中数据接受区和接受进程用户空间地址的映射关系 3 发送方进程通过系统调用 copy_from_user()将数据copy到内核缓冲区，由于内核缓冲区和接受进程的用户空间存在内存映射，因此也就相当于把数据发送到了接受进程的用户空间，这样便完成一次进程间的通信。 
	在说下android中binder 通信模型，4个部分组成,client、service、serviceManger和binder驱动，其中client、service、serviceManager运行在用户空间，binder驱动在内核空间，serviceManager和binder由系统提供，client和service由应用程序实现。client、service和serviceManger均是通过系统调用open、内存映射和文件读写方法来访问设备文件/dev/binder,从而实现binder驱动的交互来间接的实现跨进程通信。通信过程，首先一个进程使用 BINDER_SET_COUNTEXT_MGR命令通过binder驱动将之间注册成为ServiceManager;然后service通过驱动向serviceManager中注册Binder(Service中的binder 实体)，表明可以对外提供服务。驱动为这个binder创建位于内核中的实体节点以及serviceManager对实体的引用，将名字以及新建的引用打包传给ServiceManger,serviceManger将其填入查找表，client通过名字，在binder驱动的帮助下从ServiceManager中获取到对binder实体的引用，通过这个引用就额能实现和service进程的通信，binder中的通信代理模式，a进程后去b进程的object时，驱动会返回一个跟object一样的代理对象，具有跟object一样的方法，当binder驱动接受到a进程的消息后，发现这个代理对象(objectProxy)就是去查询自己维护的表单，一查发现这个是b进程object的代理对象。于是就会通知b进程调用object方法，并要求b进程把返回的结果发给自己，当驱动拿到b进程的返回结果后，就转发给a进程，这样一次通信就完成。
	binder ipc 在Android中的具体实现，4个类，IBinder 只要实现了这个接口，那么这个类就具备了跨进程的能力  IInterface 就是service具备什么样的能力  Binder binder的本地类，代理类  Stub binder 的本地对象，service端给client的代理。例如一个 图书管理系统，BookManagerService,创建服务，在onBinder 返回 一个Stub类的对象，Stub继承binder，实现BookManager,BookManager 继承于IInterface,我们通过客户端与服务进行绑定，在绑定服务的回调中，会得到IBinder的对象，通过asInterface方法得Stub得代理对象，通过代理对象与binder驱动中的binder与服务端进行通信。



* 2、Acivity的启动流程

  1、Acivity A调用startActiviy(),最终会调用AMSProxy代理类，通过binder的机制调用AMS的startAcivity();
  2、AMS startAcivity，会先从PMS获取对应activity的相关信息，比如pid，uid，然后检查启动模式，根据启动模式创建对应的activity任务栈，再判断是否是有效的activity，接着通过binder机制给AMSProxy发送一个暂停的通知。
  3、AMSProxy收到暂停通过后，会发送用户离开事件通知，中止事件通知，会调用A的onPause方法，等待数据数据写入操作，接着通过binder机制通知AMS暂停完成。
  4、AMS收到暂停通知后，通过进程名称从进程集合中获取ProcessRecord对象，判断是是否为空，不为空的话会调用realStartActivity()方法去真正的启动activity，如果为空，则会通过sokect的方式通知zygote进程去创建一个进程。
  5、新进程中指定ActvityThread main方法为程序的入口，这里面做了三件事，一、创建ActvityThread对象，二、调用loop的静态方法prepareMainLooper和loop方法，创建一个消息循环。三、向AMS发送一个启动完成的通知，并将ApplicationThread对象传递过去。
  6、AMS收到进程创建成功的通知，显示检查栈顶的ActivityRecod是否一致，然后对ActivityRecode的参数进行设置,并将applicationThrad 进行application绑定，会调用applicaiton的onCreate方法,例如将applicationThread的引用给PreocessRecode，并删除之前的handler超时消息，接着调用actvityStack的realStartActvity方法。
  7、realStartActiivty 其实是通过binder机制调用新进程中ApplicationThread 的 scheduleLaunchActivity()这个方法，最终会调用performlaucheActvity() 这里面做了6件事，1是获取loadAPk对象，2 创建actvity对象 3 创建applicaiton对象 4 创建ContextImpl对象 5 将application/contextImpl 对象都attach到activity对象中 6 执行回调 onCreate()这个时候activity被创建了。

  

* 3、Service的启动流程

  1456、与activity的启动一致
  从第6步开始 不一样，因为不是启动activity ,则会调用 ActiveServices 里面的 realStartServiceLocked() 接着会applicationThread 里面的 scheduleCreateService(),通过binder的机制 就回到了新的进程里面，当ApplicationThread 收到创建service 的消息，发送创建service的hanlder消息，在handleCreateService完成service的创建工作，1 先获取loadedApk 2创建service对象 3 创建 ContextImpl 4 创建application对象 5 将application/contextImpl都attach到service对象中 6 执行service 的onCreate 方法

  

* 

  

  

  

  

  



















