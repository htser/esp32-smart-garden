"""
CI 用：给 flutter create 生成的 android 工程打两个补丁

1. release 构建关闭 lint —— AGP 的 lint 在部分 JDK 上会抛
   `NoSuchMethodError: JavaDocParser.parseDataItem`，和业务代码无关，
   但会让 `flutter build apk --release` 直接失败。
2. Android 9+ 默认禁止明文 HTTP，后端目前是 http://...:18000，
   不开这个开关会直接报 CLEARTEXT communication not permitted。
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
GRADLE = ROOT / "android/app/build.gradle.kts"
MANIFEST = ROOT / "android/app/src/main/AndroidManifest.xml"


def patch_gradle() -> None:
    s = GRADLE.read_text()
    if "checkReleaseBuilds" in s:
        print("gradle: already patched")
        return
    if "android {" not in s:
        sys.exit("gradle: 找不到 android { 块，模板可能变了")
    s = s.replace(
        "android {",
        "android {\n"
        "    lint {\n"
        "        checkReleaseBuilds = false\n"
        "        abortOnError = false\n"
        "    }",
        1,
    )
    GRADLE.write_text(s)
    print("gradle: lint 已关闭")


def patch_manifest() -> None:
    s = MANIFEST.read_text()
    if "usesCleartextTraffic" in s:
        print("manifest: already patched")
        return
    s = s.replace("<application", '<application android:usesCleartextTraffic="true"', 1)
    MANIFEST.write_text(s)
    print("manifest: usesCleartextTraffic 已开启")


if __name__ == "__main__":
    patch_gradle()
    patch_manifest()
