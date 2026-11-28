# 上游 v2.13.0–v2.13.1 移植记录

更新日期：2026-11-28
范围：上游 `iamr0s/Dhizuku` v2.13.0–v2.13.1；基线为 `af20d75`。本 fork 按功能移植，没有直接 merge 上游分支。

## 当前代码状态

- 核心移植已提交并推送至 `origin/main`。
- `89d12fd`：Dhizuku API 与 Shizuku 命令流程安全/稳定性加固。
- `078e58b`：Shizuku 激活恢复与授权前身份验证。
- 截至本文建立时，主线代码为 `078e58b`；本文档是新加的记录，尚未提交。

## 已移植或已有等价实现

### 安全与可靠性

- 通过 Dhizuku API 拦截第三方发起的设备/配置文件所有者变更；默认不允许，并提供设置开关和开启确认。
- 每次按调用 UID 校验客户端签名，不复用服务实例中的旧签名状态。
- 关闭应用备份，并排除凭据存储及设备保护存储中的敏感目录。
- 对 DaemonReceiver 的广播 Action 做白名单校验；Room 插入采用 `REPLACE`；Provider 改用非空检查。
- 补齐 LockTask 状态回调；减少 Koin 日志输出。
- 上游 Android 9+ `grantPermissions` 判断修复在 fork 中已有等价实现，无需重复移植。

### API 与 Shizuku

- Dhizuku Server API 升至 `0.3.0`，HiddenApiBypass 升至 `6.2`。
- 命令控制台的 Shizuku UserService 绑定增加超时和绑定失败处理。
- Android 8.0/8.1 隐藏不支持的所有者转移入口。
- 上游 Android 12+ `user_setup_complete` 激活绕过已移植并加强：仅当原值为 `1` 才临时改值；先写入设备保护存储恢复标记；激活结束后恢复，进程中断后应用启动时重试恢复。
- 上游 Android N 以下的激活反射回退未移植，因为 fork 的 `minSdk` 为 26，相关分支不可达。

### 生物识别授权

- 设置中新增可选的“授权前验证身份”，默认关闭。
- 新的/待人工审批的 Dhizuku API 权限请求，在用户点同意后使用 AndroidX `BiometricPrompt` 验证生物识别或锁屏凭据。
- 已记住的授权仍自动通过，不会每次调用 API 都弹验证。
- 取消、验证失败、超时或运行时没有可用验证方式时拒绝授权。
- 开启设置前检查设备是否具备可用的验证方式；不可用时保持关闭并显示 Prism 提示。
- 授权 Activity 在系统提示出现时不会因 `onPause` 提前拒绝；超时回调和认证提示在完成、切换请求及销毁时清理。
- Android 原生提示目前提供英文和简体中文字符串。

## 有意未合并的上游内容

| 上游内容 | 当前处理与影响 |
| --- | --- |
| 约 32 个 locale 的生物识别标题/副标题和商店 changelog 翻译 | 未补齐；原生系统提示只有英文和简体中文，其他语言可能回退为英文。影响翻译完整度，不影响认证功能。若要完整支持现有所有语言，可单独补资源。 |
| 拨号彩蛋 `*#*#3449858#*#*`（`937b010`） | 有意不加；纯隐藏彩蛋，需要额外接收入口，不属于权限管理必需功能。 |
| KSP `2.3.12 → 2.3.14`、Gradle Wrapper `9.8.0 → 9.9.1` | 暂缓为独立构建维护任务，不与功能移植混在一起。 |
| AGP `9.4.1 → 9.5.3`、Kotlin `2.4.20 → 2.4.21`、Compose 版本更新 | 暂不采用；fork 页面已改用 Flutter/Prism，Compose 工具链升级不带来当前功能收益，需单独做构建兼容验证。 |
| 上游降低 `minSdk 26 → 23` 并加入 core library desugaring | 不采用；当前 fork 使用 API 26+ 的 `DeviceAdminService`。降低最低版本需要替换该架构。 |
| v2.13.1 版本号、Fastlane/商店 changelog | 不照搬；fork 使用独立的 `2.14.0` 版本线和发布说明。 |
| `TERMS.md` 格式调整 | 未同步；仅文档格式，不影响运行行为。 |
| Compose 管理列表/设置页重构、开源许可证页、ClickableSpan 链接组件 | 未照搬；属于上游 Compose UI。需要许可证页面时，应按现有 Flutter/Prism UI 单独实现。 |
| `DaemonService` 常驻通知隐藏/通知内容设置 | 不适用；fork 已采用系统绑定的 `DeviceAdminService`，移除了对应的常驻 Daemon 通知方案。 |
| 上游 `build.yml` / `release.yml` 产物命名调整 | 不适用；fork 使用自有 Flutter 构建工作流。 |
| 部分日志删除、OptIn 标记清理及 lint 清理 | 未整体照搬；属于上游局部整理。fork 保留必要的安全和运行诊断日志。 |

上游其他共享运行依赖已核对：`androidx.annotation`、`core-ktx`、Biometric 和 HiddenApiBypass 等已与所需版本一致；Compose 相关依赖因 Flutter UI 迁移而移除。

## 验证边界

- `flutter analyze`：无问题。
- `scripts/build-release.ps1`：Release 构建成功。
- APK 已安装到 Honor MAA-AN10 并启动；启动检查未发现崩溃。
- 尚未在真实第三方应用的待授权流程中手动完成生物识别，也未在手机上实际执行所有者激活流程；需要对应请求/设备状态才能端到端验证。

## 后续参考

后续同步上游版本时，先确认新的 upstream tag 和 merge-base，再按功能比较。不要把上述“有意未合并”项目当成待清理错误；只有当产品需求改变、增加多语言覆盖、升级构建工具或替换系统服务最低版本时，再单独重新评估。
