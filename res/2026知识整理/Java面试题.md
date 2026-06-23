# Java 基础面试题

---

## 1. 面向对象思想：抽象类与接口的区别

- **抽象类**：`abstract class`，可包含抽象方法、具体方法、字段、构造器；单继承；表达 **“is-a”** 的层级与代码复用。
- **接口**：`interface`（Java 8+ 可有 `default`/`static` 方法），主要约定 **行为契约**；可多实现；更偏向 **“can-do”** 能力组合。
- **选型**：需要共享状态/模板方法时用抽象类；需要多继承式组合能力、与实现解耦时用接口。

---

## 2. Android 与 Java 序列化原理

- **Java 序列化**：`Serializable` 通过反射遍历对象图，写入类元数据与字段；性能与体积一般，版本兼容需注意 `serialVersionUID`。
    **优点：** 使用简单，声明接口即可。
    **缺点：** 
- **Android 推荐 `Parcelable`**：由开发者手写 `writeToParcel`/`CREATOR`，按字段顺序扁平写入 `Parcel`，**无反射、可裁剪字段**，启动 Activity、跨进程 Binder 更高效。
- **其他**：`Bundle` 传参、JSON/Protobuf 等属于“另一种序列化形态”，按场景选用。

---

## 3. 什么是单例？能手写一个吗

**单例**：全局唯一实例，控制构造与访问点，常见用于配置、缓存管理等（注意线程安全与测试可替换性）。

**线程安全懒汉（双重检查）示例**：

```java
public final class Singleton {
    private static volatile Singleton instance;

    private Singleton() {}

    public static Singleton getInstance() {
        if (instance == null) {
            synchronized (Singleton.class) {
                if (instance == null) {
                    instance = new Singleton();
                }
            }
        }
        return instance;
    }
}
```

**枚举单例**（Effective Java 推荐，防反射/序列化破坏）：`public enum Singleton { INSTANCE; }`

---

## 4. 什么是匿名内部类？有什么特征

- **定义**：没有名字、在表达式位置直接 `new 父类/接口() { ... }` 定义并实现方法的类。
- **特征**：可访问 **effectively final** 的外部局部变量；编译器生成合成类与 `this$0` 等；**非 static 匿名类持有外部类引用**，可能造成泄漏（典型：Handler 持有 Activity）。
- **Java 8+**：很多场景可用 **lambda** 替代函数式接口的匿名类。

---

## 5. `String` 中 `==` 与 `equals()` 的区别

- **`==`**：比较 **引用地址**是否相同（是否同一对象）。
- **`equals()`**：`String` 重写后比较 **字符序列内容**是否相同。
- **补充**：字符串常量池、`intern()` 会影响 `==` 的结果；业务比较内容应优先用 `equals`，并注意 **NPE**（`"x".equals(s)` 或 `Objects.equals`）。

---

## 6. 为什么说 `String` 不可变

- 内部 `char[]`/`byte[]`（JDK 9+ 压缩字符串）被 **`final` 封装**，对外无修改 API；`substring` 等新对象不共享可变底层（历史版本需注意）。
- **好处**：可安全作 `HashMap` 键、线程安全、便于常量池复用与哈希缓存。

---

## 7. 什么是内存泄漏？Java 是如何处理它的

- **泄漏**：对象已无业务需要，仍被 **GC Root 可达**（如静态集合、未取消监听、匿名内部类/Handler 链），导致无法回收、内存持续上涨。
- **Java 侧**：靠 **可达性分析 + GC** 回收不可达对象；泄漏不是“GC 坏了”，而是 **引用路径仍可达**。
- **处理**：断开引用（`null`、unregister、`WeakReference`）、避免长生命周期持有短生命周期上下文、LeakCanary 等工具辅助定位。

---

## 8. Java 回收机制，如何降低 OOM 概率

- **GC 简述**：分代/分区收集（Young/Old、G1、ZGC 等），标记可达对象，回收不可达内存。
- **降 OOM**：控制 **大对象/集合体量**、图片 **采样与复用**（Android `Bitmap`）、流及时 **close**、避免 **内存泄漏**、合理 **缓存上限**（LruCache）、分页加载、必要时 **`onTrimMemory`** 释放。

---

## 9. `ArrayList` 的特点

- **底层动态数组**；**随机访问 O(1)**；尾部增删均摊 O(1)，中间插入删除需搬移元素 O(n)。
- **扩容**：默认增长策略（如 1.5 倍），可指定 `initialCapacity` 减少扩容拷贝。
- **非线程安全**；`fail-fast` 迭代器（并发修改抛 `ConcurrentModificationException`）。

---

## 10. `LinkedList` 与 `ArrayList` 的区别

| 维度 | ArrayList | LinkedList |
|------|-----------|------------|
| 结构 | 数组 | 双向链表 |
| 随机访问 | O(1) | O(n) |
| 头尾插入删除 | 中间慢、尾部快 | 头尾 O(1)（已定位节点前提下） |
| 内存 | 连续、缓存友好 | 节点额外指针，碎片多 |
| 典型场景 | 多数默认列表 | 队列/双端队列（`Deque`）场景 |

---

## 11. `HashMap` 原理与性能优化

- **JDK 8**：数组 + 链表；哈希冲突时链表过长（>8 且桶容量足够）**树化**为红黑树，过短会 **退链**。
- **`put` 流程**：`hash` → 寻桶 `(n-1)&hash` → 比较 key `equals` → 插入/覆盖。
- **优化**：合理 **`initialCapacity`/`loadFactor`**、好的 **`hashCode`/`equals`**、避免过高冲突 key、多线程用 `ConcurrentHashMap` 而非外部大锁。

---

## 12. 从源码角度：`HashMap` 与 `SparseArray` 性能

- **`HashMap`**：通用键（对象哈希 + 装箱）、有额外节点/树开销；查找、扩容为 **O(1) 均摊**但常数因子较大。
- **`SparseArray`（及 `LongSparseArray`）**：**int 键**，**双数组**（keys 有序 + values），查找 **二分** O(log n)，插入可能搬移；**避免 Integer 装箱**，小数据量、内存更省；数据量大时随机访问可能不如 `HashMap`。
- **结论**：Android 上 **小映射、int 键** 可考虑 `Sparse*`；通用或大容量仍用 `HashMap`。

---

## 13. 快速排序能手写吗

**思想**：选基准，partition 使左侧 ≤ 基准、右侧 ≥ 基准，递归子区间。平均 O(n log n)，最坏 O(n²)（可随机化基准改善）。

```java
public static void quickSort(int[] a, int lo, int hi) {
    if (lo >= hi) return;
    int p = partition(a, lo, hi);
    quickSort(a, lo, p - 1);
    quickSort(a, p + 1, hi);
}

private static int partition(int[] a, int lo, int hi) {
    int pivot = a[hi];
    int i = lo;
    for (int j = lo; j < hi; j++) {
        if (a[j] <= pivot) {
            swap(a, i++, j);
        }
    }
    swap(a, i, hi);
    return i;
}

private static void swap(int[] a, int i, int j) {
    int t = a[i];
    a[i] = a[j];
    a[j] = t;
}
```

---

## 14. 查找算法你用过哪些

- **线性查找** O(n)：无序或小规模。
- **二分查找** O(log n)：有序数组；注意边界与 `mid` 计算防溢出 `(lo + hi) >>> 1`。
- **哈希查找** O(1) 均摊：`HashMap`/`HashSet`。
- **树结构**：BST/红黑树（`TreeMap`）有序遍历与范围查询。

---

## 15. 强引用、软引用、弱引用、虚引用

- **强引用**：普通 `=`，只要可达就不回收。
- **软引用 `SoftReference`**：内存不足时回收，适合 **缓存**（如图片缓存配合 `LruCache` 思路）。
- **弱引用 `WeakReference`**：下一次 GC 即回收，适合 **避免阻碍回收**（如 `WeakHashMap`、某些 listener 模式）。
- **虚引用 `PhantomReference`**：最弱，用于 **跟踪对象被回收的时机**（配合 `ReferenceQueue`），如堆外资源释放跟踪。

---

## 16. 什么是依赖注入？常见库

- **依赖注入（DI）**：由外部容器/框架 **创建并注入依赖**，而不是在类内部 `new`，降低耦合、便于测试与替换实现。
- **常见库**：**Dagger2 / Hilt**（编译期生成）、**Koin**（Kotlin DSL 运行时）、**Guice**、Spring（服务端）等。

---

## 17. `synchronized` 的作用

- **互斥**：同一监视器上 **同一时刻只有一个线程** 进入同步块/方法。
- **内存语义**：保证 **可见性** 与 **有序性**（释放锁 flush、获取锁 invalidate），建立 happens-before。
- **用法**：实例锁 `synchronized(this)`、静态锁 `synchronized(Class)`、`synchronized` 方法；JDK 6+ 锁升级（偏向→轻量→重量）；可与 `wait/notify` 配合（更推荐 `java.util.concurrent`）。

---

## 18. 如何根据泛型 `T` 获取具体类的类名

- **运行时泛型擦除**：一般方法里 **`T` 无具体 Class**，不能直接 `T.class`。

常用方式：

1. **构造/工厂传入 `Class<T>`**：`Class<T> clazz`，再 `clazz.getName()`。
2. **子类保留实际类型**：`TypeToken` / 匿名子类 `new TypeReference<List<String>>(){}` + 反射解析 `ParameterizedType`（Gson 等库用法）。
3. **方法参数**：`void foo(Class<T> type)`。

---

## 19. 注解的原理

- 注解是 **元数据**，保留策略：`SOURCE`（编译期丢弃）、`CLASS`（字节码）、`RUNTIME`（反射可读）。
- **处理**：编译期 **APT（Annotation Processor）** 生成代码（如 Dagger、DataBinding）；运行期 **反射** 读注解并执行逻辑（成本更高）。
- 字节码里以 **`RuntimeVisibleAnnotations`** 等形式存在。

---

## 20. 动态代理机制

- **JDK 动态代理**：`Proxy.newProxyInstance`，针对 **接口**，运行时生成 **代理类**（`Proxy` 子类 + `InvocationHandler`），调用转发到 `invoke`。
- **CGLIB / ByteBuddy**：**子类继承** 目标类，可代理无接口类（不能 `final` 类/方法）。
- **应用**：AOP、Retrofit 接口实现、Mock 等。

---

## 21. Android `ClassLoader` 原理简述

- **双亲委派**：`loadClass` 先交父加载器，父无法加载再自己加载，保证 **核心类唯一**、安全。
- **常见类型**：`BootClassLoader`（框架/SDK）、`PathClassLoader`（APK dex，**默认**）、`DexClassLoader`（可指定优化输出路径，用于插件/动态加载 dex）。
- **热修复/插件**：自定义 `ClassLoader` + dex 元素插入 **`DexPathList`**（如 `dexElements` 插队），使类解析优先加载补丁包；需注意 **Android 版本差异与禁止行为**（不同 ROM/版本策略不同）。

---

*整理用途：面试口述时可按“定义 → 原理要点 → 场景/坑”三层展开。*
