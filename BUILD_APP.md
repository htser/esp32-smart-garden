# 不装 Flutter，用 GitHub Actions 在线打包（Android + iOS）

本地没有 Flutter 也能出包：仓库里已经放好 `.github/workflows/flutter-apk.yml`，
推到 GitHub 后它会用 `ubuntu-latest` + 官方 Flutter 稳定版自动编译。

免费额度：
- **公开仓库**：Actions 全免费（含 macOS runner）
- **私有仓库**：每月 2000 分钟；Android 跑 ubuntu 按 1 倍计，iOS 跑 macOS **按 10 倍计**
  （一次 iOS 约 10 分钟 → 消耗 100 分钟额度）

## 产物说明

| 平台 | 产物 | 能不能直接装手机 |
|---|---|---|
| Android | `zhigu-android-apk` → `app-release.apk` | ✅ 能，用正式证书签过名 |
| iOS | `zhigu-ios-unsigned-ipa` → `zhigu-unsigned.ipa` | ❌ **不能**，未签名，只能证明能编过 |

iOS 想装真机必须有 Apple 开发者账号（￥688/年），用账号里的证书 + 描述文件签名才行；
免费的 Apple ID 只能在 Mac 上用 Xcode 直连装、7 天过期。没有账号就只能拿未签名包做编译验证。

## 一次性准备

1. 在 GitHub 上新建一个空仓库（不要勾选 README / .gitignore，避免冲突）。
2. 在项目根目录执行：

```bash
cd /Users/ht/Downloads/smart-garden
git remote add origin https://github.com/<你的用户名>/<仓库名>.git
git push -u origin main
```

> 本地已经 `git init` 并提交好了（53 个文件、424KB；`mobile-app/.dart_tool` 那 190MB 已被
> `.gitignore` 排除，不会上传）。

## 配置 Android 签名（三个 Secret）

证书已经生成好了，在 `android-signing/`（**已被 gitignore，不会上传**）：

| Secret 名称 | 值 |
|---|---|
| `ANDROID_KEY_PEM_B64` | `pbcopy < android-signing/key.pem.b64` 后粘贴 |
| `ANDROID_CERT_PEM_B64` | `pbcopy < android-signing/cert.pem.b64` 后粘贴 |
| `ANDROID_KEYSTORE_PASS` | 见 `android-signing/SECRETS.txt` |

不配也能出包，但会是 debug 签名（只能自己装、不能上架）。配了之后 CI 会用 `apksigner` 重新签成正式包。

> 这套密钥丢了，以后就没法给已安装的用户发更新了，**务必自己备份 `android-signing/` 目录**。

## 以后每次打包

1. 改完代码 `git add -A && git commit -m "xxx" && git push`
2. 打开仓库 → **Actions** → 左侧 `Build Flutter APK` → 最新一次运行
3. 跑完在页面底部 **Artifacts** 下载 `zhigu-app-apk.zip` → 解压得 `app-release.apk` → 装到手机

> 也可以不改代码直接点 **Run workflow** 手动触发。

## Workflow 里已经处理掉的坑

| 坑 | 处理 |
|---|---|
| 仓库里没有 `android/` 目录 | 先用 `flutter create --platforms=android` 生成 |
| Android 9+ 禁止明文 HTTP，连 `http://39.105.145.255:18000` 会直接失败 | 打包前给 `AndroidManifest.xml` 注入 `android:usesCleartextTraffic="true"` |
| 后端地址是写死在编译期的 | 用 `--dart-define=API_BASE/WS_BASE` 注入 |
| `firebase_*`、`flutter_blue_plus` 代码里没用到，却要 google-services.json / 蓝牙权限 | 已在 `pubspec.yaml` 里注释掉 |

## 注意事项

- 用的是 **debug 签名**（没有配置 keystore），能装能跑，但上应用商店前要换成自己的签名。
- 生成的 APK 支持全架构（约 20MB）。想要更小可以改成
  `flutter build apk --release --split-per-abi`，产物是 3 个分架构 APK。
- 后端现在是明文 HTTP。等要正式对外，建议在服务器上用 nginx + Let's Encrypt 上 HTTPS，
  然后把 `API_BASE/WS_BASE` 换成 `https://` / `wss://`，并去掉 `usesCleartextTraffic`。
- iOS 包需要 macOS runner（免费额度按 10 倍计费），暂时只出 Android。

## 备选服务

| 服务 | 说明 |
|---|---|
| **Codemagic** | 专门给 Flutter 的，免费 500 分钟/月，网页里选仓库即可，同样需要 git 仓库 |
| **Appcircle** | 有网页版构建，免费额度较小 |
| **Gitee Go** | 国内访问快，配置比 GitHub Actions 繁琐一些 |

三个都要「代码在 git 仓库里」，所以还是先推仓库最省事。
