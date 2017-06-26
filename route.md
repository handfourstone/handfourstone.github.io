[<span style="font-size:20px;color:red">\<\<\<返回上级目录</span>](index.html)

# 本部分主要的数据结构


	include
	├── net
	│	├── dst.h
	│	│	├── struct dst_entry
	│	│	└── xxxxxxxxxxxxxx
	│	│
	│	├── dst_ops.h
	│	│	├── struct dst_ops
	│	│	└── xxxxxxxxxxxxxx
	│	│
	│	├── ip_fib.h
	│	│	├── struct fib_table
	│	│	├── struct fib_nh
	│	│	├── struct fib_info
	│	│	├── struct fib_result
	│	│	└── xxxxxxxxxxxxxx
	│	│
	│	├── flow.h
	│	│	├── struct flowi
	│	│	└── xxxxxxxxxxxxxx
	│	│
	│	├── fib_rules.h
	│	│	├── struct fib_rule
	│	│	└── xxxxxxxxxxxxxx
	│	│
	│	├── inetpeer.h
	│	│
	│	└── route.h
	│		├── struct rtable
	│		├── struct rt_cache_stat
	│		└── xxxxxxxxxxxxxx
	├── 
	│	├── fib_lookup.h 		
	│	│	└── struct fib_alias
	
	net
	├── ipv4
	│	├── fib_rules.c
	│	│	└── struct fib4_rule
	│	├── fib_lookup.h 		
	│	│	└── struct fib_alias
	│	│
	│	│
	│	│
	│
	└── core
	

## fib\_table

1. struct hlist\_node tb\_hlist

2. u32 tb\_id

	路由表标识符。取值定义在 include/uapi/linux/rtnetlink.h 中。

		enum rt_class_t {
			RT_TABLE_UNSPEC=0,
			/* User defined values */
			RT_TABLE_COMPAT=252,
			RT_TABLE_DEFAULT=253,
			RT_TABLE_MAIN=254,
			RT_TABLE_LOCAL=255,
			RT_TABLE_MAX=0xFFFFFFFF
		};

3. int tb\_num\_default

4. struct rcu\_head rcu

5. unsigned long \*tb\_data

6. unsigned long \_\_data[0]

## fib\_alias

fib\_alias 实例是用来区分目的网络相同但其它配置参数（除了目的地址以外）不同的路由项。下面逐一描述该结构中的字段。

1. struct hlist\_node fa\_list

2. struct fib\_info \*fa\_info

	该指针指向一个 fib_info 实例，该结构存储着如何处理与该路由相匹配封包的信息。

3. u8 fa\_tos

	路由的服务类型（TOS）位字段。当该值为 0 时意味着还没有配置 TOS，所以在路由查找时任何值都可以匹配。不要将 fa_tos 字段与 fib_fule 结构中的 t_tos 字段相混淆。fa_tos 字段允许用户在 TOS 中对个别路由表项指定条件，而 fib_rule 结构中的 r_tos 字段是用户在 TOS 中制定策略规则。

4. u8 fa\_type

	参见 [rtable](#rtable) 结构一节对 rt_type 字段的描述。

5. u8 fa\_state

	一些按位定义的标志，迄今为止只定义了下面一个标志（net/ipv4/fib_lookup.h）：

		FA_S_ACCESSED

	无论何时查找访问到 fib_alias 实例，就用该标识来标记。

6. u8 fa\_slen

7. u32 tb\_id

8. s16 fa\_default

9. struct rcu\_head rcu

## fib\_nh

对每一个吓一跳，内核需要跟踪的信息与 IP 地址相比更多。fib_nh 结构在下面字段中存储这些额外的信息：

1. struct net_device \*nh_dev

	这是与设备标识 nf_oif（后面介绍）相关的 net_device 数据结构。因为设备标识符和指向 net_device 结构的指针都需要利用，虽然利用其中任何一项都可以得到另一项，但这两项都保存在 fib_nh 结构中。

2. struct hlist_node nh_hash

	用于将 fib_nh 数据结构插入到在[吓一跳路由结构的组织]一节中描述的 hash 表中。

3. struct fib_info \*nh_parent

	该指针指向包含该 fib_nh 实例的 fib_info 结构，参见图 5.1。

4. unsigned int nh_flags

	在 include/linux/rtnetlink.h 文件中定义的一组 RTNH_F_XXX 标识，在表 7.7 中列出。

5. unsigned char nh_scope

	用于获取吓一跳路由范围。在大多数情况下为 RT_SCOPE_LINK。该字段由 fib_check_nh 初始化。

\#ifdef CONFIG_IP_ROUTE_MULTIPATH

6. int nh_weight

	仅当内核编译为支持多路径时，该字段才会成为该结构体的一部分。在[多路径路由背后的概念](#多路径路由背后的概念)一节对该字段由详细介绍。该字段由用户利用关键字 weight 来设置。

7. atomic_t nh_upper_bound

\#endif

\#ifdef CONFIG_IP_ROUTE_CLASSID

8. \_\_u32 nh_tclassid

	仅当内核编译为支持基友路由表的分类器时，该字段才是 fib_nh 数据结构的一部分。它的值是利用 realms 关键字来设置。参见[策略路由与基于路由表的分类器](#策略路由与基于路由表的分类器)一节。

\#endif

9. int nh_oif

	出口设备标识符。它是利用关键字 oif 和 dev 来设置的。

10. \_\_be32 nh_gw

	下一跳网管的 IP 地址，由关键字 via 提供。注意在 NAT 情况下，他表示 NAT 路由器向外部世界公告的地址。以及在 NAT 路由器向内网中主机发送回应之前向外部世界回应的地址。

11. \_\_be32 nh_saddr

12. int nh_saddr_genid

13. struct rtable \_\_rcu * \_\_percpu \*nh_pcpu_rth_output

14. struct rtable \_\_rcu \*nh_rth_input

15. struct fnhe_hash_bucket \_\_rcu \*nh_exceptions

16. struct lwtunnel_state \*nh_lwtstate


## fib\_info

在前面几节已经描述过，定义一个路由项的参数包含在 fib\_node 结构和 fib\_alias 结构的组合体中。如下一跳网关等重要的路由信息则存储在一个 fib\_info 结构内。下面逐一描述该结构中的字段。

1. struct hlist\_node fib\_hash

2. struct hlist\_node fib\_lhash

	用于将 fib_info 数据结构插入到 [fib_info 结构的组织](#fib_info结构的组织)一节中描述的两个 hash 表中。

3. struct net \*fib\_net

4. int fib\_treeref

	引用计数。持有该 fib_info 实例引用的 fib_node 数据结构的数目。

5. atomic\_t fib\_clntref

	引用计数。由于路由查找成功而被持有的引用计数。

6. unsigned int fib\_flags

	RTNH_F_XXX 标识的设置见下表。当前使用的唯一标识时 RTNH_F_DEAD。当与一个多路径路由项相关联的所有 fib_nh 结构都设置了 RTNH_F_DEAD 标识时，设置该标识（参见[常用的辅助程序与宏](#常见的辅助程序与宏)一节）。

7. unsigned char fib\_dead

	标记路由项正在被删除的路由标识。当该标识置 1 时，警告该数据结构将被删除而不能再使用。参见[删除路由](#删除路由)一节。

8. unsigned char fib\_protocol

	已安装的路由协议。该字段的可能取值 RTPROT_XXX 定义在 include/linux/rtnetlink.h 中，并在表 6.8 和表 6.9 中列出了这些值（这两个表中缺少了 ROUTED，因为它不使用 Netlink 接口与内核通信），参见[路由协议守护进程]一节中对这些协议的概述。

	fib_protocol 大于 RTPROT_STATIC 的值只用于不是由内核产生的路由项（即这些协议由用户空间的路由守护进程生成）。

	使用该字段的一个例子是，限制路由守护进程只能操作自己产生的路由项。更多细节参考第一章。

	Table 7.8 Vaules of fib_protocol used by the kernel

	| 值        |    描述 |
	|:---|:------------------------------------------------------------------------------------|
	| RTPROT_UNSPECT  | 无效的参数。 |
	| RTPROT_REDIRECT | 由 ICMP 重定向安装的路由，当前的 IPv4 不使用。 |
	| RTPROT_KERNEL   | 由内核安装的路由，参见[内核插入路由：fib_magic 函数](内核插入路由)。 |
	| RTPROT_BOOT     | 由用户空间命令如 ip route 和 route 安装的路由。 |
	| RTPROT_STATIC   | 由管理员安装的路由。 |

	Table 7.9 Values if fib_protocol used by user space

	|  值 |    描述 |
	|:----|:---------------------------------------------------------------------------|
	| RTPROT_GateD    | GateD 添加的路由。 |
	| RTPROT_RA       | RDISC（IPv4） 和 ND（IPv6）路由器公告的路由。这是一种 RFC 1256 定义的 ICMP 路由发现协议的机制，\
	使主机发现相邻的路由器。rdisc 是 iputils 软件包的一部分，用于实现用户空间的 ICMP 路由器发现消息。 |
	| RTPROT_MRT      | 由多线程路由工具包（Muting-Threaded Routing Toolkit, MRT）添加的路由。 |
	| RTPROT_ZEBRA    | 由 Zebra 添加的路由。 |
	| RTPROT_BITD     | 由 BIRD 添加的路由。 |
	| RTPROT_DMROUTED | 由 DECnet 路由守护进程添加的路由。  |
	| RTPROT_XORP     | 由 XORP 路由守护进程添加的路由。 |
	| RTPROT_NTK      | 由 Netsukuku 添加的路由。 |
	| RTPROT_DHCP     | 由 DHCP 客户端添加的路由。 |
	| RTPROT_MROUTED  | 由 Multicast 守护进程添加的路由。 |
	| RTPROT_BABEL    | 由 Babel 守护进程添加的路由。 |

9. unsigned char fib\_scope

10. unsigned char fib\_type

11. \_\_be32 fib_prefsrc

	首选 IP 地址。参见[选择源 IP 地址](#选择源 IP 地址)一节。

12. u32 fib\_tb\_id

13. u32 fib\_priority

	路由的优先级。值越小则优先级越高。它的值可以用 IPROUTE2 包中的 metric/priorty/preference 关键字来配置。当没有明确配置时，内核将他的值初始化为默认值 0。

14. u32 \*fib\_metrics;

	当配置路由时，ip route 命令允许指定一组规格（metric）。fib_metric 是存储这组规格的向量。没有明确设置的规格在初始化时被设置为 0。参见[路由的基本要素](#路由的基本要素)一节中列出的可用的规格。表 6.10 列出了路由的基本要素一节中列出的规格与在 include/linux/rtnetlink.h 文件中定义的相关内核符号 RTAX_XXX 之间的关系。

	Table 7.10 Routing metrics

	| 规格 | 内核符号 |
	|:----|:----------------------------------------------------------------------------|
	| | RTAX_UNSPEC |
	| 没有规格 | RTAX_LOCK |
	| 路径 MTU | RTAX_MTU  |
	| 最大的公告窗口 | RTAX_WINDOW |
	| 往返时间（RTT） | RTAX_RTT |
	| RTT 变量 | RTAX_RTTVAR |
	| 慢启动门限值 | RTAX_SSTHRESH |
	| 拥塞窗口 | RTAX_CWND |
	| 最大的段大小 | RTAX_ADVMSS |
	| 最大的重定序（Reordering）| RTAX_REORDERING  |
	| 默认的存活时间（TTL）| RTAX_HOPLIMIT |
	| 初始的拥塞窗口 | RTAX_INITCWND |
	| 不是一种规格 | RTAX_FEATURES |
	| | RTAX_RTO_MIN |
	| | RTAX_INITRWND |
	| | RTAX_QUICKACK |
	| | RTAX_CC_ALGO |

15. \#define fib\_mtu fib\_metrics[RTAX\_MTU-1]

	用于宏用于访问 fib_metrics 数组中指定的元素 RTAX_MTU。

16. \#define fib\_window fib\_metrics[RTAX\_WINDOW-1]

	用于宏用于访问 fib_metrics 数组中指定的元素 RTAX_WINDOW。

17. \#define fib\_rtt fib\_metrics[RTAX\_RTT-1]

	用于宏用于访问 fib_metrics 数组中指定的元素 RTAX_RTT。

18. \#define fib\_advmss fib\_metrics[RTAX\_ADVMSS-1]

	用于宏用于访问 fib_metrics 数组中指定的元素 RTAX_ADVMSS。

19. int fib\_nhs

	可变长度的数组，fib_nhs 时该向量的大小。仅当内核支持多路径功能时，fib_nhs 才可能大于 1，参见[多路径路由背后的概念](#多路径路由背后的概念)一节，以及图 5.1 。

\#ifdef CONFIG\_IP\_ROUTE\_MULTIPATH\

20. int fib_weight

\#endif

21. unsigned int fib\_offload\_cnt

22. struct rcu\_head rcu

23. struct fib\_nh fib\_nh[0]

	可变长度的数组，fib_nhs 时该向量的大小。仅当内核支持多路径功能时，fib_nhs 才可能大于 1，参见[多路径路由背后的概念](#多路径路由背后的概念)一节，以及图 5.1 。

24. \#define fib\_dev fib\_nh[0].nh\_dev

	这个宏用于访问 fib_nh 向量中第一个 fib_nh 实例的 nh_dev 字段。参见图 5.1 。


## fib_rule

利用 ip rule 命令来配置策略路由规则。如果你的 linux 系统上安装了 IPROUTE2 软件包，就可以输入 ip rule help 来查看该命令的语法。策略存储在 fib_rule 结构中，下面逐一介绍该结构的字段：


1. struct list_head list

	将所有的 fib_rule 结构连接到一个包含所有 fib_rule 实例的全局链表内，参见图 6.8。

2. int iifindex

	iifname （下面介绍）是策略应用的设备的名称，给定的 iifname，内核可以发现相关的 net_device 实例，并将该实例的 ifindex 字段拷贝到该字段中。iifindex 值区 -1 代表禁止该规则（参见[对策略数据库的影响一节](#对策略数据库的影响)）。

3. int oifindex

4. u32 mark

5. u32 mark_mask

6. u32 flags

7. u32 table

8. u8 action

	该字段允许的取值是定义在 include/uapi/linux/rtnetlink.h 文件中的 rtm_type 枚举值（RTN_UNICAST 等）。这些值含义在 [rtable](#rtable) 结构中介绍。

	当配置一条规则时，用户可以明确使用 type 关键字来设定该字段。如果没有明确配置，IPROUTE2 在添加规则时设置该字段的值为 RTN_UNICAST，在其它情况下设置为 RTN_UNSPEC（例如，当删除规则时）。

9. u8 l3mdev

10. u32 target

11. \_\_be64 tun_id

12. struct fib_rule \_\_rcu \*ctarget

13. struct net \*fr_net

14. atomic_t refcnt

15. u32 pref

	路由规则的优先级。当管理员用 IPROUTE2 软件包添加一个策略时，可以使用关键字 Priority、preference 和 order 来配置。如果没有明确配置，内核为其分配一个优先级，该值比用户添加的最后一个规则的优先级小一个级别（参见[inet_rtm_newrule](#inet_rtm_newrule)）。

16. int suppress_ifgroup

17. int suppress_prefixlen

18. char iifname[IFNAMSIZ]

19. char oifname[IFNAMSIZ]

20. struct fib_kuid_range uid_range

21. struct rcu_head rcu


## fib_result

fib_result 结构被 fib_semantic_match 初始化为路由查找结果，更多细节参考（[语义匹配附加标准](#语义匹配附加标准)）。该结构中的字段为：

1. unsigned char prefixlen

	匹配路由的前缀长度。参见 [fn_zone](#fn_zone) 中对 fz_order 的描述。

2. unsigned char nh_sel

	多路径路由由多个吓一跳定义。该字段标识已被选中的下一跳。

3. unsigned char type

	该字段被初始化为相匹配的 fib_alias 实例的 fa_type 的取值。

4. unsigned char scope

	该字段被初始化为相匹配的 fib_alias 实例的 fa_scope 的取值。

5. u32 tclassid


6. struct fib_info \*fi

	与匹配的 fib_alias 实例相关联的 fib_info 实例。

7. struct fib_table \*table

8. struct hlist_head \*fa_head


## rtable

IPv4 使用 rtable 数据结构来存储缓存中的路由表项（IPv6 使用 rt6_info, DECnet 使用 dn_route）。为了转储路由缓存的内容，可以查看 /proc/net/rt_cache 文件（参考[通过 /proc 文件系统调整](#通过/proc文件系统调整)一节），或是使用 ip route list cache 或 route -C 命令。下面逐一介绍该结构中的字段。

1. struct dst_entry dst

2. int rt_genid

3. unsigned int rt_flags

	在该位图中可以设置的标识为在 include/uapi/linux/in_route.h 文件中定义的 RTCF_XXX 值，表 7.11 中列出了这些值。

	Table 7.11 Possible values for rt_flags

	| 值 | 描述 |
	|:------|:------------------------------------------------------------------------|
	| RTCF_NOTIFY | 路由表项的任何变化，通过 Netlink 通知感兴趣的用户空间应用程序。该标识用 ip route get 10.0.1.0/24 notofy 的命令设置。|
	| RTCF_DIRECTDST| 没有使用。|
	| RTCF_REDIRECTED | 表项已被添加加以响应接收到的 ICMP_REDIRECT 消息。（参见 [ip_rt_redirect](#ip_rt_redirect) 及其调用者。）|
	| RTCF_TPROXY| 没有使用。|
	| RTCF_FAST|没有使用。|
	| RTCF_MASQ|没有使用。|
	| RTCF_SNAT|没有使用。|
	| RTCF_DOREDIRECT | 当 ICMP_REDIRECT 消息必须被送回源地址时，该标识由 ip_route_input_slow 设置。ip_forward 基于此标识和其它信息，决定是否真正送 ICMP 重定向消息。|
	| RTCF_DIRECTSRC | 该标识主要用于通知 ICMP 代码，不应当响应地址掩码请求消息。每次调用 fib_validate_source 检查到接收封包的源地址通过一个本地 scope（RT_SCOPE_HOST）的下一跳时可达的，就设置该标识。|
	| RTCF_DNAT | 该功能已经被删除。|
	| RTCF_BROADCAST | 路由的目的地址是一个广播地址。|
	| RTCF_MULTICAST | 路由的目的地址是一个多播地址。|
	| RTCF_REJECT | 没有使用。|
	| RTCF_LOCAL | 路由的目的地址是一个本地地址（即本地接口上配置的某个地址）。对本地广播地址和多播地址也设置该标识\
	（参见 [ip_route_input_mc](#ip_route_input_mc)）。|
	| RTCF_NAT | RTCF_DNAT\|RTCF_SNAT |


4. \_\_u16 rt_type

	路由类型。它间接定义了当路由器查找匹配时应采取的动作。该字段可能的取值在 include/uapi/linux/rtnetlink.h 文件中定义了 RTN_XXX 宏，表 7.12 列出了这些值。

	Table 7.12 Possible values for rt_type

	| 值 | 描述 |
	|:-----|:--------------------------------------------------------------|
	| RTN_UNSPEC | 定义一个未初始化的值。例如，当从路由表中删除一个表项时使用该值，这是因为删除操作不需要制定路由表项的类型。|
	| RTN_UNICAST | 该路由是一个直接或间接（通过一个网关）的单播地址路由。当用户通过 ip route 命令添加路由但没有指定其它路由类型时，路由类型默认被设置为 RTN_UNICAST。|
	| RTN_LOCAL | 目的地址是一个配置在本地接口上的地址。|
	| RTN_BROADCAST | 目的地址是一个广播地址。匹配的入口封包以广播方式发往本地，并且匹配的出口封包以广播形式发送出去。|
	| RTN_ANYCAST | 匹配的入口封包以广播形式送往本地，匹配的出口封包以单播形式发送出去。IPv4 不使用。|
	| RTN_MULTICAST | 目的地址是一个多播地址。|
	| RTN_BLACKHOLE | 丢弃。|
	| RTN_UNREACHABLE | 目标不可达。|
	| RTN_PROHIBIT | 管理员禁止。|
	| RTN_THROW | 不在这张表中。|
	| RTN_NAT | 转换这个地址。
	| RTN_XRESOLVE | 由一个外部解析器来处理该路由。|

5. \_\_u8 rt_is_input

6. \_\_u8 rt_uses_gateway

	当目的主机直连时（即在同一链路上），该字段匹配目的地址。当需要通过一个网关到达目的地址时，该字段设备为被路由识别的下一跳网关。

7. int rt_iif

	入口设备标识符。该值是从入口设备的 net_device 数据结构中取出。对本地产生的流量（因此不是从任何接口上接收到的），该字段被设置成流程设备的 ifindex 字段。

8. \_\_be32 rt_gateway

9. u32 rt_pmtu

10. u32 rt_table_id

11. struct list_head rt_uncached

12. struct uncached_list \*rt_uncached_list

## dst_entry

该结构用于存储缓存路由项中独立于协议的信息。L3 层协议在单独的结构中存储本协议更多的私有信息（例如，IPv4 使用 rtable 结构）。下面逐一介绍该结构的字段：

1. struct rcu_head rcu_head

	处理互斥。

2. struct dst_entry \*child

	IPsec 代码使用该字段。

3. struct net_device \*dev

	出口设备（即将封包送达目的地的发送设备）。

4. struct  dst_ops \*ops

	用于处理 dst_entry 结构的 VFT。

5. unsigned long \_metrics

6. unsigned long  expires

	表示该表项将过期的时间戳。参见[过期标准](#过期标准)一节。

7. struct dst_entry \*path

	IPsec 代码使用该字段。

8. struct dst_entry \*from

\#ifdef CONFIG_XFRM

9. struct xfrm_state \*xfrm

	IPsec 代码使用该字段。

\#else

10. void \*\_\_pad1

\#endif

11. int (\*input)(struct sk_buff \*)

	处理入口封包的函数，参见[缓存查找](#缓存查找)一节。

12. int (\*output)(struct net \*net, struct sock \*sk, struct sk_buff \*skb)

	处理出口封包的函数，参见[缓存查找](#缓存查找)一节。

13. unsigned short flags

	标识集合。DST_HOST 被 TCP 使用。表示主机路由（即它不是到网络或到一个广播/多播地址的路由）。DST_NOXFRM、DST_NOPOLICY 和 DST_NOHASH 只用于 IPsec。

14. \#define DST_HOST 0x0001

	表示该路由是一个主机路由，即它不是到网络或者到广播/多播地址的路由。

15. \#define DST_NOXFRM 0x0002

	只用于 IPsec。

16. \#define DST_NOPOLICY 0x0004

	只用于 IPsec。

17. \#define DST_NOHASH 0x0008

	只用于 IPsec。

18. \#define DST_NOCACHE 0x0010

19. \#define DST_NOCOUNT 0x0020

20. \#define DST_FAKE_RTABLE 0x0040

21. \#define DST_XFRM_TUNNEL 0x0080

22. \#define DST_XFRM_QUEUE 0x0100

23. \#define DST_METADATA 0x0200

24. short error

	当 fib_lookup API（只被 IPv4 使用）失败时，错误值（正值）被保存在该字段中，又后面的 ip_error 使用该值来决定如何处理本次路由查找失败（即决定产生哪一类 ICMP 消息）。

25. short obsolete

	用于定义 dst_entry 实例的可用状态：0（默认值，下面的 DST_OBSOLETE_NONE）表示该结构有效而且可以被使用，2（下面的 DST_OBSOLETE_DEAD）表示该结构将被删除因而不能被使用，-1（下面的 DST_OBSOLETE_DEAD）被 IPsec 和 IPv6 使用但不被 IPv4 使用。

26. \#define DST_OBSOLETE_NONE 0

	表示该结构有效而且可以被使用。

27. \#define DST_OBSOLETE_DEAD 2

	表示该结构被删除因而不能被使用。

28. \#define DST_OBSOLETE_FORCE_CHK -1

	表示该结构被 IPsec 和 IPv6 使用但不被 IPv4 使用。

29. \#define DST_OBSOLETE_KILL -2

30. unsigned short header_len

	IPsec 代码使用该字段。

31. unsigned short trailer_len

	IPsec 代码使用该字段。

32. unsigned short \_\_pad3

\#ifdef CONFIG_IP_ROUTE_CLASSID

33. \_\_u32 tclassid

	基于路由表的分类器的标识。参见[策略路由和基于路由表的分类器](#策略路由和基于路由表的分类器)一节。

\#else

34. \_\_u32 \_\_pad2

\#endif

\#ifdef CONFIG_64BIT

35. long \_\_pad_to_align_refcnt[2]

\#endif

36. atomic_t \_\_refcnt

	引用计数。参见[删除 DST 表项](#删除DST表项)一节。

37. int \_\_use

	该表项已经被使用的次数（即缓存查找返回该表项的次数）。

38. unsigned long lastuse

	用于记录该表项上次被使用的时间戳。当缓存查找成功时更新该时间戳。垃圾回收函数使用该时间戳来选择最合适被释放的结构。

39. struct lwtunnel_state   \*lwtstate

union {

40. struct dst_entry \*next

	用于将分布在同一个 hash 表的 bucket 中具有冲突的 dst_entry 实例链接在一起。参见图 4.1。

41. struct rtable \_\_rcu \*rt_next

42. struct rt6_info \*rt6_next

43. struct dn_route \_\_rcu \*dn_next

}


## dst_ops

dst_ops 结构时独立于协议的缓存与使用 L3 层协议路由缓存之间的接口。参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。下面逐一描述该结构的字段：

1. unsigned short family

	地址簇。参见 include/linux/socket.h 文件中的 AF_XXX。

2. unsigned int gc_thresh

	该字段用于垃圾回收算法，指定了路由缓存的大小（即 bucket 的数目）。其初始化是由 ip_rt_init（IPv4 路由子系统初始化函数）完成的。

3. int (\*gc)(struct dst_ops \*ops)

	当协议已经分配的 dst_entry 实例数目大于或等于门限值 gc_thresh 时，dst_alloc 函数启动垃圾回收函数 gc。

4. struct dst_entry \* (\*check)(struct dst_entry \*, \_\_u32 cookie)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

5. unsigned int (\*default_advmss)(const struct dst_entry \*)

6. unsigned int (\*mtu)(const struct dst_entry \*)

7. u32 \* (\*cow_metrics)(struct dst_entry \*, unsigned long)

8. void (\*destroy)(struct dst_entry \*)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

9. void (\*ifdown)(struct dst_entry \*, struct net_device \*dev, int how)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

10. struct dst_entry \* (\*negative_advice)(struct dst_entry \*)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

11. void (\*link_failure)(struct sk_buff \*)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

12. void (\*update_pmtu)(struct dst_entry \*dst, struct sock \*sk, struct sk_buff \*skb, u32 mtu)

	参见 [DST 与调用协议间的接口](#DST与调用协议间的接口)一节。

13. void (\*redirect)(struct dst_entry \*dst, struct sock \*sk, struct sk_buff \*skb)

14. in (\*local_out)(struct net \*net, struct sock \*sk, struct sk_buff \*skb)

15. struct neighbour \* (\*neigh_lookup)(const struct dst_entry \*dst, struct sk_buff \*skb, const void \*daddr)

16. void (\*confirm_neigh)(const struct dst_entry \*dst, const void \*daddr)

17. struct kmem_cache \*kmem_cachep

	分配路由缓存元素的内存池。

18. struct percpu_counter pcpuc_entries \_\_\_\_cacheline_aligned_in_smp


## flowi

使用 flowi 数据结构，可以根据入口设备和出口设备，L3 和 L4 层协议报头中的参数等字段的组合对流量进行分类。它通常被用作路由查找的搜索关键字，IPsec 策略的流量选择器及其它高级用途。下面介绍该结构中的字段：

union {

1. struct flowi_common \_\_fl_common
2. struct flowi4 ip4
3. struct flowi6 ip6
4. struct flowidn dn

} u

5. \#define flowi_oif u.\_\_fl_common.flowic_oif

6. \#define flowi_iif u.\_\_fl_common.flowic_iif

7. \#define flowi_mark u.\_\_fl_common.flowic_mark

8. \#define flowi_tos u.\_\_fl_common.flowic_tos

9. \#define flowi_scope u.\_\_fl_common.flowic_scope

10. \#define flowi_proto u.\_\_fl_common.flowic_proto

11. \#define flowi_flags u.\_\_fl_common.flowic_flags

12. \#define flowi_secid u.\_\_fl_common.flowic_secid

13. \#define flowi_tun_key u.\_\_fl_common.flowic_tun_key

14. \#define flowi_uid u.\_\_fl_common.flowic_uid


## flowi_tunnel

1. int flowic_oif

	入口设备标识符。

2. int flowic_iif

	出口设备标识符。

3. \_\_u32 flowic_mark



4. \_\_u8 flowic_tos

5. \_\_u8 flowic_scope

6. \_\_u8 flowic_proto

	L4 层协议。

7. \_\_u8 flowic_flags

	使用 8、9、10 中定义的三个值。

8. \#define FLOWI_FLAG_ANYSRC 0x01

9. \#define FLOWI_FLAG_KNOWN_NH 0x02

10. \#define FLOWI_FLAG_SKIP_NH_OIF 0x04

11. \_\_u32 flowic_secid

12. struct flowi_tunnel flowic_tun_key

13. kuid_t  flowic_uid

## rt_cache_stat

该结构体存储了在[统计数据](统计数据)一节中介绍的统计信息的计数器。下面描述这些计数器：

1. unsigned int in_slow_tot

	该字段是由于缓存查找失败而需要查找路由表的封包数目（参见 [ip_route_input_slow](#ip_route_input_slow)），只对查找路由表成功的封包计数。该计数器被称为慢的是因为查找路由表与查找路由缓存相比非常慢。该计数器也对广播封包计数，但不对多播封包计数。多播封包计数使用下面的 in_slow_mc 变量来计数。

2. unsigned int in_slow_mc

	该字段是由于缓存查找失败而需要查找路由表的封包数目（参见 [ip_route_input_slow](#ip_route_input_slow)），只对查找路由表成功的封包计数。该计数器被称为慢的是因为查找路由表与查找路由缓存相比非常慢。该计数器只对多播封包计数。单播和广播封包计数使用上面的 in_slow_tot 变量来计数。

3. unsigned int in_no_route

	由于路由表不知道如何到达目的 IP 地址（只可能发生在默认网关没有配置或不可用的情况下）而不能被转发的入口封包的数目。参见 [ip_route_input_slow](#ip_route_input_slow)。没有计数器用于跟踪由于查找路由失败而不能被送出的本地产生的封包的数目。

4. unsigned int in_brd

	被正确接收（合理性检查没有失败）的广播封包的数目。没有计数器用于统计送出的广播封包的数目。

5. unsigned int in_martian_dst

	表示由于目的 IP 地址没有通过合理性检查而被丢弃的封包的数目。合理性检查的范例比如目的地址不能属于所谓的零网段，即地址不能为 0.n.n.n。

6. unsigned int in_martian_src

	表示由于源 IP 地址没有通过合理性检查而被丢弃的封包的数目。合理性检查的范例比如源 IP 地址不能为多播地址或广播地址。

7. unsigned int out_slow_tot

	参见 1 中的介绍，只是该字段用于出口流量的计数。

8. unsigned int out_slow_mc

	参见 2 中的介绍，只是该字段用于出口流量的计数。

