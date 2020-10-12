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

* ## init脚本的启动

  > ```
  > +------------+    +-------+   +-----------+
  > |Linux Kernel+--> |init.rc+-> |app_process|
  > +------------+    +-------+   +-----------+
  >                create and public          
  >                  server socket
  > ```
  >
  > linux内核加载完成后，运行init.rc脚本
  >
  > ```
  > service zygote /system/bin/app_process -Xzygote /system/bin --zygote --start-system-server socket zygote stream 666
  > ```
  >
  > - /system/bin/app_process Zygote服务启动的进程名
  > - --start-system-server 表明Zygote启动完成之后，要启动System进程。
  > - socket zygote stream 666 在Zygote启动时，创建一个权限为666的socket。此socket用来请求Zygote创建新进程。socket的fd保存在名称为“ANDROID_SOCKET_zygote”的环境变量中。

* ## Zygote进程的启动过程

  >```
  >            create rumtime                            
  >  +-----------+            +----------+                  
  >  |app_process+----------> |ZygoteInit|                  
  >  +-----------+            +-----+----+                  
  >                                 |                       
  >                                 |                       
  >                                 | registerZygoteSocket()
  >                                 |                       
  >   +------+  startSystemServer() |                       
  >   |System| <-------+            |                       
  >   +------+   fork               | runSelectLoopMode()   
  >                                 |                       
  >                                 v         
  >```
  >
  >**app_process进程**
  >
  >------
  >
  >/system/bin/app_process 启动时创建了一个AppRuntime对象。通过AppRuntime对象的start方法，通过JNI调用创建了一个虚拟机实例，然后运行com.android.internal.os.ZygoteInit类的静态main方法，传递true(boolean startSystemServer)参数。
  >
  >**ZygoteInit类**
  >
  >------
  >
  >ZygoteInit类的main方法运行时，会通过registerZygoteSocket方法创建一个供ActivityManagerService使用的server socket。然后通过调用startSystemServer方法来启动System进程。最后通过runSelectLoopMode来等待AMS的新建进程请求。
  >
  >1. 在registerZygoteSocket方法中，通过名为ANDROID_SOCKET_zygote的环境获取到zygote启动时创建的socket的fd，然后以此来创建server socket。
  >2. 在startSystemServer方法中，通过Zygote.forkSystemServer方法创建了一个子进程，并将其用户和用户组的ID设置为1000。
  >3. 在runSelectLoopMode方法中，会将之前建立的server socket保存起来。然后进入一个无限循环，在其中通过selectReadable方法，监听socket是否有数据可读。有数据则说明接收到了一个请求。 selectReadable方法会返回一个整数值index。如果index为0，则说明这个是AMS发过来的连接请求。这时会与AMS建立一个新的socket连接，并包装成ZygoteConnection对象保存起来。如果index大于0，则说明这是AMS发过来的一个创建新进程的请求。此时会取出之前保存的ZygoteConnection对象，调用其中的runOnce方法创建新进程。调用完成后将connection删除。 这就是Zygote处理一次AMS请求的过程。
  >
  >

* ## System进程的启动

  > ```
  >  +                                                     
  >  |                                                     
  >  |                                                     
  >  v fork()                                              
  >  +--------------+                                      
  >  |System Process|                                      
  >  +------+-------+                                      
  >         |                                              
  >         | RuntimeInit.zygoteInit() commonInit, zygoteInitNative                                             
  >         | init1()  SurfaceFlinger, SensorServic...     
  >         |                                              
  >         |                                              
  >         | init2() +------------+                       
  >         +-------> |ServerThread|                       
  >         |         +----+-------+                       
  >         |              |                               
  >         |              | AMS, PMS, WMS...              
  >         |              |                               
  >         |              |                               
  >         |              |                               
  >         v              v               
  > ```
  >
  > System进程是在ZygoteInit的handleSystemServerProcess中开始启动的。
  >
  > 1. 首先，因为System进程是直接fork Zygote进程的，所以要先通过closeServerSocket方法关掉server socket。
  > 2. 调用RuntimeInit.zygoteInit方法进一步启动System进程。在zygoteInit中，通过commonInit方法设置时区和键盘布局等通用信息，然后通过zygoteInitNative方法启动了一个Binder线程池。最后通过invokeStaticMain方法调用SystemServer类的静态Main方法。
  > 3. SystemServer类的main通过JNI调用cpp实现的init1方法。在init1方法中，会启动各种以C++开发的系统服务（例如SurfaceFlinger和SensorService）。然后回调ServerServer类的init2方法来启动以Java开发的系统服务。
  > 4. 在init2方法中，首先会新建名为"android.server.ServerThread"的ServerThread线程，并调用其start方法。然后在该线程中启动各种Service（例如AMS，PMS，WMS等）。启动的方式是调用对应Service类的静态main方法。
  > 5. 首先，AMS会被创建，但未注册到ServerManager中。然后PMS被创建，AMS这时候才注册到ServerManager中。然后到ContentService、WMS等。 注册到ServerManager中时会制定Service的名字，其后其他进程可以通过这个名字来获取到Binder Proxy对象，以访问Service提供的服务。
  > 6. 执行到这里，System就将系统的关键服务启动起来了，这时候其他进程便可利用这些Service提供的基础服务了。
  > 7. 最后会调用ActivityManagerService的systemReady方法，在该方法里会启动系统界面以及Home程序。
  >
  > \##Android进程启动
  >
  > ------
  >
  > ```
  >    +----------------------+       +-------+      +----------+   +----------------+   +-----------+                         
  >    |ActivityManagerService|       |Process|      |ZygoteInit|   |ZygoteConnection|   |RuntimeInit|                         
  >    +--------------+-------+       +---+---+      +-----+----+   +-----------+----+   +------+----+                         
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >  startProcessLocked()                 |                |                    |               |                              
  > +---------------> |                   |                |                    |               |                              
  >                   |  start()          |                |                    |               |                              
  >                   |  "android.app.ActivityThread"      |                    |               |                              
  >                   +-----------------> |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |openZygoteSocketIfNeeded()           |               |                              
  >                   |                   +------+         |                    |               |                              
  >                   |                   |      |         |                    |               |                              
  >                   |                   | <----+         |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |sZygoteWriter.write(arg)             |               |                              
  >                   |                   +------+         |                    |               |                              
  >                   |                   |      |         |                    |               |                              
  >                   |                   |      |         |                    |               |                              
  >                   |                   | <----+         |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   +--------------> |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |runSelectLoopMode() |               |                              
  >                   |                   |                +-----------------+  |               |                              
  >                   |                   |                |                 |  |               |                              
  >                   |                   |                | <---------------+  |               |                              
  >                   |                   |                |   acceptCommandPeer()              |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |  runOnce()         |               |                              
  >                   |                   |                +------------------> |               |                              
  >                   |                   |                |                    |forkAndSpecialize()                           
  >                   |                   |                |                    +-------------+ |                              
  >                   |                   |                |                    |             | |                              
  >                   |                   |                |                    | <-----------+ |                              
  >                   |                   |                |                    |  handleChildProc()                           
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    | zygoteInit()  |                              
  >                   |                   |                |                    +-------------> |                              
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |in^okeStaticMain()            
  >                   |                   |                |                    |               +---------------->             
  >                   |                   |                |                    |               |("android.app.ActivityThread")
  >                   |                   |                |                    |               |                              
  >                   |                   |                |                    |               |                              
  >                   +                   +                +                    +               +                            
  > ```
  >
  > - AMS向Zygote发起请求（通过之前保存的socket），携带各种参数，包括“android.app.ActivityThread”。
  > - Zygote进程fork自己，然后在新Zygote进程中调用RuntimeInit.zygoteInit方法进行一系列的初始化（commonInit、Binder线程池初始化等）。
  > - 新Zygote进程中调用ActivityThread的main函数，并启动消息循环。

# 三、四大组件启动流程

* 1、Acivity的启动流程

  1、Acivity A调用startActiviy(),最终会调用AMSProxy代理类，通过binder的机制调用AMS的startAcivity();
  2、AMS startAcivity，会先从PMS获取对应activity的相关信息，比如pid，uid，然后检查启动模式，根据启动模式创建对应的activity任务栈，再判断是否是有效的activity，接着通过binder机制给AMSProxy发送一个暂停的通知。
  3、AMSProxy收到暂停通过后，会发送用户离开事件通知，中止事件通知，会调用A的onPause方法，等待数据数据写入操作，接着通过binder机制通知AMS暂停完成。
  4、AMS收到暂停通知后，通过进程名称从进程集合中获取ProcessRecord对象，判断是是否为空，不为空的话会调用realStartActivity()方法去真正的启动activity，如果为空，则会通过sokect的方式通知zygote进程去创建一个进程。
  5、新进程中指定ActvityThread main方法为程序的入口，这里面做了三件事，一、创建ActvityThread对象，二、调用loop的静态方法prepareMainLooper和loop方法，创建一个消息循环。三、向AMS发送一个启动完成的通知，并将ApplicationThread对象传递过去。
  6、AMS收到进程创建成功的通知，显示检查栈顶的ActivityRecod是否一致，然后对ActivityRecode的参数进行设置,并将applicationThrad 进行application绑定，会调用applicaiton的onCreate方法,例如将applicationThread的引用给PreocessRecode，并删除之前的handler超时消息，接着调用actvityStack的realStartActvity方法。
  7、realStartActiivty 其实是通过binder机制调用新进程中ApplicationThread 的 scheduleLaunchActivity()这个方法，最终会调用performlaucheActvity() 这里面做了6件事，1是获取loadAPk对象，2 创建actvity对象 3 创建applicaiton对象 4 创建ContextImpl对象 5 将application/contextImpl 对象都attach到activity对象中 6 执行回调 onCreate()这个时候activity被创建了。

  

* 2、Service的启动流程

  1456、与activity的启动一致
  从第6步开始 不一样，因为不是启动activity ,则会调用 ActiveServices 里面的 realStartServiceLocked() 接着会applicationThread 里面的 scheduleCreateService(),通过binder的机制 就回到了新的进程里面，当ApplicationThread 收到创建service 的消息，发送创建service的hanlder消息，在handleCreateService完成service的创建工作，1 先获取loadedApk 2创建service对象 3 创建 ContextImpl 4 创建application对象 5 将application/contextImpl都attach到service对象中 6 执行service 的onCreate 方法

* 

# 四、window的创建流程

* ## Window 概念与分类

  > Window 是一个抽象类，它的具体实现是 PhoneWindow。WindowManager 是外界访问 Window 的入口，Window 的具体实现位于 WindowManagerService 中，WindowManager 和 WindowManagerService 的交互是一个 IPC 过程。Android 中所有的视图都是通过 Window 来呈现，因此 Window 实际是 View 的直接管理者。
  >
  > | Window 类型        | 说明                                               | 层级      |
  > | ------------------ | -------------------------------------------------- | --------- |
  > | Application Window | 对应着一个 Activity                                | 1~99      |
  > | Sub Window         | 不能单独存在，只能附属在父 Window 中，如 Dialog 等 | 1000~1999 |
  > | System Window      | 需要权限声明，如 Toast 和 系统状态栏等             |           |

* ## Window 的内部机制

  > Window 是一个抽象的概念，每一个 Window 对应着一个 View 和一个 ViewRootImpl。Window 实际是不存在的，它是以 View 的形式存在。对 Window 的访问必须通过 WindowManager，WindowManager 的实现类是 WindowManagerImpl：
  >
  > ```
  > WindowManagerImpl.java
  > @Override
  > public void addView(@NonNull View view, @NonNull ViewGroup.LayoutParams params) {
  >     applyDefaultToken(params);
  >     mGlobal.addView(view, params, mContext.getDisplay(), mParentWindow);
  > }
  > 
  > @Override
  > public void updateViewLayout(@NonNull View view, @NonNull ViewGroup.LayoutParams params) {
  >     applyDefaultToken(params);
  >     mGlobal.updateViewLayout(view, params);
  > }
  > 
  > @Override
  > public void removeView(View view) {
  >     mGlobal.removeView(view, false);
  > }
  > ```
  >
  > WindowManagerImpl 没有直接实现 Window 的三大操作，而是全部交给 WindowManagerGlobal 处理，WindowManagerGlobal 以工厂的形式向外提供自己的实例：
  >
  > ```
  > WindowManagerGlobal.java
  > // 添加
  > public void addView(View view, ViewGroup.LayoutParams params,
  >         Display display, Window parentWindow) {
  >     ···
  >     // 子 Window 的话需要调整一些布局参数
  >     final WindowManager.LayoutParams wparams = (WindowManager.LayoutParams) params;
  >     if (parentWindow != null) {
  >         parentWindow.adjustLayoutParamsForSubWindow(wparams);
  >     } else {
  >         ···
  >     }
  >     ViewRootImpl root;
  >     View panelParentView = null;
  >     synchronized (mLock) {
  >         // 新建一个 ViewRootImpl，并通过其 setView 来更新界面完成 Window 的添加过程
  >         ···
  >         root = new ViewRootImpl(view.getContext(), display);
  >         view.setLayoutParams(wparams);
  >         mViews.add(view);
  >         mRoots.add(root);
  >         mParams.add(wparams);
  >         // do this last because it fires off messages to start doing things
  >         try {
  >             root.setView(view, wparams, panelParentView);
  >         } catch (RuntimeException e) {
  >             // BadTokenException or InvalidDisplayException, clean up.
  >             if (index >= 0) {
  >                 removeViewLocked(index, true);
  >             }
  >             throw e;
  >         }
  >     }
  > }
  > 
  > // 删除
  > @UnsupportedAppUsage
  > public void removeView(View view, boolean immediate) {
  >     ···
  >     synchronized (mLock) {
  >         int index = findViewLocked(view, true);
  >         View curView = mRoots.get(index).getView();
  >         removeViewLocked(index, immediate);
  >         ···
  >     }
  > }
  > 
  > private void removeViewLocked(int index, boolean immediate) {
  >     ViewRootImpl root = mRoots.get(index);
  >     View view = root.getView();
  >     if (view != null) {
  >         InputMethodManager imm = InputMethodManager.getInstance();
  >         if (imm != null) {
  >             imm.windowDismissed(mViews.get(index).getWindowToken());
  >         }
  >     }
  >     boolean deferred = root.die(immediate);
  >     if (view != null) {
  >         view.assignParent(null);
  >         if (deferred) {
  >             mDyingViews.add(view);
  >         }
  >     }
  > }
  > 
  > // 更新
  > public void updateViewLayout(View view, ViewGroup.LayoutParams params) {
  >     ···
  >     final WindowManager.LayoutParams wparams = (WindowManager.LayoutParams)params;
  >     view.setLayoutParams(wparams);
  >     synchronized (mLock) {
  >         int index = findViewLocked(view, true);
  >         ViewRootImpl root = mRoots.get(index);
  >         mParams.remove(index);
  >         mParams.add(index, wparams);
  >         root.setLayoutParams(wparams, false);
  >     }
  > }
  > ```
  >
  > 在 ViewRootImpl 中最终会通过 WindowSession 来完成 Window 的添加、更新、删除工作，mWindowSession 的类型是 IWindowSession，是一个 Binder 对象，真正地实现类是 Session，是一个 IPC 过程。

* ## Window 的创建过程

  > ### Activity 的 Window 创建过程
  >
  > 在 Activity 的创建过程中，最终会由 ActivityThread 的 performLaunchActivity() 来完成整个启动过程，该方法内部会通过类加载器创建 Activity 的实例对象，并调用 attach 方法关联一系列上下文环境变量。在 Activity 的 attach 方法里，系统会创建所属的 Window 对象并设置回调接口，然后在 Activity 的 setContentView 方法中将视图附属在 Window 上：
  >
  > ```
  > Activity.java
  > final void attach(Context context, ActivityThread aThread,
  >         Instrumentation instr, IBinder token, int ident,
  >         Application application, Intent intent, ActivityInfo info,
  >         CharSequence title, Activity parent, String id,
  >         NonConfigurationInstances lastNonConfigurationInstances,
  >         Configuration config, String referrer, IVoiceInteractor voiceInteractor,
  >         Window window, ActivityConfigCallback activityConfigCallback) {
  >     attachBaseContext(context);
  > 
  >     mFragments.attachHost(null /*parent*/);
  > 
  >     mWindow = new PhoneWindow(this, window, activityConfigCallback);
  >     mWindow.setWindowControllerCallback(this);
  >     mWindow.setCallback(this);
  >     mWindow.setOnWindowDismissedCallback(this);
  >     mWindow.getLayoutInflater().setPrivateFactory(this);
  >     if (info.softInputMode != WindowManager.LayoutParams.SOFT_INPUT_STATE_UNSPECIFIED) {
  >         mWindow.setSoftInputMode(info.softInputMode);
  >     }
  >     if (info.uiOptions != 0) {
  >         mWindow.setUiOptions(info.uiOptions);
  >     }
  >     ···
  > }
  > ···
  > 
  > public void setContentView(@LayoutRes int layoutResID) {
  >     getWindow().setContentView(layoutResID);
  >     initWindowDecorActionBar();
  > }
  > PhoneWindow.java
  > @Override
  > public void setContentView(int layoutResID) {
  >     if (mContentParent == null) { // 如果没有 DecorView，就创建
  >         installDecor();
  >     } else {
  >         mContentParent.removeAllViews();
  >     }
  >     mLayoutInflater.inflate(layoutResID, mContentParent);
  >     final Callback cb = getCallback();
  >     if (cb != null && !isDestroyed()) {
  >         // 回调 Activity 的 onContentChanged 方法通知 Activity 视图已经发生改变
  >         cb.onContentChanged();
  >     }
  > }
  > ```
  >
  > 这个时候 DecorView 还没有被 WindowManager 正式添加。在 ActivityThread 的 handleResumeActivity 方法中，首先会调用 Activity 的 onResume 方法，接着调用 Activity 的 makeVisible()，完成 DecorView 的添加和显示过程：
  >
  > ```
  > Activity.java
  > void makeVisible() {
  >     if (!mWindowAdded) {
  >         ViewManager wm = getWindowManager();
  >         wm.addView(mDecor, getWindow().getAttributes());
  >         mWindowAdded = true;
  >     }
  >     mDecor.setVisibility(View.VISIBLE);
  > }
  > ```
  >
  > ### Dialog 的 Window 创建过程
  >
  > Dialog 的 Window 的创建过程和 Activity 类似，创建同样是通过 PolicyManager 的 makeNewWindow 方法完成的，创建后的对象实际就是 PhoneWindow。当 Dialog 被关闭时，会通过 WindowManager 来移除 DecorView：mWindowManager.removeViewImmediate(mDecor)。
  >
  > ```
  > Dialog.java
  > Dialog(@NonNull Context context, @StyleRes int themeResId, boolean      createContextThemeWrapper) {
  >     ···
  >     mWindowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
  > 
  >     final Window w = new PhoneWindow(mContext);
  >     mWindow = w;
  >     w.setCallback(this);
  >     w.setOnWindowDismissedCallback(this);
  >     w.setOnWindowSwipeDismissedCallback(() -> {
  >         if (mCancelable) {
  >             cancel();
  >         }
  >     });
  >     w.setWindowManager(mWindowManager, null, null);
  >     w.setGravity(Gravity.CENTER);
  > 
  >     mListenersHandler = new ListenersHandler(this);
  > }
  > ```
  >
  > 普通 Dialog 必须采用 Activity 的 Context，采用 Application 的 Context 就会报错，是因为应用 token 所导致，应用 token 一般只有 Activity 拥有。系统 Window 比较特殊，不需要 token。
  >
  > ### Toast 的 Window 创建过程
  >
  > Toast 属于系统 Window ，由于其具有定时取消功能，所以系统采用了 Handler。Toast 的内部有两类 IPC 过程，第一类是 Toast 访问 NotificationManagerService，第二类是 NotificationManagerService 回调 Toast 里的 TN 接口。
  >
  > Toast 内部的视图由两种方式，一种是系统默认的样式，另一种是 setView 指定一个自定义 View，它们都对应 Toast 的一个内部成员 mNextView。
  >
  > ```
  > Toast.java
  > public void show() {
  >     if (mNextView == null) {
  >         throw new RuntimeException("setView must have been called");
  >     }
  > 
  >     INotificationManager service = getService();
  >     String pkg = mContext.getOpPackageName();
  >     TN tn = mTN;
  >     tn.mNextView = mNextView;
  > 
  >     try {
  >         service.enqueueToast(pkg, tn, mDuration);
  >     } catch (RemoteException e) {
  >         // Empty
  >     }
  > }
  > ···
  > 
  > public void cancel() {
  >     mTN.cancel();
  > }
  > NotificationManagerService.java
  > private void showNextToastLocked() {
  >     ToastRecord record = mToastQueue.get(0);
  >     while (record != null) {
  >         if (DBG) Slog.d(TAG, "Show pkg=" + record.pkg + " callback=" + record.callback);
  >         try {
  >             record.callback.show();
  >             scheduleTimeoutLocked(record, false);
  >             return;
  >         } catch (RemoteException e) {
  >             Slog.w(TAG, "Object died trying to show notification " + record.callback
  >                     + " in package " + record.pkg);
  >             // remove it from the list and let the process die
  >             int index = mToastQueue.indexOf(record);
  >             if (index >= 0) {
  >                 mToastQueue.remove(index);
  >             }
  >             keepProcessAliveLocked(record.pid);
  >             if (mToastQueue.size() > 0) {
  >                 record = mToastQueue.get(0);
  >             } else {
  >                 record = null;
  >             }
  >         }
  >     }
  > }
  > 
  > ···
  > private void scheduleTimeoutLocked(ToastRecord r, boolean immediate)
  > {
  >     Message m = Message.obtain(mHandler, MESSAGE_TIMEOUT, r);
  >     long delay = immediate ? 0 : (r.duration == Toast.LENGTH_LONG ? LONG_DELAY : SHORT_DELAY);
  >     mHandler.removeCallbacksAndMessages(r);
  >     mHandler.sendMessageDelayed(m, delay);
  > }
  > ```



# 五、键盘的创建流程
# 六、性能优化



*  **合理管理内存**

  > * 节制的使用Service 如果应用程序需要使用Service来执行后台任务的话，只有当任务正在执行的时候才应该让Service运行起来。当启动一个Service时，系统会倾向于将这个Service所依赖的进程进行保留，系统可以在LRUcache当中缓存的进程数量也会减少，导致切换程序的时候耗费更多性能。我们可以使用IntentService，当后台任务执行结束后会自动停止，避免了Service的内存泄漏。
  > * 当界面不可见时释放内存 当用户打开了另外一个程序，我们的程序界面已经不可见的时候，我们应当将所有和界面相关的资源进行释放。重写Activity的onTrimMemory()方法，然后在这个方法中监听TRIM_MEMORY_UI_HIDDEN这个级别，一旦触发说明用户离开了程序，此时就可以进行资源释放操作了。
  > * 当内存紧张时释放内存 onTrimMemory()方法还有很多种其他类型的回调，可以在手机内存降低的时候及时通知我们，我们应该根据回调中传入的级别来去决定如何释放应用程序的资源。
  > * 避免在Bitmap上浪费内存 读取一个Bitmap图片的时候，千万不要去加载不需要的分辨率。可以压缩图片等操作。
  > * 是有优化过的数据集合 Android提供了一系列优化过后的数据集合工具类，如SparseArray、SparseBooleanArray、LongSparseArray，使用这些API可以让我们的程序更加高效。HashMap工具类会相对比较低效，因为它需要为每一个键值对都提供一个对象入口，而SparseArray就避免掉了基本数据类型转换成对象数据类型的时间。
  > * 知晓内存的开支情况
  >   - 使用枚举通常会比使用静态常量消耗两倍以上的内存，尽可能不使用枚举
  >   - 任何一个Java类，包括匿名类、内部类，都要占用大概500字节的内存空间
  >   - 任何一个类的实例要消耗12-16字节的内存开支，因此频繁创建实例也是会在一定程序上影响内存的
  >   - 使用HashMap时，即使你只设置了一个基本数据类型的键，比如说int，但是也会按照对象的大小来分配内存，大概是32字节，而不是4字节，因此最好使用优化后的数据集合
  > * 谨慎使用抽象编程 在Android使用抽象编程会带来额外的内存开支，因为抽象的编程方法需要编写额外的代码，虽然这些代码根本执行不到，但是也要映射到内存中，不仅占用了更多的内存，在执行效率上也会有所降低。所以需要合理的使用抽象编程。
  > * 尽量避免使用依赖注入框架 使用依赖注入框架貌似看上去把findViewById()这一类的繁琐操作去掉了，但是这些框架为了要搜寻代码中的注解，通常都需要经历较长的初始化过程，并且将一些你用不到的对象也一并加载到内存中。这些用不到的对象会一直站用着内存空间，可能很久之后才会得到释放，所以可能多敲几行代码是更好的选择。
  > * 使用多个进程 谨慎使用，多数应用程序不该在多个进程中运行的，一旦使用不当，它甚至会增加额外的内存而不是帮我们节省内存。这个技巧比较适用于哪些需要在后台去完成一项独立的任务，和前台是完全可以区分开的场景。比如音乐播放，关闭软件，已经完全由Service来控制音乐播放了，系统仍然会将许多UI方面的内存进行保留。在这种场景下就非常适合使用两个进程，一个用于UI展示，另一个用于在后台持续的播放音乐。关于实现多进程，只需要在Manifast文件的应用程序组件声明一个android:process属性就可以了。进程名可以自定义，但是之前要加个冒号，表示该进程是一个当前应用程序的私有进程。

* **分析内存的使用情况**

  > 系统不可能将所有的内存都分配给我们的应用程序，每个程序都会有可使用的内存上限，被称为堆大小。不同的手机堆大小不同，如下代码可以获得堆大小：
  >
  > ```
  > ActivityManager manager = (ActivityManager)getSystemService(Context.ACTIVITY_SERVICE);
  > int heapSize = manager.getMemoryClass();
  > ```
  >
  > 结果以MB为单位进行返回，我们开发时应用程序的内存不能超过这个限制，否则会出现OOM。

  * Android的GC操作 Android系统会在适当的时机触发GC操作，一旦进行GC操作，就会将一些不再使用的对象进行回收。GC操作会从一个叫做Roots的对象开始检查，所有它可以访问到的对象就说明还在使用当中，应该进行保留，而其他的对系那个就表示已经不再被使用了。
  * Android中内存泄漏 Android中的垃圾回收机制并不能防止内存泄漏的出现导致内存泄漏最主要的原因就是某些长存对象持有了一些其它应该被回收的对象的引用，导致垃圾回收器无法去回收掉这些对象，也就是出现内存泄漏了。比如说像Activity这样的系统组件，它又会包含很多的控件甚至是图片，如果它无法被垃圾回收器回收掉的话，那就算是比较严重的内存泄漏情况了。 举个例子，在MainActivity中定义一个内部类，实例化内部类对象，在内部类新建一个线程执行死循环，会导致内部类资源无法释放，MainActivity的控件和资源无法释放，导致OOM,可借助一系列工具，比如LeakCanary。

* **高性能编码优化**

  > 都是一些微优化，在性能方面看不出有什么显著的提升的。使用合适的算法和数据结构是优化程序性能的最主要手段。

  * 避免创建不必要的对象 不必要的对象我们应该避免创建：

    > - 如果有需要拼接的字符串，那么可以优先考虑使用StringBuffer或者StringBuilder来进行拼接，而不是加号连接符，因为使用加号连接符会创建多余的对象，拼接的字符串越长，加号连接符的性能越低。
    >
    > - 在没有特殊原因的情况下，尽量使用基本数据类型来代替封装数据类型，int比Integer要更加有效，其它数据类型也是一样。
    >
    > - 当一个方法的返回值是String的时候，通常需要去判断一下这个String的作用是什么，如果明确知道调用方会将返回的String再进行拼接操作的话，可以考虑返回一个StringBuffer对象来代替，因为这样可以将一个对象的引用进行返回，而返回String的话就是创建了一个短生命周期的临时对象。
    >
    > - 基本数据类型的数组也要优于对象数据类型的数组。另外两个平行的数组要比一个封装好的对象数组更加高效，举个例子，Foo[]和Bar[]这样的数组，使用起来要比Custom(Foo,Bar)[]这样的一个数组高效的多。
    >
    >   尽可能地少创建临时对象，越少的对象意味着越少的GC操作。

  * 静态优于抽象 如果你并不需要访问一个对系那个中的某些字段，只是想调用它的某些方法来去完成一项通用的功能，那么可以将这个方法设置成静态方法，调用速度提升15%-20%，同时也不用为了调用这个方法去专门创建对象了，也不用担心调用这个方法后是否会改变对象的状态(静态方法无法访问非静态字段)。

  * 对常量使用static final修饰符

    ```
    static int intVal = 42;  
    static String strVal = "Hello, world!";  
    ```

    编译器会为上面的代码生成一个初始方法，称为方法，该方法会在定义类第一次被使用的时候调用。这个方法会将42的值赋值到intVal当中，从字符串常量表中提取一个引用赋值到strVal上。当赋值完成后，我们就可以通过字段搜寻的方式去访问具体的值了。

    final进行优化:

    ```
    static final int intVal = 42;  
    static final String strVal = "Hello, world!";  
    ```

    这样，定义类就不需要方法了，因为所有的常量都会在dex文件的初始化器当中进行初始化。当我们调用intVal时可以直接指向42的值，而调用strVal会用一种相对轻量级的字符串常量方式，而不是字段搜寻的方式。

    这种优化方式只对基本数据类型以及String类型的常量有效，对于其他数据类型的常量是无效的。

  * 使用增强型for循环语法

    ```
    static class Counter {  
        int mCount;  
    }  
      
    Counter[] mArray = ...  
      
    public void zero() {  
        int sum = 0;  
        for (int i = 0; i < mArray.length; ++i) {  
            sum += mArray[i].mCount;  
        }  
    }  
      
    public void one() {  
        int sum = 0;  
        Counter[] localArray = mArray;  
        int len = localArray.length;  
        for (int i = 0; i < len; ++i) {  
            sum += localArray[i].mCount;  
        }  
    }  
      
    public void two() {  
        int sum = 0;  
        for (Counter a : mArray) {  
            sum += a.mCount;  
        }  
    }  
    ```

    zero()最慢，每次都要计算mArray的长度，one()相对快得多，two()fangfa在没有JIT(Just In Time Compiler)的设备上是运行最快的，而在有JIT的设备上运行效率和one()方法不相上下，需要注意这种写法需要JDK1.5之后才支持。

    Tips:ArrayList手写的循环比增强型for循环更快，其他的集合没有这种情况。因此默认情况下使用增强型for循环，而遍历ArrayList使用传统的循环方式。

  * 多使用系统封装好的API

    > 系统提供不了的Api完成不了我们需要的功能才应该自己去写，因为使用系统的Api很多时候比我们自己写的代码要快得多，它们的很多功能都是通过底层的汇编模式执行的。 举个例子，实现数组拷贝的功能，使用循环的方式来对数组中的每一个元素一一进行赋值当然可行，但是直接使用系统中提供的System.arraycopy()方法会让执行效率快9倍以上。

  * 避免在内部调用Getters/Setters方法

    > 面向对象中封装的思想是不要把类内部的字段暴露给外部，而是提供特定的方法来允许外部操作相应类的内部字段。但在Android中，字段搜寻比方法调用效率高得多，我们直接访问某个字段可能要比通过getters方法来去访问这个字段快3到7倍。但是编写代码还是要按照面向对象思维的，我们应该在能优化的地方进行优化，比如避免在内部调用getters/setters方法。

* 布局优化

  * 减少布局文件层级

  * RelatvieLayout 和linearLayout都可以使用时，优先考虑使用 LinearLayout

  * 采用标签 和ViewStub

    > 重用布局文件
    >
    > 标签可以允许在一个布局当中引入另一个布局，那么比如说我们程序的所有界面都有一个公共的部分，这个时候最好的做法就是将这个公共的部分提取到一个独立的布局中，然后每个界面的布局文件当中来引用这个公共的布局。
    >
    > Tips:如果我们要在标签中覆写layout属性，必须要将layout_width和layout_height这两个属性也进行覆写，否则覆写xiaoguo将不会生效。
    >
    > 
    >
    > 标签是作为标签的一种辅助扩展来使用的，它的主要作用是为了防止在引用布局文件时引用文件时产生多余的布局嵌套。布局嵌套越多，解析起来就越耗时，性能就越差。因此编写布局文件时应该让嵌套的层数越少越好。
    >
    > 举例：比如在LinearLayout里边使用一个布局。里边又有一个LinearLayout，那么其实就存在了多余的布局嵌套，使用merge可以解决这个问题。
    >
    > \###仅在需要时才加载布局
    >
    > 某个布局当中的元素不是一起显示出来的，普通情况下只显示部分常用的元素，而那些不常用的元素只有在用户进行特定操作时才会显示出来。
    >
    > 举例：填信息时不是需要全部填的，有一个添加更多字段的选项，当用户需要添加其他信息的时候，才将另外的元素显示到界面上。用VISIBLE性能表现一般，可以用ViewStub。ViewStub也是View的一种，但是没有大小，没有绘制功能，也不参与布局，资源消耗非常低，可以认为完全不影响性能。
    >
    > ```
    > <ViewStub   
    >         android:id="@+id/view_stub"  
    >         android:layout="@layout/profile_extra"  
    >         android:layout_width="match_parent"  
    >         android:layout_height="wrap_content"  
    >         />  
    > public void onMoreClick() {  
    >     ViewStub viewStub = (ViewStub) findViewById(R.id.view_stub);  
    >     if (viewStub != null) {  
    >         View inflatedView = viewStub.inflate();  
    >         editExtra1 = (EditText) inflatedView.findViewById(R.id.edit_extra1);  
    >         editExtra2 = (EditText) inflatedView.findViewById(R.id.edit_extra2);  
    >         editExtra3 = (EditText) inflatedView.findViewById(R.id.edit_extra3);  
    >     }  
    > }  
    > ```
    >
    > tips：ViewStub所加载的布局是不可以使用标签的，因此这有可能导致加载出来出来的布局存在着多余的嵌套结构。

  * 避免过度绘制

    > 过度绘制（Overdraw）描述的是屏幕上的某个像素在同一帧的时间内被绘制了多次。在多层次重叠的 UI 结构里面，如果不可见的 UI 也在做绘制的操作，会导致某些像素区域被绘制了多次，同时也会浪费大量的 CPU 以及 GPU 资源。

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

  

#  七、内存优化

### 内存泄漏总结

* Java 内存分配策略

  > Java 程序运行时的内存分配策略有三种,分别是静态分配,栈式分配,和堆式分配，对应的，三种存储策略使用的内存空间主要分别是静态存储区（也称方法区）、栈区和堆区。
  >
  > - 静态存储区（方法区）：主要存放静态数据、全局 static 数据和常量。这块内存在程序编译时就已经分配好，并且在程序整个运行期间都存在。
  > - 栈区 ：当方法被执行时，方法体内的局部变量（其中包括基础数据类型、对象的引用）都在栈上创建，并在方法执行结束时这些局部变量所持有的内存将会自动被释放。因为栈内存分配运算内置于处理器的指令集中，效率很高，但是分配的内存容量有限。
  > - 堆区 ： 又称动态内存分配，通常就是指在程序运行时直接 new 出来的内存，也就是对象的实例。这部分内存在不使用时将会由 Java 垃圾回收器来负责回收。
  >
  > 
  >
  > 栈与堆的区别：
  >
  > 在方法体内定义的（局部变量）一些基本类型的变量和对象的引用变量都是在方法的栈内存中分配的。当在一段方法块中定义一个变量时，Java 就会在栈中为该变量分配内存空间，当超过该变量的作用域后，该变量也就无效了，分配给它的内存空间也将被释放掉，该内存空间可以被重新使用。
  >
  > 堆内存用来存放所有由 new 创建的对象（包括该对象其中的所有成员变量）和数组。在堆中分配的内存，将由 Java 垃圾回收器来自动管理。在堆中产生了一个数组或者对象后，还可以在栈中定义一个特殊的变量，这个变量的取值等于数组或者对象在堆内存中的首地址，这个特殊的变量就是我们上面说的引用变量。我们可以通过这个引用变量来访问堆中的对象或者数组。
  >
  > 举个例子:
  >
  > ```
  > public class Sample {
  >     int s1 = 0;
  >     Sample mSample1 = new Sample();
  > 
  >     public void method() {
  >         int s2 = 1;
  >         Sample mSample2 = new Sample();
  >     }
  > }
  > 
  > Sample mSample3 = new Sample();
  > ```
  >
  > Sample 类的局部变量 s2 和引用变量 mSample2 都是存在于栈中，但 mSample2 指向的对象是存在于堆上的。 mSample3 指向的对象实体存放在堆上，包括这个对象的所有成员变量 s1 和 mSample1，而它自己存在于栈中。
  >
  > 结论：
  >
  > 局部变量的基本数据类型和引用存储于栈中，引用的对象实体存储于堆中。—— 因为它们属于方法中的变量，生命周期随方法而结束。
  >
  > 成员变量全部存储与堆中（包括基本数据类型，引用和引用的对象实体）—— 因为它们属于类，类对象终究是要被new出来使用的。
  >
  > 了解了 Java 的内存分配之后，我们再来看看 Java 是怎么管理内存的。

* Java是如何管理内存

  > Java的内存管理就是对象的分配和释放问题。在 Java 中，程序员需要通过关键字 new 为每个对象申请内存空间 (基本类型除外)，所有的对象都在堆 (Heap)中分配空间。另外，对象的释放是由 GC 决定和执行的。在 Java 中，内存的分配是由程序完成的，而内存的释放是由 GC 完成的，这种收支两条线的方法确实简化了程序员的工作。但同时，它也加重了JVM的工作。这也是 Java 程序运行速度较慢的原因之一。因为，GC 为了能够正确释放对象，GC 必须监控每一个对象的运行状态，包括对象的申请、引用、被引用、赋值等，GC 都需要进行监控。
  >
  > 监视对象状态是为了更加准确地、及时地释放对象，而释放对象的根本原则就是该对象不再被引用。
  >
  > 为了更好理解 GC 的工作原理，我们可以将对象考虑为有向图的顶点，将引用关系考虑为图的有向边，有向边从引用者指向被引对象。另外，每个线程对象可以作为一个图的起始顶点，例如大多程序从 main 进程开始执行，那么该图就是以 main 进程顶点开始的一棵根树。在这个有向图中，根顶点可达的对象都是有效对象，GC将不回收这些对象。如果某个对象 (连通子图)与这个根顶点不可达(注意，该图为有向图)，那么我们认为这个(这些)对象不再被引用，可以被 GC 回收。 以下，我们举一个例子说明如何用有向图表示内存管理。对于程序的每一个时刻，我们都有一个有向图表示JVM的内存分配情况。以下右图，就是左边程序运行到第6行的示意图。
  >
  > [![img](https://camo.githubusercontent.com/ba01b8ae9af4a5e588251316c826bf3e0e695f35/687474703a2f2f7777772e69626d2e636f6d2f646576656c6f706572776f726b732f636e2f6a6176612f6c2d4a6176614d656d6f72794c65616b2f312e676966)](https://camo.githubusercontent.com/ba01b8ae9af4a5e588251316c826bf3e0e695f35/687474703a2f2f7777772e69626d2e636f6d2f646576656c6f706572776f726b732f636e2f6a6176612f6c2d4a6176614d656d6f72794c65616b2f312e676966)
  >
  > Java使用有向图的方式进行内存管理，可以消除引用循环的问题，例如有三个对象，相互引用，只要它们和根进程不可达的，那么GC也是可以回收它们的。这种方式的优点是管理内存的精度很高，但是效率较低。另外一种常用的内存管理技术是使用计数器，例如COM模型采用计数器方式管理构件，它与有向图相比，精度行低(很难处理循环引用的问题)，但执行效率很高。

* 什么是Java中的内存泄露

  > 在Java中，内存泄漏就是存在一些被分配的对象，这些对象有下面两个特点，首先，这些对象是可达的，即在有向图中，存在通路可以与其相连；其次，这些对象是无用的，即程序以后不会再使用这些对象。如果对象满足这两个条件，这些对象就可以判定为Java中的内存泄漏，这些对象不会被GC所回收，然而它却占用内存。
  >
  > 在C++中，内存泄漏的范围更大一些。有些对象被分配了内存空间，然后却不可达，由于C++中没有GC，这些内存将永远收不回来。在Java中，这些不可达的对象都由GC负责回收，因此程序员不需要考虑这部分的内存泄露。
  >
  > 通过分析，我们得知，对于C++，程序员需要自己管理边和顶点，而对于Java程序员只需要管理边就可以了(不需要管理顶点的释放)。通过这种方式，Java提高了编程的效率。
  >
  > [![img](https://camo.githubusercontent.com/4845ffe2ed44807b01b7bb93647dbff85de6300f/687474703a2f2f7777772e69626d2e636f6d2f646576656c6f706572776f726b732f636e2f6a6176612f6c2d4a6176614d656d6f72794c65616b2f322e676966)](https://camo.githubusercontent.com/4845ffe2ed44807b01b7bb93647dbff85de6300f/687474703a2f2f7777772e69626d2e636f6d2f646576656c6f706572776f726b732f636e2f6a6176612f6c2d4a6176614d656d6f72794c65616b2f322e676966)
  >
  > 因此，通过以上分析，我们知道在Java中也有内存泄漏，但范围比C++要小一些。因为Java从语言上保证，任何对象都是可达的，所有的不可达对象都由GC管理。
  >
  > 对于程序员来说，GC基本是透明的，不可见的。虽然，我们只有几个函数可以访问GC，例如运行GC的函数System.gc()，但是根据Java语言规范定义， 该函数不保证JVM的垃圾收集器一定会执行。因为，不同的JVM实现者可能使用不同的算法管理GC。通常，GC的线程的优先级别较低。JVM调用GC的策略也有很多种，有的是内存使用到达一定程度时，GC才开始工作，也有定时执行的，有的是平缓执行GC，有的是中断式执行GC。但通常来说，我们不需要关心这些。除非在一些特定的场合，GC的执行影响应用程序的性能，例如对于基于Web的实时系统，如网络游戏等，用户不希望GC突然中断应用程序执行而进行垃圾回收，那么我们需要调整GC的参数，让GC能够通过平缓的方式释放内存，例如将垃圾回收分解为一系列的小步骤执行，Sun提供的HotSpot JVM就支持这一特性。
  >
  > 同样给出一个 Java 内存泄漏的典型例子，
  >
  > ```
  > Vector v = new Vector(10);
  > for (int i = 1; i < 100; i++) {
  >     Object o = new Object();
  >     v.add(o);
  >     o = null;   
  > }
  > ```
  >
  > 在这个例子中，我们循环申请Object对象，并将所申请的对象放入一个 Vector 中，如果我们仅仅释放引用本身，那么 Vector 仍然引用该对象，所以这个对象对 GC 来说是不可回收的。因此，如果对象加入到Vector 后，还必须从 Vector 中删除，最简单的方法就是将 Vector 对象设置为 null。

### **详细Java中的内存泄漏**

* Java内存回收机制

  > 不论哪种语言的内存分配方式，都需要返回所分配内存的真实地址，也就是返回一个指针到内存块的首地址。Java中对象是采用new或者反射的方法创建的，这些对象的创建都是在堆（Heap）中分配的，所有对象的回收都是由Java虚拟机通过垃圾回收机制完成的。GC为了能够正确释放对象，会监控每个对象的运行状况，对他们的申请、引用、被引用、赋值等状况进行监控，Java会使用有向图的方法进行管理内存，实时监控对象是否可以达到，如果不可到达，则就将其回收，这样也可以消除引用循环的问题。在Java语言中，判断一个内存空间是否符合垃圾收集标准有两个：一个是给对象赋予了空值null，以下再没有调用过，另一个是给对象赋予了新值，这样重新分配了内存空间。

* .Java内存泄漏引起的原因

  > 内存泄漏是指无用对象（不再使用的对象）持续占有内存或无用对象的内存得不到及时释放，从而造成内存空间的浪费称为内存泄漏。内存泄露有时不严重且不易察觉，这样开发者就不知道存在内存泄露，但有时也会很严重，会提示你Out of memory。j
  >
  > Java内存泄漏的根本原因是什么呢？长生命周期的对象持有短生命周期对象的引用就很可能发生内存泄漏，尽管短生命周期对象已经不再需要，但是因为长生命周期持有它的引用而导致不能被回收，这就是Java中内存泄漏的发生场景。具体主要有如下几大类：
  >
  > 1、静态集合类引起内存泄漏：
  >
  > 像HashMap、Vector等的使用最容易出现内存泄露，这些静态变量的生命周期和应用程序一致，他们所引用的所有的对象Object也不能被释放，因为他们也将一直被Vector等引用着。
  >
  > 例如
  >
  > ```
  > Static Vector v = new Vector(10);
  > for (int i = 1; i<100; i++)
  > {
  > Object o = new Object();
  > v.add(o);
  > o = null;
  > }
  > ```
  >
  > 在这个例子中，循环申请Object 对象，并将所申请的对象放入一个Vector 中，如果仅仅释放引用本身（o=null），那么Vector 仍然引用该对象，所以这个对象对GC 来说是不可回收的。因此，如果对象加入到Vector 后，还必须从Vector 中删除，最简单的方法就是将Vector对象设置为null。
  >
  > 2、当集合里面的对象属性被修改后，再调用remove()方法时不起作用。
  >
  > 例如：
  >
  > ```
  > public static void main(String[] args)
  > {
  > Set<Person> set = new HashSet<Person>();
  > Person p1 = new Person("唐僧","pwd1",25);
  > Person p2 = new Person("孙悟空","pwd2",26);
  > Person p3 = new Person("猪八戒","pwd3",27);
  > set.add(p1);
  > set.add(p2);
  > set.add(p3);
  > System.out.println("总共有:"+set.size()+" 个元素!"); //结果：总共有:3 个元素!
  > p3.setAge(2); //修改p3的年龄,此时p3元素对应的hashcode值发生改变
  > 
  > set.remove(p3); //此时remove不掉，造成内存泄漏
  > 
  > set.add(p3); //重新添加，居然添加成功
  > System.out.println("总共有:"+set.size()+" 个元素!"); //结果：总共有:4 个元素!
  > for (Person person : set)
  > {
  > System.out.println(person);
  > }
  > }
  > ```
  >
  > 3、监听器
  >
  > 在java 编程中，我们都需要和监听器打交道，通常一个应用当中会用到很多监听器，我们会调用一个控件的诸如addXXXListener()等方法来增加监听器，但往往在释放对象的时候却没有记住去删除这些监听器，从而增加了内存泄漏的机会。
  >
  > 4、各种连接
  >
  > 比如数据库连接（dataSourse.getConnection()），网络连接(socket)和io连接，除非其显式的调用了其close（）方法将其连接关闭，否则是不会自动被GC 回收的。对于Resultset 和Statement 对象可以不进行显式回收，但Connection 一定要显式回收，因为Connection 在任何时候都无法自动回收，而Connection一旦回收，Resultset 和Statement 对象就会立即为NULL。但是如果使用连接池，情况就不一样了，除了要显式地关闭连接，还必须显式地关闭Resultset Statement 对象（关闭其中一个，另外一个也会关闭），否则就会造成大量的Statement 对象无法释放，从而引起内存泄漏。这种情况下一般都会在try里面去的连接，在finally里面释放连接。
  >
  > 5、内部类和外部模块的引用
  >
  > 内部类的引用是比较容易遗忘的一种，而且一旦没释放可能导致一系列的后继类对象没有释放。此外程序员还要小心外部模块不经意的引用，例如程序员A 负责A 模块，调用了B 模块的一个方法如： public void registerMsg(Object b); 这种调用就要非常小心了，传入了一个对象，很可能模块B就保持了对该对象的引用，这时候就需要注意模块B 是否提供相应的操作去除引用。
  >
  > 6、单例模式
  >
  > 不正确使用单例模式是引起内存泄漏的一个常见问题，单例对象在初始化后将在JVM的整个生命周期中存在（以静态变量的方式），如果单例对象持有外部的引用，那么这个对象将不能被JVM正常回收，导致内存泄漏，考虑下面的例子：
  >
  > ```
  > class A{
  > public A(){
  > B.getInstance().setA(this);
  > }
  > ....
  > }
  > //B类采用单例模式
  > class B{
  > private A a;
  > private static B instance=new B();
  > public B(){}
  > public static B getInstance(){
  > return instance;
  > }
  > public void setA(A a){
  > this.a=a;
  > }
  > //getter...
  > } 
  > ```
  >
  > 显然B采用singleton模式，它持有一个A对象的引用，而这个A类的对象将不能被回收。想象下如果A是个比较复杂的对象或者集合类型会发生什么情况



### Android中常见的内存泄漏汇总

* 集合类泄漏

  > 集合类如果仅仅有添加元素的方法，而没有相应的删除机制，导致内存被占用。如果这个集合类是全局性的变量 (比如类中的静态属性，全局性的 map 等即有静态引用或 final 一直指向它)，那么没有相应的删除机制，很可能导致集合所占用的内存只增不减。比如上面的典型例子就是其中一种情况，当然实际上我们在项目中肯定不会写这么 2B 的代码，但稍不注意还是很容易出现这种情况，比如我们都喜欢通过 HashMap 做一些缓存之类的事，这种情况就要多留一些心眼。

* 单例造成的泄漏

  > 由于单例的静态特性使得其生命周期跟应用的生命周期一样长，所以如果使用不恰当的话，很容易造成内存泄漏。比如下面一个典型的例子，
  >
  > ```
  > public class AppManager {
  > private static AppManager instance;
  > private Context context;
  > private AppManager(Context context) {
  > this.context = context;
  > }
  > public static AppManager getInstance(Context context) {
  > if (instance == null) {
  > instance = new AppManager(context);
  > }
  > return instance;
  > }
  > }
  > ```
  >
  > 这是一个普通的单例模式，当创建这个单例的时候，由于需要传入一个Context，所以这个Context的生命周期的长短至关重要：
  >
  > 1、如果此时传入的是 Application 的 Context，因为 Application 的生命周期就是整个应用的生命周期，所以这将没有任何问题。
  >
  > 2、如果此时传入的是 Activity 的 Context，当这个 Context 所对应的 Activity 退出时，由于该 Context 的引用被单例对象所持有，其生命周期等于整个应用程序的生命周期，所以当前 Activity 退出时它的内存并不会被回收，这就造成泄漏了。
  >
  > 正确的方式应该改为下面这种方式：
  >
  > ```
  > public class AppManager {
  > private static AppManager instance;
  > private Context context;
  > private AppManager(Context context) {
  > this.context = context.getApplicationContext();// 使用Application 的context
  > }
  > public static AppManager getInstance(Context context) {
  > if (instance == null) {
  > instance = new AppManager(context);
  > }
  > return instance;
  > }
  > }
  > ```
  >
  > 或者这样写，连 Context 都不用传进来了：
  >
  > ```
  > 在你的 Application 中添加一个静态方法，getContext() 返回 Application 的 context，
  > 
  > ...
  > 
  > context = getApplicationContext();
  > 
  > ...
  >    /**
  >      * 获取全局的context
  >      * @return 返回全局context对象
  >      */
  >     public static Context getContext(){
  >         return context;
  >     }
  > 
  > public class AppManager {
  > private static AppManager instance;
  > private Context context;
  > private AppManager() {
  > this.context = MyApplication.getContext();// 使用Application 的context
  > }
  > public static AppManager getInstance() {
  > if (instance == null) {
  > instance = new AppManager();
  > }
  > return instance;
  > }
  > }
  > ```

* 非静态内部类 创建静态实例 

  > 有的时候我们可能会在启动频繁的Activity中，为了避免重复创建相同的数据资源，可能会出现这种写法：
  >
  > ```
  >         public class MainActivity extends AppCompatActivity {
  >         private static TestResource mResource = null;
  >         @Override
  >         protected void onCreate(Bundle savedInstanceState) {
  >         super.onCreate(savedInstanceState);
  >         setContentView(R.layout.activity_main);
  >         if(mManager == null){
  >         mManager = new TestResource();
  >         }
  >         //...
  >         }
  >         class TestResource {
  >         //...
  >         }
  >         }
  > ```
  >
  > 这样就在Activity内部创建了一个非静态内部类的单例，每次启动Activity时都会使用该单例的数据，这样虽然避免了资源的重复创建，不过这种写法却会造成内存泄漏，因为非静态内部类默认会持有外部类的引用，而该非静态内部类又创建了一个静态的实例，该实例的生命周期和应用的一样长，这就导致了该静态实例一直会持有该Activity的引用，导致Activity的内存资源不能正常回收。正确的做法为：
  >
  > 将该内部类设为静态内部类或将该内部类抽取出来封装成一个单例，如果需要使用Context，请按照上面推荐的使用Application 的 Context。当然，Application 的 context 不是万能的，所以也不能随便乱用，对于有些地方则必须使用 Activity 的 Context，对于Application，Service，Activity三者的Context的应用场景如下：
  >
  > [![img](https://camo.githubusercontent.com/dee4aecb8a80c4e73337b56ee01cbffa2a8049dd/687474703a2f2f696d672e626c6f672e6373646e2e6e65742f32303135313132333134343232363334393f73706d3d353137362e3130303233392e626c6f67636f6e742e392e437455316334)](https://camo.githubusercontent.com/dee4aecb8a80c4e73337b56ee01cbffa2a8049dd/687474703a2f2f696d672e626c6f672e6373646e2e6e65742f32303135313132333134343232363334393f73706d3d353137362e3130303233392e626c6f67636f6e742e392e437455316334)
  >
  > 其中： NO1表示 Application 和 Service 可以启动一个 Activity，不过需要创建一个新的 task 任务队列。而对于 Dialog 而言，只有在 Activity 中才能创建

* 匿名内部类

  > 例如在actvity 中创建 runnable 而runnable 的线程生命周期比actvity 生命周期长的话，runnable会持有actvity的引用，那么会导致actvity的内存泄漏。

* handler 造成的内存泄漏

  > 创建handler 时，如果不是静态 会持有actvity 的引用
  >
  > handler 是属于 TLS(线程本地存储区) 变量，跟actvity的生命周期是不一致的，所以会造成actvity的内存泄漏，将handler 声明成 静态的就可以了，actvity 的context 可以采用 弱引用的方式传入。
  >
  > 
  >
  > 在Android应用的开发中，为了防止内存溢出，在处理一些占用内存大而且声明周期较长的对象时候，可以尽量应用软引用和弱引用技术。
  >
  > 软/弱引用可以和一个引用队列（ReferenceQueue）联合使用，如果软引用所引用的对象被垃圾回收器回收，Java虚拟机就会把这个软引用加入到与之关联的引用队列中。利用这个队列可以得知被回收的软/弱引用的对象列表，从而为缓冲器清除已失效的软/弱引用。
  >
  > 假设我们的应用会用到大量的默认图片，比如应用中有默认的头像，默认游戏图标等等，这些图片很多地方会用到。如果每次都去读取图片，由于读取文件需要硬件操作，速度较慢，会导致性能较低。所以我们考虑将图片缓存起来，需要的时候直接从内存中读取。但是，由于图片占用内存空间比较大，缓存很多图片需要很多的内存，就可能比较容易发生OutOfMemory异常。这时，我们可以考虑使用软/弱引用技术来避免这个问题发生

  

* 尽量避免使用static 成员变量

  > 如果 成员变量 被声明成static  那么生命周期与app进程一致，切到后台后，内存不会被释放，占内存较大的后台会优先被回收，如果做了保活，会造成app在后台频繁重启，这样时很耗电量与流量，解决方法 一时尽量避免 静态成员变量，二 时将 静态成员变量的生命周期管理起来。

* 资源未关闭造成的内存泄漏

  > braodcastrReceiver, ContentObserver,file,游标 Cursor,Stream,BItmap 等资源的使用，应该在actvtiy 销毁时及时关闭或注销，否则这些资源将不会被回收，造成内存泄漏

* 一些不良代码造成的内存压力

  * 例如 构建 Adapter 时，不使用缓存的 convertView ，每次创建 converView ，会造成内存压力，导致内存溢出，或者对大图片不进行压缩。

* 总结

  > 对 Activity 等组件的引用应该控制在 Activity 的生命周期之内； 如果不能就考虑使用 getApplicationContext 或者 getApplication，以避免 Activity 被外部长生命周期的对象引用而泄露。
  >
  > 尽量不要在静态变量或者静态内部类中使用非静态外部成员变量（包括context )，即使要使用，也要考虑适时把外部成员变量置空；也可以在内部类中使用弱引用来引用外部类的变量。
  >
  > 对于生命周期比Activity长的内部类对象，并且内部类中使用了外部类的成员变量，可以这样做避免内存泄漏：
  >
  > ```
  >     将内部类改为静态内部类
  >     静态内部类中使用弱引用来引用外部类的成员变量
  > ```
  >
  > Handler 的持有的引用对象最好使用弱引用，资源释放时也可以清空 Handler 里面的消息。比如在 Activity onStop 或者 onDestroy 的时候，取消掉该 Handler 对象的 Message和 Runnable.
  >
  > 在 Java 的实现过程中，也要考虑其对象释放，最好的方法是在不使用某对象时，显式地将此对象赋值为 null，比如使用完Bitmap 后先调用 recycle()，再赋为null,清空对图片等资源有直接引用或者间接引用的数组（使用 array.clear() ; array = null）等，最好遵循谁创建谁释放的原则。
  >
  > 正确关闭资源，对于使用了BraodcastReceiver，ContentObserver，File，游标 Cursor，Stream，Bitmap等资源的使用，应该在Activity销毁时及时关闭或者注销。
  >
  > 保持对对象生命周期的敏感，特别注意单例、静态对象、全局性集合等的生命周期

  

### 项目中内存泄露分析方法





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



# 十、JNI 基础

* ### 数据类型

  > - 基本数据类型
  >
  > | Java 类型 | Native 类型 | 符号属性 | 字长 |
  > | --------- | ----------- | -------- | ---- |
  > | boolean   | jboolean    | 无符号   | 8位  |
  > | byte      | jbyte       | 无符号   | 8位  |
  > | char      | jchar       | 无符号   | 16位 |
  > | short     | jshort      | 有符号   | 16位 |
  > | int       | jnit        | 有符号   | 32位 |
  > | long      | jlong       | 有符号   | 64位 |
  > | float     | jfloat      | 有符号   | 32位 |
  > | double    | jdouble     | 有符号   | 64位 |
  >
  > - 引用数据类型
  >
  > 
  >
  > | Java 引用类型       | Native 类型   | Java 引用类型 | Native 类型  |
  > | ------------------- | ------------- | ------------- | ------------ |
  > | All objects         | jobject       | char[]        | jcharArray   |
  > | java.lang.Class     | jclass        | short[]       | jshortArray  |
  > | java.lang.String    | jstring       | int[]         | jintArray    |
  > | Object[]            | jobjectArray  | long[]        | jlongArray   |
  > | boolean[]           | jbooleanArray | float[]       | jfloatArray  |
  > | byte[]              | jbyteArray    | double[]      | jdoubleArray |
  > | java.lang.Throwable | jthrowable    |               |              |

* ### String 字符串函数操作

  > | JNI 函数                                  | 描述                                                         |
  > | ----------------------------------------- | ------------------------------------------------------------ |
  > | GetStringChars / ReleaseStringChars       | 获得或释放一个指向 Unicode 编码的字符串的指针（指 C/C++ 字符串） |
  > | GetStringUTFChars / ReleaseStringUTFChars | 获得或释放一个指向 UTF-8 编码的字符串的指针（指 C/C++ 字符串） |
  > | GetStringLength                           | 返回 Unicode 编码的字符串的长度                              |
  > | getStringUTFLength                        | 返回 UTF-8 编码的字符串的长度                                |
  > | NewString                                 | 将 Unicode 编码的 C/C++ 字符串转换为 Java 字符串             |
  > | NewStringUTF                              | 将 UTF-8 编码的 C/C++ 字符串转换为 Java 字符串               |
  > | GetStringCritical / ReleaseStringCritical | 获得或释放一个指向字符串内容的指针(指 Java 字符串)           |
  > | GetStringRegion                           | 获取或者设置 Unicode 编码的字符串的指定范围的内容            |
  > | GetStringUTFRegion                        | 获取或者设置 UTF-8 编码的字符串的指定范围的内容              |
  >
  > 

* ### 常用 JNI 访问 Java 对象方法

  > ```
  > MyJob.java
  > package com.example.myjniproject;
  > 
  > public class MyJob {
  > 
  >     public static String JOB_STRING = "my_job";
  >     private int jobId;
  > 
  >     public MyJob(int jobId) {
  >         this.jobId = jobId;
  >     }
  > 
  >     public int getJobId() {
  >         return jobId;
  >     }
  > }
  > native-lib.cpp
  > #include <jni.h>
  > 
  > extern "C"
  > JNIEXPORT jint JNICALL
  > Java_com_example_myjniproject_MainActivity_getJobId(JNIEnv *env, jobject thiz, jobject job) {
  > 
  >     // 根据实力获取 class 对象
  >     jclass jobClz = env->GetObjectClass(job);
  >     // 根据类名获取 class 对象
  >     jclass jobClz = env->FindClass("com/example/myjniproject/MyJob");
  > 
  >     // 获取属性 id
  >     jfieldID fieldId = env->GetFieldID(jobClz, "jobId", "I");
  >     // 获取静态属性 id
  >     jfieldID sFieldId = env->GetStaticFieldID(jobClz, "JOB_STRING", "Ljava/lang/String;");
  > 
  >     // 获取方法 id
  >     jmethodID methodId = env->GetMethodID(jobClz, "getJobId", "()I");
  >     // 获取构造方法 id
  >     jmethodID  initMethodId = env->GetMethodID(jobClz, "<init>", "(I)V");
  > 
  >     // 根据对象属性 id 获取该属性值
  >     jint id = env->GetIntField(job, fieldId);
  >     // 根据对象方法 id 调用该方法
  >     jint id = env->CallIntMethod(job, methodId);
  > 
  >     // 创建新的对象
  >     jobject newJob = env->NewObject(jobClz, initMethodId, 10);
  > 
  >     return id;
  > }
  > ```

* ### 基础开发流程

  > - 在 java 中声明 native 方法
  >
  > ```
  > public class MainActivity extends AppCompatActivity {
  > 
  >     // Used to load the 'native-lib' library on application startup.
  >     static {
  >         System.loadLibrary("native-lib");
  >     }
  > 
  >     @Override
  >     protected void onCreate(Bundle savedInstanceState) {
  >         super.onCreate(savedInstanceState);
  >         setContentView(R.layout.activity_main);
  > 
  >         Log.d("MainActivity", stringFromJNI());
  >     }
  > 
  >     private native String stringFromJNI();
  > }
  > ```
  >
  > - 在 `app/src/main` 目录下新建 cpp 目录，新建相关 cpp 文件，实现相关方法（AS 可用快捷键快速生成）
  >
  > ```
  > native-lib.cpp
  > #include <jni.h>
  > 
  > extern "C" JNIEXPORT jstring JNICALL
  > Java_com_example_myjniproject_MainActivity_stringFromJNI(
  >         JNIEnv *env,
  >         jobject /* this */) {
  >     std::string hello = "Hello from C++";
  >     return env->NewStringUTF(hello.c_str());
  > }
  > ```
  >
  > > - 函数名的格式遵循遵循如下规则：Java_包名_类名_方法名。
  > > - extern "C" 指定采用 C 语言的命名风格来编译，否则由于 C 与 C++ 风格不同，导致链接时无法找到具体的函数
  > > - JNIEnv*：表示一个指向 JNI 环境的指针，可以通过他来访问 JNI 提供的接口方法
  > > - jobject：表示 java 对象中的 this
  > > - JNIEXPORT 和 JNICALL：JNI 所定义的宏，可以在 jni.h 头文件中查找到
  >
  > - 通过 CMake 或者 ndk-build 构建动态库

* ### System.loadLibrary()

  > `java/lang/System.java`:
  >
  > ```
  > @CallerSensitive
  > public static void load(String filename) {
  >     Runtime.getRuntime().load0(Reflection.getCallerClass(), filename);
  > }
  > ```
  >
  > - 调用 `Runtime` 相关 native 方法
  >
  > `java/lang/Runtime.java`:
  >
  > ```
  > private static native String nativeLoad(String filename, ClassLoader loader, Class<?> caller);
  > ```
  >
  > - native 方法的实现如下：
  >
  > `dalvik/vm/native/java_lang_Runtime.cpp`:
  >
  > ```
  > static void Dalvik_java_lang_Runtime_nativeLoad(const u4* args,
  >     JValue* pResult)
  > {
  >     ···
  >     bool success;
  > 
  >     assert(fileNameObj != NULL);
  >     // 将 Java 的 library path String 转换到 native 的 String
  >     fileName = dvmCreateCstrFromString(fileNameObj);
  > 
  >     success = dvmLoadNativeCode(fileName, classLoader, &reason);
  >     if (!success) {
  >         const char* msg = (reason != NULL) ? reason : "unknown failure";
  >         result = dvmCreateStringFromCstr(msg);
  >         dvmReleaseTrackedAlloc((Object*) result, NULL);
  >     }
  >     ···
  > }
  > ```
  >
  > - `dvmLoadNativeCode` 函数实现如下：
  >
  > ```
  > dalvik/vm/Native.cpp
  > bool dvmLoadNativeCode(const char* pathName, Object* classLoader,
  >         char** detail)
  > {
  >     SharedLib* pEntry;
  >     void* handle;
  >     ···
  >     *detail = NULL;
  > 
  >     // 如果已经加载过了，则直接返回 true
  >     pEntry = findSharedLibEntry(pathName);
  >     if (pEntry != NULL) {
  >         if (pEntry->classLoader != classLoader) {
  >             ···
  >             return false;
  >         }
  >         ···
  >         if (!checkOnLoadResult(pEntry))
  >             return false;
  >         return true;
  >     }
  > 
  >     Thread* self = dvmThreadSelf();
  >     ThreadStatus oldStatus = dvmChangeStatus(self, THREAD_VMWAIT);
  >     // 把.so mmap 到进程空间，并把 func 等相关信息填充到 soinfo 中
  >     handle = dlopen(pathName, RTLD_LAZY);
  >     dvmChangeStatus(self, oldStatus);
  >     ···
  >     // 创建一个新的 entry
  >     SharedLib* pNewEntry;
  >     pNewEntry = (SharedLib*) calloc(1, sizeof(SharedLib));
  >     pNewEntry->pathName = strdup(pathName);
  >     pNewEntry->handle = handle;
  >     pNewEntry->classLoader = classLoader;
  >     dvmInitMutex(&pNewEntry->onLoadLock);
  >     pthread_cond_init(&pNewEntry->onLoadCond, NULL);
  >     pNewEntry->onLoadThreadId = self->threadId;
  > 
  >     // 尝试添加到列表中
  >     SharedLib* pActualEntry = addSharedLibEntry(pNewEntry);
  > 
  >     if (pNewEntry != pActualEntry) {
  >         ···
  >         freeSharedLibEntry(pNewEntry);
  >         return checkOnLoadResult(pActualEntry);
  >     } else {
  >         ···
  >         bool result = true;
  >         void* vonLoad;
  >         int version;
  >         // 调用该 so 库的 JNI_OnLoad 方法
  >         vonLoad = dlsym(handle, "JNI_OnLoad");
  >         if (vonLoad == NULL) {
  >             ···
  >         } else {
  >             // 调用 JNI_Onload 方法，重写类加载器。
  >             OnLoadFunc func = (OnLoadFunc)vonLoad;
  >             Object* prevOverride = self->classLoaderOverride;
  > 
  >             self->classLoaderOverride = classLoader;
  >             oldStatus = dvmChangeStatus(self, THREAD_NATIVE);
  >             ···
  >             version = (*func)(gDvmJni.jniVm, NULL);
  >             dvmChangeStatus(self, oldStatus);
  >             self->classLoaderOverride = prevOverride;
  > 
  >             if (version != JNI_VERSION_1_2 && version != JNI_VERSION_1_4 &&
  >                 version != JNI_VERSION_1_6)
  >             {
  >                 ···
  >                 result = false;
  >             } else {
  >                 ···
  >             }
  >         }
  > 
  >         if (result)
  >             pNewEntry->onLoadResult = kOnLoadOkay;
  >         else
  >             pNewEntry->onLoadResult = kOnLoadFailed;
  > 
  >         pNewEntry->onLoadThreadId = 0;
  > 
  >         // 释放锁资源 
  >         dvmLockMutex(&pNewEntry->onLoadLock);
  >         pthread_cond_broadcast(&pNewEntry->onLoadCond);
  >         dvmUnlockMutex(&pNewEntry->onLoadLock);
  >         return result;
  >     }
  > }
  > ```

* ## CMake 构建 NDK 项目

  > > CMake 是一个开源的跨平台工具系列，旨在构建，测试和打包软件，从 Android Studio 2.2 开始，Android Sudio 默认地使用 CMake 与 Gradle 搭配使用来构建原生库。
  >
  > 启动方式只需要在 `app/build.gradle` 中添加相关：
  >
  > ```
  > android {
  >     ···
  >     defaultConfig {
  >         ···
  >         externalNativeBuild {
  >             cmake {
  >                 cppFlags ""
  >             }
  >         }
  > 
  >         ndk {
  >             abiFilters 'arm64-v8a', 'armeabi-v7a'
  >         }
  >     }
  >     ···
  >     externalNativeBuild {
  >         cmake {
  >             path "CMakeLists.txt"
  >         }
  >     }
  > }
  > ```
  >
  > 然后在对应目录新建一个 `CMakeLists.txt` 文件：
  >
  > ```
  > # 定义了所需 CMake 的最低版本
  > cmake_minimum_required(VERSION 3.4.1)
  > 
  > # add_library() 命令用来添加库
  > # native-lib 对应着生成的库的名字
  > # SHARED 代表为分享库
  > # src/main/cpp/native-lib.cpp 则是指明了源文件的路径。
  > add_library( # Sets the name of the library.
  >         native-lib
  > 
  >         # Sets the library as a shared library.
  >         SHARED
  > 
  >         # Provides a relative path to your source file(s).
  >         src/main/cpp/native-lib.cpp)
  > 
  > # find_library 命令添加到 CMake 构建脚本中以定位 NDK 库，并将其路径存储为一个变量。
  > # 可以使用此变量在构建脚本的其他部分引用 NDK 库
  > find_library( # Sets the name of the path variable.
  >         log-lib
  > 
  >         # Specifies the name of the NDK library that
  >         # you want CMake to locate.
  >         log)
  > 
  > # 预构建的 NDK 库已经存在于 Android 平台上，因此，无需再构建或将其打包到 APK 中。
  > # 由于 NDK 库已经是 CMake 搜索路径的一部分，只需要向 CMake 提供希望使用的库的名称，并将其关联到自己的原生库中
  > 
  > # 要将预构建库关联到自己的原生库
  > target_link_libraries( # Specifies the target library.
  >         native-lib
  > 
  >         # Links the target library to the log library
  >         # included in the NDK.
  >         ${log-lib})
  > ···
  > ```

* [CMake 命令详细信息文档](https://cmake.org/cmake/help/latest/manual/cmake-commands.7.html)

* ## 常用的 Android NDK 原生 API

  > | 支持 NDK 的 API 级别 | 关键原生 API         | 包括                                                         |
  > | -------------------- | -------------------- | ------------------------------------------------------------ |
  > | 3                    | Java 原生接口        | #include <jni.h>                                             |
  > | 3                    | Android 日志记录 API | #include <android/log.h>                                     |
  > | 5                    | OpenGL ES 2.0        | #include <GLES2/gl2.h> #include <GLES2/gl2ext.h>             |
  > | 8                    | Android 位图 API     | #include <android/bitmap.h>                                  |
  > | 9                    | OpenSL ES            | #include <SLES/OpenSLES.h> #include <SLES/OpenSLES_Platform.h> #include <SLES/OpenSLES_Android.h> #include <SLES/OpenSLES_AndroidConfiguration.h> |
  > | 9                    | 原生应用 API         | #include <android/rect.h> #include <android/window.h> #include<android/native_activity.h> ··· |
  > | 18                   | OpenGL ES 3.0        | #include <GLES3/gl3.h> #include <GLES3/gl3ext.h>             |
  > | 21                   | 原生媒体 API         | #include <media/NdkMediaCodec.h> #include <media/NdkMediaCrypto.h> ··· |
  > | 24                   | 原生相机 API         | #include <camera/NdkCameraCaptureSession.h> #include <camera/NdkCameraDevice.h> ··· |
  > |                      |                      |                                                              |

* 









