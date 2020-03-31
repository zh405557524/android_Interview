# 一、常见问题

* handler

  > 简答来说 就是 handler 添加消息任务到 MessageQueue 中、然后Loop不断从MessageQueue 读取消息任务，拿到Message后调用，message中的handler 对象的dispatchMessage()方法，handleMessage()->从而handler创建的线程收到子线程发送的Message对象，做对应的业务处理
  >
  > 复杂点的来说，
  >
  > 1、ActivityThread启动时在main中 调用了Loop的两个方法，一个是prepareMainLooper()，一个是loop方法；Loop.prepareMainLooper（）调用prepare() 方法，给loop里面的静态 对象 ThreadLocal 设置 loop对象。 loop方法是从ThreadLocal 取出loop对象，获取到MessageQueue 对象，在 for循环中 调用MessageQueue 的next方法取出message 对象，如果没有message 那么线程 会在nativePollOnce()这里进行睡眠
  >
  > 2、handler 在创建时，如果没有传递loop对象，通过Looper.myLooper() 获取到 ThreadLocal 中的loop对象，也就是主线中创建的loop对象。并将 loop对象，和loop中MessageQueue 对象 赋值给handle成员变量。
  >
  > 3、创建Message 对象，通过handler sendMessage（）调用 MessageQueue的enqueueMessage()方法将Message对象添加到 MessageQueue中，MessageQueue 是维护了Message链表，将新添加的Message 放在链表的最前面，然后调用natvieWake()方法 将主线程唤醒，next()继续执行方法。获取到message对象 传递给loop中，loop 方法会调用Message中的handler对象的dispatchMessage()方法。从而实现子线程到主线的数据传递。
  >
  > 
  
* 事件传递机制

  >
  >
  
* View 绘制流程

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

* 线程通信

  * handler
  * runOnUIThread
  * View.post()
  * AsyncTask

* http和https的区别、基础什么协议、get与post的区别

  * https协议需要Ca http是超文本协议传输，信息是明文传输。https则是具有安全性的ssl加密传输协议
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

