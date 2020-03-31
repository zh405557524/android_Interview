# 一、JVM





****

# 二、集合

* ArrayList 跟linkList的区别

  * 1、底层数据结构不同，ArrayList 数据结构是数组，通过索引可以查询到对应的数据。LinkedList 数据结构是双向链表结构，每个元素都有上一个和下一个元素的引用。
  * 2、 相对于ArrayList ,LinkedList 的插入、添加、删除速度更快，因为元素添加到集合种任意位置的时候，不需要像数组那样重新计算大小或者是更新索引。但是，查询速度更慢，数组通过索引就可以查到数据，链表只能挨个查询。
  * 3、LinkedList比ArrayList 更占内存，因为LinkedList为每一个节点存储了两个引用，一个指向上一个元素，一个指向下一个元素。

* hashMap的实现原理

  * HashMap 的概述：

    > HashMap是基于哈希表的Map接口的非同步实现。此实现提供所有可选的映射操作，并允许使用null值和null键。此类不保证映射的顺序，特别是它不保证该顺序恒久不变。
    >
    >  在java编程语言中，最基本的结构就是两种，一个是数组，另外一个是模拟指针（引用），所有的数据结构都可以用这两个基本结构来构造的，HashMap也不例外。HashMap实际上是一个“链表散列”的数据结构，即数组和链表的结合体。
    >
    > ![img](http://dl.iteye.com/upload/picture/pic/63364/042032ea-6f15-3428-bfb4-b3b1460769a7.jpg)
    >
    > HashMap底层就是一个数组结构，数组中的每一项又是一个链表。当新建一个HashMap的时候，就会初始化一个数组。
    >
    > ~~~java
    > /**
    >  * The table, resized as necessary. Length MUST Always be a power of two.
    >  */
    > transient Entry[] table;
    > 
    > static class Entry<K,V> implements Map.Entry<K,V> {
    >     final K key;
    >     V value;
    >     Entry<K,V> next;
    >     final int hash;
    >     ……
    > }
    > ~~~
    >
    > 
    >
    > Entry就是数组中的元素，每个 Map.Entry 其实就是一个key-value对，它持有一个指向下一个元素的引用，这就构成了链表。

     

