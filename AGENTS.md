# 本机 Android 构建

- 本机 SDK 路径保存在根目录被 Git 忽略的 `local.properties`，不要把真实机器路径写进受版本控制的文件。
- Release 构建统一运行 `.\scripts\build-release.ps1`；脚本会加载 SDK/JDK/Flutter 路径，检查 Gradle 锁定的 NDK，并设置当前进程的环境变量。
- 新机器从 `local.properties.example` 复制配置；Flutter 模块的 `.android/local.properties` 缺失或路径不匹配时，先在 `flutter_ui` 运行 `flutter pub get`。

# 上游同步记录

- 处理 Dhizuku 上游版本同步或评估已有移植时，先阅读 `docs/UPSTREAM_MERGE_STATUS_2.13.md`，以其中的完成项和有意跳过项为起点，再核对最新代码状态；不要重复移植已完成内容，也不要把已记录的有意跳过项当成遗漏。
