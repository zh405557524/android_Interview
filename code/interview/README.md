# 剧说 Flutter 工程说明

> 更新时间：2026-05-25
> 当前阶段：Flutter 前端编码已完成 T-F001 至 T-F019；生成流程已收口为快速批量生成 quick batch
> 当前包名：`com.lxwx.narrate`
> 当前策略：前端先行，默认使用 mock；真实后端接口、支付 / 短信 / 一键登录 / 视频 / 对象存储等业务 SDK 待确定

## 1. 工程定位

剧说是一个面向视频解说创作的 Flutter App。当前工程已经完成前端主链路、页面结构、Controller 级 mock / real 分支、业务模型和基础状态体系，可以在 mock 模式下跑通主要功能。

当前工程不包含未确定业务 SDK。页面层不直接写接口路径；Controller 在 mock 模式下调用私有 mock 方法，在 real 模式下调用 `lib/apis/` 的静态真实接口方法。生成流程只保留 quick batch：创建批次、上传多个视频、全部完成后自动生成一个作品。

当前应用包名 / Bundle Identifier 已统一为 `com.lxwx.narrate`：

- Android `namespace`：`com.lxwx.narrate`
- Android `applicationId`：`com.lxwx.narrate`
- Android `MainActivity` package：`com.lxwx.narrate`
- iOS Runner `PRODUCT_BUNDLE_IDENTIFIER`：`com.lxwx.narrate`

## 2. 工程目录结构

```text
narrate/
├── .cursor/rules/              # Flutter 工程内项目规则，后续编码以这里为准
├── android/                    # Android 工程
├── ios/                        # iOS 工程
├── lib/
│   ├── main.dart               # App 入口
│   ├── global.dart             # 全局依赖初始化
│   ├── theme.dart              # 全局主题
│   ├── apis/                   # 真实接口静态 API 与响应解析
│   │   ├── auth.dart
│   │   ├── home.dart
│   │   ├── user.dart
│   │   ├── creation.dart
│   │   ├── works.dart
│   │   ├── payment.dart
│   │   ├── points.dart
│   │   ├── quick_generation.dart
│   │   ├── invite.dart
│   │   ├── feedback.dart
│   │   ├── helpers.dart
│   │   └── config.dart
│   ├── models/                 # 领域模型、请求参数、通用响应
│   │   ├── data/
│   │   ├── params/
│   │   └── responses/
│   ├── enums/                  # API 错误、业务枚举、ViewState
│   ├── services/               # HttpService、MockService、Storage、Event
│   ├── store/                  # ConfigStore、UserStore、CreationStore
│   ├── routes/                 # go_router 路由、路由名、observer、转场
│   ├── widgets/                # 通用 UI：Scaffold、Toast、状态组件、按钮
│   ├── utils/                  # 常量、资源、格式化、校验、日志
│   ├── components/             # 预留组件聚合入口
│   ├── plugins/                # 预留插件聚合入口
│   └── pages/
│       ├── main/               # 主框架：tab 容器与底部导航
│       ├── home/               # 创作首页
│       ├── auth/               # 登录：一键登录、短信验证码登录
│       ├── account/            # 我的页
│       ├── creation/           # 创作页
│       │   └── dialog/         # 创作相关弹层
│       ├── works/              # 作品列表
│       │   └── detail/         # 作品详情
│       ├── membership/         # VIP 会员
│       ├── points/             # 积分模块
│       │   ├── recharge/       # 积分充值
│       │   └── ledger/         # 积分明细
│       ├── invite/             # 邀请好友
│       ├── settings/           # 更多设置
│       ├── feedback/           # 意见反馈
│       └── webview/            # 协议 / 隐私等静态内容页
├── test/
│   ├── controller_api_test.dart # Controller mock / real 分支与校验器测试
│   └── widget_test.dart        # App smoke test
├── assets/
│   ├── images/                 # Figma 图片资源，含 1x / 2.0x / 3.0x
│   ├── launcher/               # 启动图 / launcher 相关资源
│   └── midi/                   # 预留音频 / midi 资源目录
└── pubspec.yaml                # Flutter 依赖配置
```

页面模块遵循标准结构：

```text
lib/pages/{feature_name}/
├── index.dart
├── controller.dart
└── view.dart
```

只有真实存在弹层、组件或子功能时，才创建 `dialog/`、`widgets/` 或 `{sub_feature}/`。

## 3. 已实现业务功能

| 模块 | 当前能力 | 状态 |
|------|----------|------|
| 工程骨架 | 工程内 `.cursor/rules/`、基础依赖、主题、路由、服务、Store、通用组件 | done |
| API 基础设施 | 静态真实 API、Controller 级 mock / real 分支、`HttpService.to`、统一响应和错误转换 | done |
| 登录 | 一键登录、短信验证码登录、协议勾选、验证码倒计时、登录态写入 | done |
| 首页 / 主框架 | `HomePage` 独立页面、创作 / 作品 / 我的三 tab、热门案例、积分与会员入口、创建项目入口 | done |
| 我的页 | 用户信息、邀请码复制、VIP / 积分 / 邀请 / 反馈 / 设置入口 | done |
| 创作流程 | 多视频选择、快速批量生成、上传前积分确认、风格选择、配音角色、语速、更多设置 | done |
| 创作弹层 | 选择视频、删除确认、积分确认、权益不足、风格、配音、更多设置 | done |
| 作品模块 | 作品空态、作品列表、分类筛选、作品详情、状态提示、下载占位 | done |
| 会员与积分 | VIP 套餐、积分充值、积分流水、协议勾选、支付提交占位 | done |
| 邀请好友 | 邀请码、复制、分享占位、邀请规则、累计奖励、邀请记录 / 空态 | done |
| 更多设置 | 用户协议、隐私政策、版本号、清理缓存、退出登录、注销账号占位 | done |
| 意见反馈 | 类型选择、内容输入、联系方式、附件占位、提交状态、失败保留输入 | done |
| 静态内容 | 协议 / 隐私等静态页面，Controller 在 mock / real 间切换内容来源 | done |
| 状态与异常 | loading、empty、error、disabled、submitting、not_found、keyed mock 空态 / 失败 | done |
| Figma 图片资源 | 已接入本地 `assets/images/`，首页背景、底部导航、积分、创建、作品播放图标按 Figma 命名使用 | done |

## 4. 开发进度

| 任务 | 名称 | 状态 | 说明 |
|------|------|------|------|
| T-F001 | 工程骨架 | done | 已完成工程规则、依赖、基础分层、路由和通用能力 |
| T-F002 | 登录模块 | done | 已完成一键登录和验证码登录前端流程 |
| T-F003 | 主框架与首页 | done | 已完成底部导航、创作首页和热门案例 |
| T-F004 | 创作页 | done | 已完成默认态、已选视频态和生成入口 |
| T-F005 | 创作弹层 | done | 已完成创作相关弹层和选择结果回填 |
| T-F006 | 作品模块 | done | 已完成作品空态、列表、详情和下载占位 |
| T-F007 | 我的页 | done | 已完成账号、邀请码、积分、VIP 和二级入口 |
| T-F008 | 会员与积分 | done | 已完成 VIP、积分充值和积分明细 |
| T-F009 | 邀请好友 | done | 已补齐用户确认缺失页 |
| T-F010 | 更多设置 | done | 已补齐用户确认缺失页 |
| T-F011 | 意见反馈 | done | 已补齐用户确认缺失页 |
| T-F012 | 状态与异常补齐 | done | 已补统一状态组件、校验器和 mock 异常开关 |
| T-F013 | 包名配置 | done | Android / iOS 包名已统一为 `com.lxwx.narrate` |
| T-F014 | Figma REST 图标导出 | cancelled | 因 Figma REST API 限流，已撤销 REST 导出方案，不再依赖 REST 批量导出 |
| T-F015 | Scaffold 与 API 规则迁移 | done | `CustomScaffold` 已迁移到新参数；API 改为静态真实请求；mock / real 开关上移到 Controller |
| T-F016 | API 与 Data 注释规则补齐 | done | API 方法和 `models/data/` 类已补业务注释，规则已同步要求后续新增时必须补注释 |
| T-F017 | 首页拆分与图片资源接入 | done | `_HomeTab` 已拆为 `HomePage`，新增 `HomeController`；UI 使用 `AppAssets` 中的 Figma 图片资源 |
| T-F018 | 顶部栏 AppBar 迁移 | done | 有标题 / 返回 / 右侧操作的页面已迁移到 `CustomScaffold.appBar: AppBar(...)`，避免 body 内手写 header 导致顶部挤压 |
| T-F019 | 快速批量生成收口 | done | 前端移除旧素材库 / 草稿 / 单任务生成调用，新增 `QuickGenerationAPI` 和 quick batch data 类 |

## 5. 本地资源

当前已注册 `assets/images/` 本地图片资源，Flutter 会自动按 `2.0x/`、`3.0x/` 目录选择倍率。页面内通过 `AppAssets` 统一引用，不直接散写资源路径。

已接入资源：

- `image_create_bg`
- `icon_add`
- `icon_create_select`
- `icon_integral`
- `icon_mine`
- `icon_works`
- `icon_works_play`

## 6. 待确定 / 待联调事项

| 类型 | 内容 | 当前处理 |
|------|------|----------|
| 后端接口 | quick batch OpenAPI、字段、错误码、分页格式 | 生成流程已切到 `/api/generation/quick-batches`，页面层不写接口路径 |
| 登录 SDK | 运营商一键登录、短信服务供应商 | Flutter 暂不引入 SDK，保留 Controller mock 分支和真实 API 方法 |
| 支付 SDK | 微信支付、支付宝、Apple IAP | 当前为提交占位，真实 SDK 待确定 |
| 视频能力 | 本地视频选择、直传、播放 SDK、保存到相册 | 当前 quick batch 接口已接入；真实本地文件直传待视频选择 / 上传能力接入 |
| 分享能力 | 邀请好友分享 SDK | 当前 toast 占位 |
| 反馈附件 | 图片 / 视频附件上传 | 当前只支持文字反馈，附件入口占位 |
| 注销账号 | 注销协议、冷静期、后端流程 | 当前为 mock 申请 |

## 7. 验证记录

最近一次验证：

```bash
flutter pub get
flutter analyze
flutter test
```

结果：

- `flutter pub get`：通过，图片资源注册后依赖正常
- `flutter analyze`：No issues found
- `flutter test`：All tests passed，当前 20 个测试通过

后续每完成一个 Flutter 模块或关键修复，需要同步更新本 README 的“开发进度”和“待确定 / 待联调事项”，方便直接从工程根目录了解当前状态。
