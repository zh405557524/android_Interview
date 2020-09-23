# 一、进程通信，binder、aidl

## 1、binder

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


binder 是一种andriod的一种进程通信机制，android的大四组件之前的通讯，系统对应用层的服务：AMS、PMS都是基于 Binder IPC 机制来实现的。操作系统，进程与进程内存是不共享的，进程空间一般是划分为用户空间 跟 内核空间，内核空间是系统的内存空间，用户空间是一般是指软件的内存空间，用户空间对内核空间的访问，需要借助系统调用来实现，主要是通过 copy_form_user和copy_to_user(),这两个函数来实现，一个是将数据从用户空间拷贝到内核空间，另外一个是将数据从内核空间拷贝到用户空间。传统的进程通讯有管道、消息队列、内存共享、socket等，android采用的进程通讯是binder ipc，binder ipc 是基于c/s架构，稳定性好，采用内存映射的方式进行数据拷贝，效率比其他进程通信效率要高，binder为每个app分配uid，保证了其安全性。
	binder ipc 跨进程通信原理，android 系统通过动态加载binder内核模块运行在内核空间，采用内存映射的方式 将用户空间的一块内存区域映射到内核空间，当映射关系建立，用户对这块内存区域的修改可以直接反应到内核空间，反之内核空间对这段区域的修改也能反应到用户空间，那么一次binder ipc 通信过程 通常是这个样子：1 首先binder 驱动在内核空间创建一个数据接受缓存区；2 接着在内核空间开辟一块内核缓存区，建立内核缓存区和内核中数据接受缓冲区之间的映射关系，以及内核中数据接受区和接受进程用户空间地址的映射关系 3 发送方进程通过系统调用 copy_from_user()将数据copy到内核缓冲区，由于内核缓冲区和接受进程的用户空间存在内存映射，因此也就相当于把数据发送到了接受进程的用户空间，这样便完成一次进程间的通信。 
	在说下android中binder 通信模型，4个部分组成,client、service、serviceManger和binder驱动，其中client、service、serviceManager运行在用户空间，binder驱动在内核空间，serviceManager和binder由系统提供，client和service由应用程序实现。client、service和serviceManger均是通过系统调用open、内存映射和文件读写方法来访问设备文件/dev/binder,从而实现binder驱动的交互来间接的实现跨进程通信。通信过程，首先一个进程使用 BINDER_SET_COUNTEXT_MGR命令通过binder驱动将之间注册成为ServiceManager;然后service通过驱动向serviceManager中注册Binder(Service中的binder 实体)，表明可以对外提供服务。驱动为这个binder创建位于内核中的实体节点以及serviceManager对实体的引用，将名字以及新建的引用打包传给ServiceManger,serviceManger将其填入查找表，client通过名字，在binder驱动的帮助下从ServiceManager中获取到对binder实体的引用，通过这个引用就额能实现和service进程的通信，binder中的通信代理模式，a进程后去b进程的object时，驱动会返回一个跟object一样的代理对象，具有跟object一样的方法，当binder驱动接受到a进程的消息后，发现这个代理对象(objectProxy)就是去查询自己维护的表单，一查发现这个是b进程object的代理对象。于是就会通知b进程调用object方法，并要求b进程把返回的结果发给自己，当驱动拿到b进程的返回结果后，就转发给a进程，这样一次通信就完成。
	binder ipc 在Android中的具体实现，4个类，IBinder 只要实现了这个接口，那么这个类就具备了跨进程的能力  IInterface 就是service具备什么样的能力  Binder binder的本地类，代理类  Stub binder 的本地对象，service端给client的代理。例如一个 图书管理系统，BookManagerService,创建服务，在onBinder 返回 一个Stub类的对象，Stub继承binder，实现BookManager,BookManager 继承于IInterface,我们通过客户端与服务进行绑定，在绑定服务的回调中，会得到IBinder的对象，通过asInterface方法得Stub得代理对象，通过代理对象与binder驱动中的binder与服务端进行通信。

	# 二、系统启动流程
	# 三、四大组件启动流程

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

  


	# 四、window的创建流程
	# 五、键盘的创建流程
	# 六、性能优化

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

  

	# 七、内存优化

内存泄漏处理

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

	# 八、热修复，插件化原理
	# 九、APK编译安装流程

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





#

