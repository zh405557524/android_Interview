## Framework面试题

### 一、消息机制与线程模型

#### 1. Handler / Looper / MessageQueue

**1. 这个知识点是干什么的**

Handler 是 Android 消息机制的上层接口，它的作用是把一个任务投递到 Handler 所在的线程去执行。最典型的场景，就是子线程执行完耗时任务以后，通过 Handler 切回主线程更新 UI。

**2. 核心原理**

Android 的消息机制主要涉及 4 个核心类：`Message`、`MessageQueue`、`Handler`、`Looper`。  
线程想处理消息，前提是先有自己的 `Looper`。`Looper` 内部会持有一个 `MessageQueue`，队列里保存这个线程后续要执行的消息。外部通过 `Handler` 发送 `Message` 或 `Runnable`，最终会进入目标线程的 `MessageQueue`。然后 `Looper.loop()` 在对应线程里不断取消息，再交给对应的 `Handler` 分发执行。  
所以它本质上不是 Handler 在主动切线程，而是把任务投递到目标线程的消息队列里，再由目标线程自己把任务取出来执行。

**3. 关键流程**

3.1 应用进程启动以后，会先进入 `ActivityThread.main()`。这里会调用 `Looper.prepareMainLooper()` 给主线程创建 `Looper` 和 `MessageQueue`。之所以主线程天然有消息循环，就是因为系统在进程入口就已经帮它准备好了。`prepareMainLooper()` 内部又会走到 `Looper.prepare()`，并通过 `ThreadLocal` 把当前线程和自己的 `Looper` 绑定起来，所以一条线程只能取到属于自己的那个 `Looper`。  
3.2 接着 `ActivityThread.main()` 会调用 `Looper.loop()` 开启主线程消息循环。`loop()` 本质上就是一个无限 `for` 循环，不断调用 `MessageQueue.next()` 取消息。这里要注意，`MessageQueue` 虽然叫队列，但底层并不是普通 FIFO，而是按消息执行时间 `when` 排序的单链表，所以它既能处理立即消息，也能处理延时消息。  
3.3 当我们调用 `post()`、`postDelayed()`、`sendMessage()`、`sendEmptyMessage()` 时，最终都会收敛到 `sendMessageAtTime()`。其中 `post()` 的本质并不是“直接执行 Runnable”，而是先把 `Runnable` 塞进 `Message.callback`，再把它包装成一条消息投递到目标线程，所以无论是 Runnable 还是 Message，最终都走统一调度链路。  
3.4 `sendMessageAtTime()` 再往下会调用 `MessageQueue.enqueueMessage()`。这个方法是真正开始调度的入口，它会按 `when` 把消息插入有序单链表中。如果新消息的执行时间比当前队头更早，就插在头部；否则顺着链表往后找第一个执行时间比它晚的节点，再把新消息插到它前面。也正因为如此，`MessageQueue` 天然具备“按执行时间调度”的能力。  
3.5 如果此时 `Looper.loop()` 所在线程正阻塞在 `MessageQueue.next()`，`enqueueMessage()` 会在必要时调用 `nativeWake()` 把它唤醒；而 `next()` 在没有可执行消息时，会通过 `nativePollOnce()` 进入 native 层等待。所以 Java 层看到的是“没消息就阻塞，有消息就继续跑”，底层其实对应的是一套 native 层的阻塞与唤醒机制。  
3.6 线程被唤醒以后，会重新回到 `Looper.loop()`，再次进入 `MessageQueue.next()` 判断当前到底该返回哪条消息。正常情况下，如果队头消息已经到时间，就直接取出返回；如果队头还没到时间，就继续等待。这里如果前面有同步屏障，也就是 `target == null` 的特殊节点，`next()` 会跳过普通同步消息，优先寻找后面的异步消息，所以同步屏障本质上是“控制消息优先级”的手段，常见场景就是配合 UI 刷新。  
3.7 `next()` 返回消息以后，`Looper.loop()` 会调用 `msg.target.dispatchMessage(msg)`，也就是把消息交给对应的 `Handler`。`dispatchMessage()` 的分发顺序是固定的：先执行 `Message.callback`，也就是 `post()` 进来的 `Runnable`；再执行 `Handler.Callback`；最后才回调我们重写的 `handleMessage()`。所以 `handleMessage()` 其实是整个 Handler 分发链路的最后一层。  
3.8 Handler 容易引发内存泄漏，也可以顺着这条链路理解。因为消息会在队列里停留一段时间，而非静态内部类 Handler 会隐式持有外部 Activity；一旦延时消息还没处理完，Activity 又已经退出，就可能因为消息链路仍然持有 Handler 而导致外部对象无法及时回收。

**4. 面试时怎么说**

Handler 是 Android 消息机制的上层接口，它的作用是把任务投递到 Handler 所在的线程执行，典型场景就是子线程切回主线程更新 UI。整个机制主要包括 `Message`、`MessageQueue`、`Handler`、`Looper` 四个核心类。主线程在应用启动时，会在 `ActivityThread.main()` 里通过 `Looper.prepareMainLooper()` 和 `Looper.loop()` 先把自己的消息循环建立起来。后面不管是 `post()` 还是 `sendMessage()`，最终都会走到 `sendMessageAtTime()`；如果是延时消息，本质上也是先算出未来执行时间，再统一入队。再往下 `enqueueMessage()` 会把消息按 `when` 插入到有序链表里，并在需要时通过 `nativeWake()` 唤醒阻塞线程。线程醒来后，`MessageQueue.next()` 负责返回当前可执行消息，最后 `Looper.loop()` 再通过 `dispatchMessage()` 把消息交给对应 Handler 处理。所以它本质上不是 Handler 在主动切线程，而是通过消息队列和消息循环，把任务交给目标线程自己执行。

**5. 可延伸点**

- 主线程为什么默认有 `Looper`，子线程为什么默认没有
- `ThreadLocal` 为什么能保证一个线程只拿到自己的 `Looper`
- `nativePollOnce()` 和 `nativeWake()` 是什么关系
- `MessageQueue` 为什么不是普通 FIFO
- `post()` 和 `sendMessage()` 的区别
- 同步屏障和异步消息是怎么配合的
- Handler 为什么容易引起内存泄漏
- 为什么子线程不能直接更新 UI

**6. 速记版**

Handler 机制主要涉及 `Message`、`MessageQueue`、`Handler`、`Looper` 这 4 个核心类。主线程在 `ActivityThread.main()` 里通过 `prepareMainLooper()` 和 `loop()` 先把消息循环建立起来，`loop()` 会不断调用 `next()` 取消息，没消息时线程会阻塞。后面不管是 `post()` 还是 `sendMessage()`，最终都会走到 `sendMessageAtTime()`；延时消息本质上也是先算出执行时间再统一入队。`enqueueMessage()` 会把消息按 `when` 插入有序链表，并在需要时通过 `nativeWake()` 唤醒阻塞线程。线程醒来以后，`next()` 负责选出当前可执行消息，最后 Looper 再通过 `dispatchMessage()` 把消息交给对应 Handler。所以它本质上不是直接切线程，而是把任务投递到目标线程的消息队列里，再由目标线程自己的 Looper 执行。

#### 2. HandlerThread

**1. 这个知识点是干什么的**

`HandlerThread` 的作用是快速创建一个带 `Looper` 的工作线程，适合把多个串行后台任务放到同一个线程里执行，比如数据库写入、日志落盘、轻量级 IO 等。

**2. 核心原理**

普通线程默认没有消息循环，所以不能直接创建和使用依赖 Looper 的 Handler。`HandlerThread` 本质上就是把 `Thread`、`Looper.prepare()` 和 `Looper.loop()` 封装到一起，让这个工作线程启动以后自动拥有自己的消息队列和消息循环。

**3. 关键流程**

3.1 创建 `HandlerThread` 对象并调用 `start()`，线程真正启动后会进入它的 `run()` 方法。  
3.2 `run()` 里先调用 `Looper.prepare()`，给当前工作线程创建 `Looper` 和 `MessageQueue`。  
3.3 接着会把创建好的 `Looper` 保存下来，外部就可以通过 `getLooper()` 拿到它。  
3.4 我们基于这个 `Looper` 创建 `Handler`，后续发送的消息就都会进入这个工作线程的 `MessageQueue`。  
3.5 最后 `run()` 会调用 `Looper.loop()`，开始不断取消息并串行执行。  
3.6 不再使用时，可以通过 `quit()` 或 `quitSafely()` 退出消息循环，其中 `quitSafely()` 会尽量处理完已经到期的消息后再结束。

**4. 面试时怎么说**

`HandlerThread` 可以理解成系统帮我们封装好的带消息循环的工作线程。普通子线程默认没有 `Looper`，所以不能直接配合 Handler 使用，而 `HandlerThread` 在内部的 `run()` 里会先调用 `Looper.prepare()` 创建消息循环，再调用 `Looper.loop()` 开始处理消息。这样我们拿到它的 `Looper` 以后，就可以创建一个绑定到这个线程的 Handler，把多个后台任务按顺序投递进去执行。它比较适合串行异步任务，不适合高并发计算；用完要记得调用 `quit()` 或 `quitSafely()` 释放线程。

**5. 可延伸点**

- `HandlerThread` 和线程池的区别
- `quit()` 和 `quitSafely()` 的区别
- 为什么它适合串行任务，不适合并发密集任务
- `IntentService` 和 `HandlerThread` 的关系

**6. 速记版**

`HandlerThread` 本质上就是一个自带 `Looper` 的工作线程。它在 `run()` 里先 `prepare()` 创建消息循环，再 `loop()` 开始取消息。外部拿到它的 `Looper` 创建 Handler 以后，就能把任务按顺序投递到这个线程执行。它适合串行后台任务，用完要记得退出 Looper。

#### 3. 为什么子线程不能直接更新 UI

**1. 这个知识点是干什么的**

这个问题本质上是在解释 Android 为什么要求 UI 操作集中在主线程执行，以及为什么框架要通过 Handler 之类的机制把任务切回主线程。

**2. 核心原理**

Android 的 View 树默认不是线程安全的。一个界面的测量、布局、绘制、事件分发都围绕同一棵 View 树展开，如果允许多个线程同时修改 UI 状态，就会带来竞态条件、状态错乱和渲染异常。Framework 选择了单线程 UI 模型，把所有 UI 操作统一放在主线程串行执行，降低复杂度和锁竞争成本。

**3. 关键流程**

3.1 Activity 启动以后，会在主线程里创建 `ViewRootImpl`，并把当前线程记录下来。  
3.2 后续 View 的刷新、布局、事件分发，都会沿着这条主线程链路执行。  
3.3 当子线程尝试直接触发某些 UI 更新时，最终可能走到 `ViewRootImpl.checkThread()`。  
3.4 这个方法会校验当前线程是不是创建 ViewRootImpl 的线程，如果不是，就抛出 “Only the original thread that created a view hierarchy can touch its views.” 之类的异常。  
3.5 所以正确做法通常是通过 `Handler`、`runOnUiThread()`、`View.post()` 或协程切到 `Dispatchers.Main`，让主线程自己去更新 UI。

**4. 面试时怎么说**

子线程不能直接更新 UI，本质原因不是说技术上绝对做不到，而是 Android 的 View 树默认不是线程安全的。一次界面更新会涉及测量、布局、绘制、事件分发等一整套流程，如果多个线程同时操作同一棵 View 树，就容易产生状态竞争和显示异常。Framework 为了降低复杂度，采用了 UI 单线程模型，把所有界面相关操作统一放在主线程串行执行。实际校验通常会落到 `ViewRootImpl.checkThread()`，如果当前线程不是创建这棵视图树的线程，就会直接抛异常。所以子线程更新结果时，一般要先切回主线程。

**5. 可延伸点**

- 为什么有些场景子线程改 View 属性没有立刻崩
- `View.post()` 为什么能切回主线程
- `SurfaceView` 为什么能在子线程刷新
- Compose 和传统 View 的线程模型有何共性

**6. 速记版**

子线程不能直接更新 UI，本质是因为 View 树不是线程安全的。Android 采用 UI 单线程模型，把测量、布局、绘制和事件分发都放在主线程串行执行。Framework 会在 `ViewRootImpl.checkThread()` 里校验当前线程，不是主线程就可能抛异常。所以子线程更新结果时，要通过 Handler 或其他方式切回主线程。

#### 4. IdleHandler / 同步屏障 / 异步消息

**1. 这个知识点是干什么的**

这几个点都属于 Handler 机制里的进阶能力，用来解决“什么时候在队列空闲时做事”以及“如何让某些高优先级消息优先执行”这类问题。

**2. 核心原理**

`IdleHandler` 是 `MessageQueue` 提供的空闲回调机制，当队列暂时没有可立即执行的消息时，可以执行一些低优先级任务。同步屏障则是在消息队列里插入一个特殊节点，它本身不会被执行，但会拦住后面的同步消息，让异步消息优先通过。两者都发生在 `MessageQueue.next()` 取消息的阶段。

**3. 关键流程**

3.1 `IdleHandler` 通过 `MessageQueue.addIdleHandler()` 注册到队列里。  
3.2 当 `MessageQueue.next()` 发现当前队列没有立刻可执行的消息时，会尝试回调这些 `IdleHandler`。  
3.3 如果回调返回 `false`，表示这个 IdleHandler 只执行一次；返回 `true` 则会继续保留。  
3.4 同步屏障本质上是一个 `target == null` 的特殊消息节点，它会插入到队列里某个位置。  
3.5 `next()` 遇到同步屏障后，不会直接返回这个节点，而是继续往后寻找第一条异步消息。  
3.6 异步消息通常通过 `Handler.createAsync()` 或给 Message 标记异步属性来产生，这样它们就可以在同步屏障存在时被优先执行，典型场景就是界面刷新相关调度。

**4. 面试时怎么说**

`IdleHandler`、同步屏障和异步消息都属于 MessageQueue 的进阶机制。`IdleHandler` 适合在消息队列暂时空闲时执行一些低优先级任务，比如预加载、延后初始化。同步屏障本质上是队列里的一个特殊节点，它本身不执行，但会先拦住同步消息，让后面的异步消息优先通过。这个机制的意义在于，当系统希望某些消息有更高时效性时，比如界面刷新，就可以借助异步消息绕过前面的同步消息排队。它们的核心都发生在 `MessageQueue.next()` 选择下一条可执行消息的阶段。

**5. 可延伸点**

- `IdleHandler` 的典型使用场景
- 为什么不能在 `IdleHandler` 里做重活
- 同步屏障是谁插入的
- 异步消息和普通消息的差异

**6. 速记版**

`IdleHandler` 用于消息队列空闲时执行低优先级任务，同步屏障用于先拦住同步消息，让异步消息优先执行。两者都发生在 `MessageQueue.next()` 选消息的阶段。`IdleHandler` 适合做延后初始化，同步屏障常和界面刷新调度配合使用。

### 二、Binder 与系统通信

#### 5. Binder 原理

**1. 这个知识点是干什么的**

Binder 是 Android 最核心的进程间通信机制，系统服务调用、AIDL、四大组件跨进程通信，底层大都建立在 Binder 之上。

**2. 核心原理**

Binder 的用户态主要有 4 个关键角色：`Client`、`Server`、`ServiceManager`、`BinderProxy/BpBinder`；内核态则依赖 Binder 驱动完成跨进程转发。  
服务端把自己的 Binder 实体注册到 `ServiceManager`，客户端先去查找服务，再拿到一个指向远端 Binder 的代理对象，后续所有方法调用都会被包装成一次 Binder 事务，通过 `Parcel` 写入参数，经 Binder 驱动转发到目标进程，再由服务端执行并把结果返回。  
它的本质是“面向对象的 IPC”，客户端像调用本地对象一样调用代理，底层再由驱动负责跨进程通信。

**3. 关键流程**

3.1 要理解 Binder，先要从 IPC 背景说起。进程之间天然是内存隔离的，A 进程不能直接访问 B 进程的地址空间，所以系统服务调用、跨进程组件通信都必须依赖进程间通信机制。Linux 传统 IPC 方案有管道、消息队列、Socket、共享内存等，而 Android 选择 Binder，是因为它更适合系统服务这种“频繁调用、需要权限校验、需要对象语义”的场景。  
3.2 从分层上看，`Client`、`Server`、`ServiceManager` 运行在用户空间，Binder 驱动运行在内核空间。应用要使用 Binder，最终都会访问 `/dev/binder` 这个设备文件，并通过 `open`、`mmap`、`ioctl` 等系统调用和 Binder 驱动交互。这里本质上是用户态把跨进程请求交给内核态，再由内核态负责转发。  
3.3 传统 IPC 常见问题是数据通常需要经过“发送方用户空间 -> 内核空间 -> 接收方用户空间”的复制链路，拷贝开销比较高。Binder 为了优化这件事，会借助 `mmap` 做内存映射，在接收进程一侧建立映射缓冲区。发送方发起事务时，数据先通过 `copy_from_user()` 进入内核缓冲区，再借助映射关系让接收方更高效地拿到数据。严格说 Binder 不是绝对零拷贝，但它在 Android 场景下能明显减少 IPC 成本。  
3.4 从通信模型上看，Binder 是典型的 C/S 架构，核心角色有 4 个：`Client` 负责发起请求，`Server` 提供服务能力，`ServiceManager` 负责服务注册与发现，Binder driver 负责跨进程转发。`ServiceManager` 的意义非常重要，它解决的是“客户端怎么根据名字找到目标服务”这个问题，否则客户端根本不知道远端服务在哪里。  
3.5 系统启动或者服务初始化时，服务端会先创建自己的 Binder 实体。Java 层常见做法是继承 `Binder`，或者让 AIDL 生成的 `Stub` 作为本地实体；native 层对应的是 `BBinder`。随后服务端会把这个 Binder 实体注册到 `ServiceManager`。注册之后，驱动会为该 Binder 实体维护内核侧的节点和引用关系，`ServiceManager` 则保存“服务名 -> Binder 引用”的查找表。  
3.6 客户端发起 `getService()` 之类的调用时，会先通过 `ServiceManager` 按名字查找目标服务。客户端最终拿到的并不是服务端真实对象，而是一个代理对象。Java 层常见的是 `BinderProxy`，native 层常见的是 `BpBinder`。这也是 Binder 的关键设计点之一：跨进程边界后，系统会自动把“本地实体”转换成“远程代理”，让客户端看起来像在调本地对象。  
3.7 当客户端调用代理对象的方法时，调用会先进入代理层，参数会被写入 `Parcel`。`Parcel` 是 Binder 专用的数据容器，和 `Serializable` 相比，它不追求通用对象图序列化，而是更强调 IPC 场景下的高效读写。之后代理对象会调用 `transact()` 发起一次 Binder 事务，把这次调用交给 Binder 驱动。  
3.8 Binder 驱动收到事务以后，会根据句柄、节点引用和目标进程信息，把这次请求路由到对应的服务端进程，并唤醒服务端 Binder 线程池中的某个线程处理请求。也就是说，Binder 不只是“搬数据”，它还顺手完成了对象寻址、线程唤醒、身份传递这些系统级工作。调用方的 UID、PID 也会随着事务一起传过去，所以服务端天然可以做权限校验，这也是 Binder 比很多传统 IPC 更适合系统服务的重要原因。  
3.9 服务端线程收到请求后，会进入本地 Binder 实体的处理链路。AIDL 场景下一般会进入 `Stub.onTransact()`，手写 Binder 场景下一般也会在 `onTransact()` 中解包 `Parcel`、分发 code、执行真实业务方法。Java 层可以把 `Stub` 理解成服务端本地实体，客户端的 `Proxy` 则是与之对应的远程代理，这一对就是典型的代理模式。  
3.10 服务端执行完真实逻辑以后，会把返回值、异常信息等重新写入 reply `Parcel`，再经由 Binder 驱动传回客户端。客户端代理层收到回复后，再把结果还原成方法返回值交给上层调用者。整个过程中，上层代码看起来像在调用本地接口，但底层实际走的是“代理封装 -> 驱动转发 -> 服务端执行 -> 结果回传”这条完整 IPC 链路。  
3.11 所以 Binder 为什么适合 Android 系统服务，也就比较清楚了。它不是单纯的传输通道，而是把服务发现、对象引用、权限身份、线程调度、事务通信整合到了一套机制里；这也是为什么 AIDL 本质上不是另一套 IPC，而只是帮我们自动生成 `Stub/Proxy` 代码，让 Binder 用起来更工程化。

**4. 面试时怎么说**

Binder 是 Android 最核心的 IPC 机制。它在用户态主要涉及 `Client`、`Server`、`ServiceManager` 和代理对象，在内核态依赖 Binder 驱动完成跨进程转发。服务端会先把自己的 Binder 实体注册到 `ServiceManager`，客户端再去查询服务并拿到一个远端代理对象，比如 Java 层常见的 `BinderProxy`。后面客户端调用代理对象方法时，会先把参数写进 `Parcel`，再通过 `transact()` 发起一次 Binder 事务。Binder 驱动根据目标对象把请求转发到服务端进程，由服务端的 Binder 线程执行真实逻辑，再把结果写回并返回。所以 Binder 的本质是把远程调用包装成像本地对象调用一样的形式，同时由系统统一做调度、权限校验和对象引用管理。

**5. 可延伸点**

- `BinderProxy`、`BpBinder`、`BBinder` 分别是什么
- `Parcel` 和 `Serializable` 的区别
- Binder 线程池是怎么工作的
- 一次 Binder 调用会不会阻塞调用方线程
- Binder 死亡通知是什么
- AIDL 和手写 Binder 的关系

**6. 速记版**

Binder 是 Android 的核心 IPC 机制。服务端先把 Binder 实体注册到 `ServiceManager`，客户端查询服务后拿到远端代理对象。后面方法调用会被写入 `Parcel`，再通过 `transact()` 发给 Binder 驱动，由驱动转发到服务端进程执行，最后再把结果返回。它本质上是面向对象的 IPC，让远程调用看起来像本地调用。

#### 6. Binder 为什么快

**1. 这个知识点是干什么的**

这个问题是在解释 Android 为什么没有把 Socket 作为系统级 IPC 主方案，而是专门设计了 Binder。

**2. 核心原理**

Binder 更快，不只是单纯某个 API 快，而是它在 Android 场景下的整体 IPC 成本更低。它通过内核驱动统一管理对象引用和进程通信，数据传递路径更短，拷贝次数更少，同时权限校验、身份信息传递和服务发现也是一体化的。

**3. 关键流程**

3.1 Binder 驱动会在内核中维护进程间通信所需的对象引用和句柄映射。  
3.2 客户端发起事务时，不需要像传统 Socket 那样自己处理连接管理、协议封包、服务发现。  
3.3 数据会被写入 `Parcel`，再由 Binder 驱动协调传输，典型场景下比传统管道或 Socket 拷贝路径更短。  
3.4 驱动还会顺手带上调用方 UID、PID 等身份信息，服务端可以直接做权限控制。  
3.5 因为 Binder 是 Android 系统级统一方案，所以系统服务、对象引用、死亡通知、线程模型都围绕这套机制做了优化。

**4. 面试时怎么说**

Binder 比 Socket 更适合 Android IPC，核心原因不是只看单次传输速度，而是看整个系统级调用成本。第一，Binder 由内核驱动统一管理对象引用和跨进程转发，拷贝次数相对更少；第二，客户端不需要自己维护连接、协议和服务发现，远程对象调用被抽象得很像本地方法调用；第三，Binder 在调用链里会天然携带 UID、PID 等身份信息，权限控制更方便；第四，Android 的系统服务、AIDL、死亡通知、线程池模型都围绕 Binder 设计，所以它在系统场景下整体效率和可管理性都更好。

**5. 可延伸点**

- Binder 是不是零拷贝
- Binder 和共享内存的关系
- Binder 为什么适合系统服务，不一定适合大文件传输
- Socket 在 Android 里还有哪些使用场景

**6. 速记版**

Binder 快，主要是因为它是 Android 专门为 IPC 设计的系统级方案。它通过驱动统一管理对象引用和进程通信，拷贝路径更短，调用像本地方法，服务发现和权限校验也一体化完成。所以在系统服务调用场景下，比 Socket 更高效也更好管理。

#### 7. AIDL 的本质

**1. 这个知识点是干什么的**

AIDL 的作用是帮助我们定义跨进程接口，让客户端和服务端可以按统一协议进行 Binder 通信。

**2. 核心原理**

AIDL 本身不是另一套 IPC 机制，它只是 Android 提供的一种接口描述语言。开发者先写 `.aidl` 接口文件，编译后系统会自动生成 `Stub` 和 `Proxy` 代码。后面客户端调用 `Proxy`，服务端实现 `Stub`，底层仍然是通过 Binder 和 `Parcel` 完成事务通信。

**3. 关键流程**

3.1 开发者先定义一个 `.aidl` 文件，描述这个远程服务具备哪些可跨进程调用的方法。这里的本质不是“声明一个普通接口”，而是在声明一份 Binder 通信契约。  
3.2 编译阶段，AIDL 工具会根据这份契约生成 `Stub` 和 `Proxy` 代码。`Stub` 代表服务端本地实体的包装，`Proxy` 代表客户端远程代理，所以 AIDL 做的核心工作其实是帮我们把 Binder 模板代码自动生成出来。  
3.3 服务端通常会继承生成出来的 `Stub`，并实现里面定义的方法。这样服务端既有了本地业务实现，也具备了 `onTransact()` 这层 Binder 分发入口。  
3.4 客户端拿到服务端返回的 `IBinder` 后，会通过 `Stub.asInterface()` 把它转成目标接口。这个方法内部会先判断当前是不是同进程调用：如果是同进程，可能直接返回服务端本地对象；如果是跨进程，则返回 `Proxy`。  
3.5 当客户端调用这个接口方法时，如果实际拿到的是 `Proxy`，调用就会被转成一次 Binder 事务。`Proxy` 会把参数写入 `Parcel`，再通过 `transact()` 把请求发给 Binder 驱动。  
3.6 驱动把请求转发到服务端后，服务端的 `Stub.onTransact()` 会根据 transaction code 解包参数、路由到具体方法、执行真实逻辑，再把返回值写回 reply `Parcel`。所以 AIDL 的核心不是发明了新的通信机制，而是把 Binder 的 `Stub/Proxy/asInterface/transact/onTransact` 这一整套模板化了。

**4. 面试时怎么说**

AIDL 的本质不是新的 IPC 方案，而是 Binder 的一层接口描述和代码生成工具。我们先定义 `.aidl` 接口，编译后系统会生成 `Stub` 和 `Proxy`。服务端通常继承 `Stub` 实现业务逻辑，客户端拿到 `IBinder` 以后通过 `asInterface()` 转成目标接口。后面如果是跨进程调用，实际走的是代理对象把参数写进 `Parcel`，再通过 Binder 发给服务端执行。所以 AIDL 的本质，还是对 Binder 调用过程做了一层标准化封装。

**5. 可延伸点**

- 为什么 AIDL 参数类型有限制
- `in`、`out`、`inout` 是什么
- 同进程调用为什么可能不走代理
- 手写 Binder 和 AIDL 的优缺点对比

**6. 速记版**

AIDL 不是新的 IPC 机制，它只是 Binder 的接口描述语言。开发者写 `.aidl` 接口后，编译器会生成 `Stub` 和 `Proxy`。客户端调用 `Proxy`，服务端实现 `Stub`，底层仍然是通过 `Parcel` 和 Binder 驱动做跨进程通信。

### 三、系统启动与组件链路

#### 8. Android 系统启动流程

**1. 这个知识点是干什么的**

这个知识点是用来回答 Android 从开机到桌面可用，中间到底经历了哪些核心进程和 Framework 服务的启动过程。

**2. 核心原理**

Android 系统启动的核心主线可以概括为：`init` 进程拉起系统基础环境，启动 `zygote`；`zygote` 负责孵化 Java 世界的关键进程；随后 `SystemServer` 被创建并启动大量 Framework 核心服务，比如 `ActivityManagerService（AMS）`、`PackageManagerService（PMS）`、`WindowManagerService（WMS）`；这些服务准备完成后，再启动 Launcher，用户最终看到桌面。

**3. 关键流程**

3.1 设备上电后，Linux 内核先完成自身启动，随后进入用户空间的第一个进程 `init`。`init` 之所以重要，是因为它是整个用户空间的起点，后续大部分系统进程最终都由它或者它拉起的子链路启动。  
3.2 `init` 启动后会解析 `init.rc` 以及其他 rc 脚本，完成挂载文件系统、初始化属性服务、启动一些 native 守护进程等基础工作。这里可以把它理解成“把 Android 运行环境的地基先打好”。在 rc 脚本里还会看到 `app_process` 和 `zygote` 相关配置，这就是 Java 世界入口的起点。  
3.3 随后 `init` 会启动 `zygote`。`zygote` 进程的入口在 `ZygoteInit.main()`，它会做几件关键事情：创建 Java 虚拟机运行环境、预加载常用类和资源、注册 zygote socket、准备后续 fork 逻辑。预加载的意义在于后续应用进程都从 zygote fork 出来，可以共享这部分已经加载好的内容，从而降低应用启动时的初始化成本。  
3.4 `ZygoteInit` 在启动阶段会调用 `registerZygoteSocket()` 建立 socket，这个 socket 的作用是等待系统服务发来“创建新进程”的请求。后面不管是 `SystemServer`，还是普通应用进程，本质上都是通过 zygote 这一套 fork 机制孵化出来的。Android 选择 fork 而不是每次从头创建虚拟机，也是为了复用 zygote 已有环境，让新进程启动更快。  
3.5 zygote 启动过程中还会调用 `startSystemServer()`，进一步走到 `forkSystemServer`，从 zygote 中 fork 出 `SystemServer`。`SystemServer` 可以理解成 Android Framework 的核心中枢进程，很多 Java 层系统服务都运行在这里。  
3.6 `SystemServer` 创建完成后，会进入 `SystemServer.main()`。在这条链路里，一方面会完成通用初始化，另一方面会进一步启动 Binder 线程池和系统服务管理框架。Binder 线程池在这个阶段被拉起来，意味着后续系统服务已经具备了通过 Binder 对外提供能力的基础。  
3.7 接下来 `SystemServer` 会按依赖顺序启动大量核心服务。最关键的几类包括：`ActivityManagerService（AMS）` 负责组件生命周期与进程调度，`PackageManagerService（PMS）` 负责应用安装包和组件解析，`WindowManagerService（WMS）` 负责窗口管理，此外还有 `PowerManagerService`、`DisplayManagerService` 等。这里之所以要按顺序启动，是因为很多服务之间存在依赖关系。  
3.8 这些服务初始化完成后，会陆续注册到 `ServiceManager`，对外暴露 Binder 接口。也就是说，应用进程后面通过 `Context.getSystemService()` 或其他入口拿到的大部分系统能力，本质上最终都会落到 `SystemServer` 中这些服务上。  
3.9 当核心服务基本准备就绪以后，系统会进入 `systemReady()` 阶段。这个阶段的含义不是“所有事情都做完了”，而是“系统已经具备对外提供核心能力的条件”，接下来就可以启动关键系统组件了。  
3.10 最后，`AMS` 会进一步启动带有 HOME 属性的桌面组件，也就是 Launcher。Launcher 本质上仍然是一个普通应用里的 Home Activity，只不过它承担了系统桌面的角色。等 Launcher 显示出来，用户才真正看到了可交互的系统桌面。  

**4. 面试时怎么说**

Android 系统启动流程如果站在 Framework 视角看，主线可以概括成 `init -> zygote -> SystemServer -> 核心系统服务 -> Launcher`。系统上电后，内核先启动，然后进入用户空间的 `init` 进程。`init` 会完成基础环境初始化，并拉起 `zygote`。`zygote` 负责预加载运行环境，并进一步创建 `SystemServer`。`SystemServer` 是 Framework 核心服务所在进程，它会启动 `AMS`、`PMS`、`WMS` 等关键系统服务。等这些服务准备完成以后，系统再启动 Launcher，用户最终看到桌面。所以这个流程的重点，其实就是从 native 世界进入 Java Framework 世界，再把系统服务体系建立起来。

**5. 可延伸点**

- `init` 进程的职责是什么
- `zygote` 为什么要预加载类和资源
- `SystemServer` 为什么这么重要
- `AMS`、`PMS`、`WMS` 分别做什么
- Launcher 是怎么被启动起来的

**6. 速记版**

Android 系统启动主线就是 `init -> zygote -> SystemServer -> AMS/PMS/WMS -> Launcher`。`init` 负责系统基础初始化，`zygote` 负责预加载和孵化进程，`SystemServer` 负责启动 Framework 核心服务，等核心服务准备完成后，再由系统拉起 Launcher，最终进入桌面。

#### 9. SystemServer 启动了哪些核心服务

**1. 这个知识点是干什么的**

这个问题主要是为了说明 `SystemServer` 为什么是 Android Framework 的中枢，以及系统能力是如何被这些核心服务拆分和承载的。

**2. 核心原理**

`SystemServer` 是一个系统进程，它内部会启动并持有大量 Java Framework 核心服务。这些服务各自负责一块系统能力，再通过 Binder 对外提供统一接口。应用进程平时调用的大部分系统服务，本质上都落在 `SystemServer` 里。

**3. 关键流程**

3.1 `zygote` fork 出 `SystemServer` 后，会进入 `SystemServer.main()`。  
3.2 `SystemServer` 会先准备主线程 Looper 和运行环境。  
3.3 接着会进入一系列启动阶段，比如 bootstrap、core、other services，不同服务按依赖顺序初始化。  
3.4 其中高频核心服务包括：`ActivityManagerService（AMS）` 负责组件和进程调度，`PackageManagerService（PMS）` 负责应用安装和包信息管理，`WindowManagerService（WMS）` 负责窗口管理，`PowerManagerService` 负责电源状态管理。  
3.5 这些服务初始化完成后，通常会注册到 `ServiceManager`，供其他进程通过 Binder 查询和调用。  
3.6 最终 `SystemServer` 会驱动系统进入可交互状态，并配合 AMS 启动桌面等关键组件。

**4. 面试时怎么说**

`SystemServer` 可以理解成 Android Framework 核心服务的大本营。它是由 `zygote` fork 出来的系统进程，启动后会按顺序初始化很多关键服务。面试里最常见的几个是 `AMS`，负责 Activity、Service、进程调度；`PMS`，负责安装包解析和应用信息管理；`WMS`，负责窗口管理；还有 `PowerManagerService` 等。这些服务启动后会注册到 `ServiceManager`，应用进程后续就是通过 Binder 去调用它们。所以 `SystemServer` 的意义，就是把系统级能力集中组织起来并统一对外提供。

**5. 可延伸点**

- 为什么这些服务要集中放在 `SystemServer`
- 服务启动顺序为什么重要
- `ATMS` 和 `AMS` 的关系
- `SystemServiceManager` 是做什么的

**6. 速记版**

`SystemServer` 是 Android Framework 核心服务所在进程。它由 `zygote` fork 出来，启动后会初始化 `AMS`、`PMS`、`WMS`、`PowerManagerService` 等关键服务，并把它们注册到 `ServiceManager`。应用平时调用的大部分系统服务，本质上都落在这里。

#### 10. Activity 启动流程

**1. 这个知识点是干什么的**

这个知识点是用来回答一次页面跳转从应用侧发起，到目标 Activity 真正创建并显示出来，中间都经过了哪些关键类和系统服务。

**2. 核心原理**

Activity 启动流程本质上是应用进程和系统服务协作完成的一次组件调度。应用侧先通过 `Instrumentation` 发起请求，再交给系统侧的 `ActivityTaskManagerService（ATMS）` 和 `ActivityManagerService（AMS）` 进行任务栈与进程管理。如果目标进程不存在，系统会先创建应用进程；进程准备好以后，再通过 `ApplicationThread` 把启动事务回调到应用主线程，由 `ActivityThread` 真正创建 Activity 实例并执行生命周期。

**3. 关键流程**

3.1 应用侧调用 `startActivity()` 以后，最先不会直接进入系统服务，而是先经过 `Instrumentation.execStartActivity()`。`Instrumentation` 的意义在于，它是应用进程内对组件启动、生命周期回调、测试注入等行为的统一代理入口，所以 Activity 启动的应用侧起点放在这里。  
3.2 `execStartActivity()` 接着会通过 Binder 调用系统侧的 `ActivityTaskManagerService（ATMS）` / `ActivityManagerService（AMS）`。这里开始进入系统调度阶段。ATMS 更偏任务栈、Activity 记录、启动模式和栈切换；AMS 更偏进程管理、系统级组件调度和整体运行状态管理。  
3.3 系统收到请求以后，会先做一轮完整判断：权限是否合法、Intent 能否解析到目标组件、当前任务栈怎么放、`launchMode` 和 `taskAffinity` 如何影响复用、目标 Activity 是否已经存在。这一步决定了后面到底是新建实例、复用实例，还是直接把已有页面调到前台。  
3.4 如果目标 Activity 所在进程还不存在，系统就会走进程创建链路，例如 `startProcessLocked()` 这类入口。随后 AMS 会通过 zygote socket 向 zygote 发送 fork 请求，由 zygote 创建出目标应用进程。冷启动、热启动、温启动的关键差异，核心就落在这里：冷启动通常需要创建新进程，热启动往往不需要。  
3.5 新进程创建后，会从 `ActivityThread.main()` 进入应用主线程初始化流程。这里同样会准备主线程 Looper、创建 `ActivityThread`、建立和 AMS 的应用侧桥梁。这个桥梁就是 `ApplicationThread`，它本质上是应用进程暴露给系统进程的 Binder 接口，系统后续要把组件启动事务下发给应用，就是通过它完成的。  
3.6 当系统确认目标进程已就绪后，会通过 `ApplicationThread.scheduleTransaction()` 把启动事务回调到应用进程。这里引入 `ClientTransaction` 的意义，是把过去分散的生命周期与回调调度统一收口成事务模型，由客户端统一执行，增强启动链路的组织性。  
3.7 应用主线程收到事务后，会交给 `TransactionExecutor` 执行。它会按事务中的 callback 和 lifecycle state request 依次推进，最终进入 `ActivityThread.handleLaunchActivity()`。也就是说，启动 Activity 不是系统直接跨进程“创建一个对象”，而是系统把一份事务描述发回应用主线程，再由应用自己按规则完成创建。  
3.8 `handleLaunchActivity()` 往下会调用 `performLaunchActivity()`，这里是真正创建 Activity 实例的核心入口。它会通过类加载器反射创建 Activity，准备 `LoadedApk`、拿到 `Application`、调用 `activity.attach()` 建立和上下文、token、Instrumentation 的关系，然后才会执行 `onCreate()`。所以 `performLaunchActivity()` 做的事情远不只是“回调生命周期”。  
3.9 Activity 在 `attach()` 过程中还会创建自己的 `PhoneWindow`。后面 `setContentView()` 会把业务布局添加到 `DecorView` 里，形成完整 View 树。随着事务继续推进，Activity 还会走 `onStart()`、`onResume()`，并在窗口添加到系统、ViewRootImpl 建立后真正具备显示能力。  
3.10 等到页面完成 resume，并且窗口内容经过 WMS、Surface、ViewRootImpl 这套链路显示到屏幕上，用户才算真正看到了目标 Activity。所以从整体上看，Activity 启动其实是“应用侧发起请求 -> 系统侧决定能不能启、怎么启 -> 应用主线程落地创建并显示页面”的完整协作过程。

**4. 面试时怎么说**

Activity 启动流程本质上是应用进程和系统服务配合完成的一次组件调度。应用侧调用 `startActivity()` 以后，会先走到 `Instrumentation.execStartActivity()`，再通过 Binder 把请求交给系统侧的 `ATMS/AMS`。系统会先处理任务栈、启动模式、权限校验这些问题，同时检查目标进程是否已经存在。若目标进程不存在，就先创建应用进程；进程起来以后，再通过应用进程里的 `ApplicationThread.scheduleTransaction()` 把启动事务回调到主线程。接着 `ActivityThread.handleLaunchActivity()` 和 `performLaunchActivity()` 会真正创建 Activity 实例，执行 `attach()`、`onCreate()`、`onStart()`、`onResume()`，并完成 Window 与 DecorView 的建立，最后把页面显示出来。冷启动和热启动的差别主要在于目标进程是否已经存在。

**5. 可延伸点**

- 冷启动、热启动、温启动的区别
- `ATMS` 和 `AMS` 分别负责什么
- `launchMode` 会在哪一步生效
- `onCreate()` 前后都做了哪些事
- Activity 为什么一定要运行在主线程

**6. 速记版**

Activity 启动主线是 `startActivity -> Instrumentation -> ATMS/AMS -> 进程检查或创建 -> ApplicationThread.scheduleTransaction -> ActivityThread.handleLaunchActivity -> performLaunchActivity`。系统先决定任务栈和进程，再把事务回调到目标应用主线程，由 `ActivityThread` 真正创建 Activity 并执行生命周期，最后把页面显示出来。

#### 11. Service 启动和 bindService 流程

**1. 这个知识点是干什么的**

这个知识点主要是回答 Service 的两种常见使用方式分别怎么工作，以及它们在生命周期和调用链上有什么区别。

**2. 核心原理**

`startService()` 和 `bindService()` 都会交给系统服务统一调度，但目标不一样。`startService()` 更偏“让服务自己运行起来”，强调生命周期独立；`bindService()` 更偏“让客户端和服务端建立连接”，强调接口交互和绑定关系。两者都可能触发服务所在进程创建。

**3. 关键流程**

3.1 应用侧调用 `startService()` 或 `bindService()` 后，请求都会先经过 `ContextImpl` 等应用侧入口，再通过 Binder 交给系统侧 AMS 进行统一调度。也就是说，Service 启动并不是应用自己直接 new 一个对象，而是交给系统去决定如何创建、何时创建、放在哪个进程里创建。  
3.2 系统收到请求后，会先根据 Intent 解析目标 Service，并检查目标进程是否已经存在。如果进程还没启动，就会先走进程创建链路，确保对应应用进程先起来。  
3.3 对于 `startService()`，系统的目标是“让服务开始运行”。因此在服务端进程准备好以后，主线程会先创建 Service 实例并执行 `onCreate()`，后续每次启动请求再进入 `onStartCommand()`。所以 `startService()` 更强调生命周期独立，它即使没有客户端绑定，也可以单独运行。  
3.4 对于 `bindService()`，系统的目标是“建立客户端和 Service 的连接”。如果服务还没创建，同样会先走 `onCreate()`；但接下来重点不是 `onStartCommand()`，而是调用 `onBind()`。`onBind()` 返回的 `IBinder`，本质上就是客户端和服务端后续通信的桥梁。  
3.5 客户端拿到这个 `IBinder` 后，会通过 `ServiceConnection.onServiceConnected()` 感知绑定成功。之后如果是同进程场景，可能直接拿到本地 Binder；如果是跨进程场景，通常会转成一个代理对象，再通过 Binder 发起远程调用。  
3.6 解绑时会走 `onUnbind()`，所有绑定都断开后，如果这个 Service 也没有被 `startService()` 持有启动引用，系统才可能进一步调用 `onDestroy()`。所以 `startService()` 和 `bindService()` 最大的本质区别，就是前者偏“启动型服务”，后者偏“连接型服务”，二者的生命周期引用是可以同时存在的。

**4. 面试时怎么说**

Service 的启动方式主要分 `startService()` 和 `bindService()` 两条线。共同点是它们最终都会交给系统服务统一调度，如果目标进程不存在，也都可能先拉起进程。区别在于，`startService()` 的重点是让服务自己运行起来，所以创建完成后会执行 `onCreate()` 和 `onStartCommand()`，生命周期相对独立；而 `bindService()` 的重点是建立客户端和服务之间的连接，所以在确保 Service 创建完成后，会调用 `onBind()` 返回一个 `IBinder` 给客户端，客户端再通过 `ServiceConnection` 建立通信通道。简单理解就是，一个偏启动运行，一个偏连接通信。

**5. 可延伸点**

- `startService()` 和 `bindService()` 可以同时存在吗
- `onBind()` 和 `onStartCommand()` 的区别
- 前台服务和普通服务的区别
- 服务被系统杀掉后会怎么恢复

**6. 速记版**

`startService()` 和 `bindService()` 都会先经过系统服务调度，目标进程不存在时都会先拉起进程。`startService()` 重点是运行服务本身，主流程是 `onCreate()` 加 `onStartCommand()`；`bindService()` 重点是建立连接，主流程是 `onCreate()` 加 `onBind()`，然后把 `IBinder` 回给客户端进行通信。

### 四、UI 与显示系统

#### 12. View 绘制与屏幕刷新流程

**1. 这个知识点是干什么的**

这个知识点是用来回答一次界面更新，从 View 发起刷新请求，到内容真正显示到屏幕，中间经历了哪些 View、渲染和显示系统的关键环节。

**2. 核心原理**

一次 UI 刷新不是简单调用一下 `onDraw()` 就结束了，它通常会经历 View 树的 `measure`、`layout`、`draw`，再经过渲染结果提交、系统合成、最终显示到屏幕。应用进程负责生产绘制结果，也就是 Buffer；系统侧的 `SurfaceFlinger` 负责把多个窗口或图层合成后输出到屏幕。

**3. 关键流程**

3.1 当界面需要更新时，常见入口是 `requestLayout()` 或 `invalidate()`。两者职责不一样：`requestLayout()` 表示当前 View 的尺寸或位置可能变了，需要重新走测量和布局；`invalidate()` 表示内容变了，需要重绘。很多人只记结论，但真正要点是：布局类变化优先影响 `measure/layout`，内容类变化优先影响 `draw`。  
3.2 这些请求最终都会汇总到 `ViewRootImpl`。`ViewRootImpl` 是 View 树和 Window 系统之间的桥梁，一头连着应用内的根 View，一头连着 `WMS`、`Surface` 和绘制调度链路。它收到刷新请求后，会调用 `scheduleTraversals()` 安排一次遍历，而不是立刻同步重绘，这样做是为了把同一帧里的多次刷新请求合并掉。  
3.3 `scheduleTraversals()` 内部会借助 `Choreographer.postCallback()` 注册一个遍历回调。`Choreographer` 的作用是把应用侧 UI 刷新节奏绑定到系统 VSYNC 节拍上，避免应用随意重绘。也就是说，View 绘制并不是“调用了就马上画”，而是尽量对齐到下一次屏幕刷新时机。  
3.4 当下一次 VSYNC 到来，`Choreographer` 会回调遍历任务，最终进入 `doTraversal()`，再走到 `ViewRootImpl.performTraversals()`。`performTraversals()` 可以理解成整个 View 树绘制总入口，它会统一决定这一帧是否需要 `performMeasure()`、`performLayout()`、`performDraw()`。  
3.5 `performMeasure()` 解决的是“每个 View 该多大”的问题，核心是父子之间通过 `MeasureSpec` 协商尺寸；`performLayout()` 解决的是“每个 View 放哪儿”的问题；`performDraw()` 解决的是“把最终内容画出来”。所以 `measure/layout/draw` 不是简单的三步模板，而是 View 系统分别在解决尺寸、位置、内容三个不同层面的约束。  
3.6 进入 draw 阶段以后，View 树会把绘制命令输出到和当前窗口关联的 `Surface`。这里应用并不是直接往物理屏幕上画，而是先把结果写入 Buffer。之所以要这样设计，是因为显示系统需要先收集不同窗口、不同图层的内容，再统一做合成，单个应用不能直接独占屏幕显示链路。  
3.7 在现代 Android 显示架构里，Buffer 生产和消费通常通过 BufferQueue 这套机制衔接。应用这一侧负责生产可显示的 Buffer，系统显示服务这一侧负责消费这些 Buffer。你可以简单理解成：应用负责“画出一帧”，而不是“直接显示一帧”。  
3.8 Buffer 准备好以后，会提交给系统显示链路，最终交由 `SurfaceFlinger` 处理。`SurfaceFlinger` 的职责是把来自不同窗口、不同 Layer 的内容做最终合成，然后交给显示硬件输出到屏幕。也正因为存在这个合成环节，系统才能同时管理状态栏、应用窗口、弹窗、动画等多个图层。  
3.9 如果某一帧在 UI 线程的测量布局绘制阶段耗时过长，或者 RenderThread / GPU / SurfaceFlinger 阶段跟不上节奏，就会错过当前 VSYNC 周期，表现成掉帧。所以从性能角度看，一帧卡顿可能不只发生在 `onDraw()`，也可能发生在主线程逻辑、布局计算、渲染提交乃至系统合成阶段。  

**4. 面试时怎么说**

View 绘制与屏幕刷新流程可以分成应用侧绘制和系统侧显示两部分来看。应用侧当 View 调用 `requestLayout()` 或 `invalidate()` 后，最终会由 `ViewRootImpl` 统一调度，并在 `performTraversals()` 里执行 `measure`、`layout`、`draw` 三大流程。绘制结果会被输出到当前窗口关联的 `Surface` Buffer 中。这个过程通常会由 `Choreographer` 配合 VSYNC 信号来调度，尽量和屏幕刷新节奏保持一致。之后这些 Buffer 会交给 `SurfaceFlinger`，由它把多个窗口图层合成，最终显示到屏幕上。所以可以简单理解成，应用负责产出内容，`SurfaceFlinger` 负责把内容真正显示出来。

**5. 可延伸点**

- `requestLayout()` 和 `invalidate()` 的区别
- 为什么 `measure/layout/draw` 不一定每次都全走
- `Choreographer` 在哪里介入
- `Surface` 和 `SurfaceView` 的关系
- 掉帧一般发生在哪些环节

**6. 速记版**

View 刷新主线是 `requestLayout/invalidate -> ViewRootImpl.scheduleTraversals() -> performTraversals() -> measure/layout/draw -> Surface Buffer -> SurfaceFlinger 合成 -> 屏幕显示`。应用负责把内容画到 Buffer 里，系统侧的 `SurfaceFlinger` 负责最终合成并显示到屏幕。

#### 13. Choreographer 与 16.6ms 刷新节奏

**1. 这个知识点是干什么的**

这个知识点主要解释 Android 为什么总在讲 16.6ms、VSYNC、掉帧，以及 `Choreographer` 在 UI 刷新里扮演什么角色。

**2. 核心原理**

屏幕通常按固定频率刷新，例如 60Hz 屏幕大约每 16.6ms 刷新一次。为了避免应用随意刷新带来的撕裂和浪费，Android 会用 VSYNC 信号作为统一节奏源，再由 `Choreographer` 在主线程上调度输入、动画、布局绘制等回调，让 UI 更新尽量贴着下一帧节奏执行。

**3. 关键流程**

3.1 显示系统周期性产生 VSYNC 信号。  
3.2 `Choreographer` 监听到 VSYNC 后，会把这一帧需要执行的回调组织起来。  
3.3 常见回调会分阶段处理，比如输入、动画、遍历绘制等。  
3.4 遍历绘制阶段最终会触发 `ViewRootImpl` 去执行 `performTraversals()`。  
3.5 如果主线程在一个刷新周期内没能完成这一帧该做的事，就可能错过本次显示时机，表现为掉帧。  
3.6 所以 16.6ms 不是说应用只能用 16.6ms 做所有事，而是说在 60Hz 下，主线程最好能在一个刷新节奏内完成当前帧关键工作。

**4. 面试时怎么说**

`Choreographer` 可以理解成 Android UI 刷新的节拍器。屏幕一般按固定频率刷新，比如 60Hz 下约每 16.6ms 一次，系统会提供 VSYNC 信号作为这一帧开始的时机。`Choreographer` 拿到 VSYNC 后，会在主线程上调度这一帧需要执行的输入、动画和遍历绘制回调，最终让 `ViewRootImpl` 去执行 `performTraversals()`。如果主线程没能在一个刷新周期内完成当前帧关键工作，就会错过这次显示机会，表现成掉帧。所以它的核心价值就是把应用侧 UI 更新和屏幕物理刷新节奏对齐。

**5. 可延伸点**

- 120Hz 屏幕时 16.6ms 还成立吗
- 掉帧和卡顿的关系
- `postInvalidateOnAnimation()` 和普通 `invalidate()` 的区别
- RenderThread 在哪里参与

**6. 速记版**

`Choreographer` 是 Android UI 刷新的节拍器。系统每次 VSYNC 到来时，它会调度输入、动画和绘制回调，让 `ViewRootImpl` 在合适时机执行遍历绘制。60Hz 屏幕下一个刷新周期约 16.6ms，如果主线程没赶上这次周期，就容易掉帧。

#### 14. View 事件分发机制

**1. 这个知识点是干什么的**

这个知识点是用来回答触摸事件从手指按下到最终被某个 View 消费，中间到底经过了哪些分发、拦截和消费逻辑。

**2. 核心原理**

Android 的事件分发本质上是一条从上到下再逐层返回的责任链。事件会先从 `Activity`、`Window` 进入整棵 View 树，再由 `ViewGroup` 决定是否要拦截；如果不拦截，就继续分发给子 View；最终由某个 View 的 `onTouchEvent()` 消费。

**3. 关键流程**

3.1 触摸事件到来后，通常会先进入 `Activity.dispatchTouchEvent()`。这一步说明事件分发的真正入口不是某个业务 View，而是先进入 Activity 和 Window 这层宿主结构。  
3.2 Activity 通常会把事件交给 `Window` 处理，`PhoneWindow` 再把它传给最顶层的 `DecorView`。`DecorView` 既是窗口内容的根 View，也是整棵 View 树事件分发的起点。  
3.3 `DecorView` 作为根 `ViewGroup`，会先进入自己的 `dispatchTouchEvent()`。`dispatchTouchEvent()` 的职责不是消费事件，而是决定事件应该继续往哪儿走，所以它是分发总入口。  
3.4 对于 `ViewGroup` 来说，分发过程中最关键的点是 `onInterceptTouchEvent()`。它决定父容器要不要在这一层截胡。如果返回 `true`，说明父容器要自己处理，后续事件就不再继续往子 View 分发；如果返回 `false`，才会继续交给目标子 View。  
3.5 子 View 收到事件后，同样会先走自己的 `dispatchTouchEvent()`，最终落到 `onTouchEvent()`。真正“消费事件”的动作通常发生在 `onTouchEvent()`，而不是 `dispatchTouchEvent()`。所以面试里要分清三个概念：`dispatchTouchEvent()` 是分发，`onInterceptTouchEvent()` 是拦截，`onTouchEvent()` 是消费。  
3.6 一旦某个节点成功消费了 `ACTION_DOWN`，这一整套手势序列后续的 `MOVE`、`UP` 通常会继续优先发给它；如果中途父容器决定拦截，或者事件被取消，就可能触发 `ACTION_CANCEL` 并重新改写分发目标。这也是为什么手势冲突处理通常要围绕 `ACTION_DOWN` 和拦截时机来分析。

**4. 面试时怎么说**

View 事件分发的主线可以概括成 `Activity -> Window -> DecorView -> ViewGroup.dispatchTouchEvent() -> onInterceptTouchEvent() -> child.dispatchTouchEvent() -> onTouchEvent()`。触摸事件先进入 Activity，再通过 Window 进入根布局 `DecorView`，之后沿着 View 树一层层向下分发。每个 `ViewGroup` 都可以通过 `onInterceptTouchEvent()` 决定要不要拦截；如果不拦截，就把事件继续交给子 View。最终真正处理点击、滑动等逻辑的，通常是在某个 View 的 `onTouchEvent()` 里。所以这个机制的关键就是三件事：谁来分发、谁来拦截、谁来消费。

**5. 可延伸点**

- `dispatchTouchEvent()`、`onInterceptTouchEvent()`、`onTouchEvent()` 的区别
- `ACTION_DOWN` 为什么重要
- `requestDisallowInterceptTouchEvent()` 的作用
- 点击事件和滑动冲突怎么处理

**6. 速记版**

事件分发主线是 `Activity -> Window -> DecorView -> ViewGroup -> child View`。每层 `ViewGroup` 先在 `dispatchTouchEvent()` 里分发，再通过 `onInterceptTouchEvent()` 决定是否拦截，不拦截就继续往子 View 传，最后由某个 View 的 `onTouchEvent()` 消费。核心就是分发、拦截、消费三件事。

#### 15. Window / WMS / SurfaceFlinger 的关系

**1. 这个知识点是干什么的**

这个知识点是用来回答 Android 一个页面显示出来时，应用窗口、系统窗口管理和最终屏幕合成之间分别由谁负责。

**2. 核心原理**

`Window` 是应用侧看到的窗口抽象，Activity 往往通过 `PhoneWindow` 管理自己的界面；`WindowManagerService（WMS）` 是系统侧的窗口管理者，负责窗口添加、删除、层级、焦点和动画等；`SurfaceFlinger` 则负责把各个窗口最终提交的图层内容合成到屏幕上。三者可以理解成：应用管理页面载体，系统管理窗口规则，显示系统负责最终出图。

**3. 关键流程**

3.1 Activity 在创建过程中会建立自己的 `Window`，典型实现就是 `PhoneWindow`。`Window` 可以理解成应用侧对“一个可显示界面载体”的抽象，它不负责真正的全局窗口调度，但负责管理当前页面的内容组织。  
3.2 当我们调用 `setContentView()` 时，本质上是把业务布局添加到 `PhoneWindow` 持有的 `DecorView` 内容区域里，最终形成当前页面的整棵 View 树。所以 `PhoneWindow` 管的是窗口容器，`DecorView` 管的是窗口里的根视图内容。  
3.3 当这个页面需要真正显示到系统时，应用不会直接和显示硬件交互，而是通过 `WindowManager` 把窗口添加出去。应用侧看到的是 `WindowManager` 接口，但它本质上只是系统窗口管理服务在应用进程里的代理。  
3.4 这个添加请求最终会通过 Binder 落到系统侧的 `WindowManagerService（WMS）`。`WMS` 负责的是全局窗口规则，比如窗口层级、焦点、尺寸、可见性、转场动画、输入目标等。也就是说，应用只负责声明“我想显示一个窗口”，真正决定这个窗口怎么参与系统窗口体系的是 WMS。  
3.5 窗口建立以后，页面内容会通过 `ViewRootImpl`、`Surface` 这条链路被绘制到对应 Buffer 中。这里要注意，普通 View 树并不是直接和 `SurfaceFlinger` 打交道，而是先依附于窗口，再通过窗口关联的 Surface 完成内容生产。  
3.6 最终 `SurfaceFlinger` 会把来自不同窗口、不同图层的 Buffer 合成后输出到屏幕。所以这三者的职责边界可以总结成：`Window` 负责应用侧页面载体，`WMS` 负责系统级窗口规则，`SurfaceFlinger` 负责最终图层合成显示。

**4. 面试时怎么说**

`Window`、`WMS`、`SurfaceFlinger` 可以分三个层次理解。`Window` 是应用侧的窗口抽象，Activity 一般通过 `PhoneWindow` 管理自己的界面和 `DecorView`。当应用要把窗口真正显示出来时，会通过 `WindowManager` 把请求交给系统侧的 `WindowManagerService`，由它负责窗口的添加、删除、层级、焦点和尺寸规则。窗口内容绘制完成后，会输出到对应的 `Surface` Buffer，最后再由 `SurfaceFlinger` 把多个窗口图层统一合成到屏幕上。所以三者关系可以概括成：应用负责组织窗口内容，WMS 负责管理窗口规则，SurfaceFlinger 负责最终显示合成。

**5. 可延伸点**

- `PhoneWindow` 和 `DecorView` 的关系
- `WindowManager` 和 `WMS` 的关系
- 普通 View 为什么不直接和 `SurfaceFlinger` 打交道
- `SurfaceView` 为什么是特殊存在

**6. 速记版**

`Window` 是应用侧窗口抽象，`WMS` 是系统侧窗口管理者，`SurfaceFlinger` 是最终的屏幕合成者。应用先通过 `PhoneWindow` 和 `DecorView` 组织界面，再把窗口交给 `WMS` 管理规则，最后把绘制结果交给 `SurfaceFlinger` 合成显示。

#### 16. Launcher 启动与桌面就绪

**1. 这个知识点是干什么的**

这个知识点主要回答系统服务启动完以后，为什么最终会进入桌面，以及桌面应用是怎么被系统拉起来的。

**2. 核心原理**

Launcher 本质上也是一个普通应用，只是它承担了系统桌面的角色。系统在核心服务就绪以后，会通过 `AMS` 启动一个带有 HOME 属性的 Activity，最终进入 Launcher 进程并显示桌面。

**3. 关键流程**

3.1 `SystemServer` 启动完核心服务后，系统进入可交互阶段。  
3.2 这时 `AMS` 会准备启动 Home 界面。  
3.3 系统会根据带有 `HOME` 类别和对应 `intent-filter` 的 Activity 查找合适的 Launcher。  
3.4 如果桌面进程还没启动，会先创建 Launcher 进程。  
3.5 随后会走一套标准的 Activity 启动流程，把 Launcher 的主界面创建出来。  
3.6 当 Launcher 的 Activity 完成 `onResume()` 并显示到前台时，用户就看到了系统桌面。

**4. 面试时怎么说**

Launcher 启动本质上也是一次标准的 Activity 启动，只不过它启动的是系统桌面对应的 Home Activity。系统在 `SystemServer` 把核心服务准备好以后，会由 `AMS` 去查找并启动带有 HOME 属性的 Launcher 组件。如果对应进程还没起来，就先拉起 Launcher 进程，再走正常的 Activity 启动流程。等 Launcher 显示出来，系统就进入了用户可交互的桌面状态。

**5. 可延伸点**

- 为什么 Launcher 本质上也是普通应用
- HOME Intent 是怎么匹配的
- 桌面进程被杀后怎么恢复
- 三方 Launcher 为什么能替换系统桌面

**6. 速记版**

Launcher 本质上也是一个 Activity，只是它承担了系统桌面角色。系统核心服务准备好后，`AMS` 会去启动带有 HOME 属性的桌面 Activity；如果桌面进程不存在就先拉起进程，再走标准 Activity 启动流程，最终进入桌面。
