#!/bin/bash

# 漫剧工坊（narrate）本地编译 iOS（Release）并安装到已连接的 iPhone（ideviceinstaller）
# 流程：flutter build ios --no-codesign → xcodebuild archive/export(development) → ideviceinstaller
#
# 依赖: Flutter、Xcode、本机已登录开发者账号与证书；brew install ideviceinstaller libimobiledevice
#
# 用法:
#   ./make_ios.sh              # 默认：pub get → build → 导出 IPA → 安装
#   ./make_ios.sh clean        # 先 flutter clean
#   DEVICE_UDID=<udid> ./make_ios.sh   # 多台连接时必须指定（idevice_id -l）
#   SKIP_UNINSTALL=1 ./make_ios.sh     # 不先卸载旧包（若与手动 install 行为不一致可先试此项）
#   IOS_IPA_PATH=/abs/xxx.ipa ./make_ios.sh  # 直接装指定 ipa（不依赖本脚本解析路径）
#
# 若「脚本没报错但手机没有 App」：多台设备时务必设 DEVICE_UDID；手机点「信任此电脑」；
#   brew upgrade libimobiledevice ideviceinstaller；或在 Xcode 里 Run 一次确认描述文件含该设备。

set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

APP_NAME="漫剧工坊"
IOS_BUNDLE_ID="com.lxwx.narrate"
# Xcode 导出多为 Runner.ipa，统一复制为此名，与手动安装路径一致：
#   ideviceinstaller install .../build/ios/ipa/narrate.ipa
IPA_INSTALL_NAME="narrate.ipa"
IPA_GLOB="build/ios/ipa/*.ipa"
RUNNER_APP_PATH="build/ios/iphoneos/Runner.app"

get_version_info() {
    local VERSION_LINE
    VERSION_LINE=$(grep "^version:" pubspec.yaml)
    VERSION=$(echo "$VERSION_LINE" | cut -d' ' -f2 | cut -d'+' -f1)
    BUILD_NUMBER=$(echo "$VERSION_LINE" | cut -d'+' -f2)
    echo -e "${BLUE}当前版本: $VERSION, 构建号: $BUILD_NUMBER${NC}"
}

check_requirements() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}错误: 仅支持在 macOS 上构建 iOS${NC}"
        exit 1
    fi
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}错误: 未找到 flutter${NC}"
        exit 1
    fi
    if ! command -v xcodebuild &> /dev/null; then
        echo -e "${RED}错误: 未找到 xcodebuild${NC}"
        exit 1
    fi
    if ! command -v ideviceinstaller &> /dev/null; then
        echo -e "${RED}错误: 未找到 ideviceinstaller${NC}"
        echo -e "${YELLOW}安装: brew install ideviceinstaller libimobiledevice${NC}"
        exit 1
    fi
    echo -e "${GREEN}工具检查通过${NC}"
}

list_devices() {
    echo -e "${BLUE}已连接设备 (idevice_id -l):${NC}"
    if command -v idevice_id &> /dev/null; then
        idevice_id -l || true
    else
        echo -e "${YELLOW}未找到 idevice_id，可用 brew install libimobiledevice${NC}"
    fi
}

# 统计当前 USB 连接的设备数
count_usb_devices() {
    if ! command -v idevice_id &> /dev/null; then
        echo 0
        return
    fi
    idevice_id -l 2>/dev/null | wc -l | tr -d '[:space:]'
}

build_flutter_unsigned() {
    echo -e "${BLUE}flutter build ios --release --no-codesign ...${NC}"
    flutter build ios --release --no-codesign
}

archive_and_export_development() {
    mkdir -p build/ios/ipa

    local cert_info
    cert_info=$(security find-identity -v -p codesigning | grep "iPhone Developer\|iPhone Distribution\|Apple Development\|Apple Distribution" | head -1 || true)
    if [ -z "$cert_info" ]; then
        echo -e "${RED}未找到可用的 iOS 代码签名证书${NC}"
        exit 1
    fi

    local cert_name team_id
    cert_name=$(echo "$cert_info" | sed 's/.*) //g' | sed 's/"//g')
    echo -e "${GREEN}使用证书: $cert_name${NC}"

    team_id=$(security find-certificate -c "$cert_name" -p 2>/dev/null | openssl x509 -text -noout 2>/dev/null | grep "OU=" | head -1 | sed 's/.*OU=\([^,]*\).*/\1/' | tr -d ' ' || true)
    if [ -z "$team_id" ]; then
        team_id=$(grep -o 'DEVELOPMENT_TEAM = [^;]*' ios/Runner.xcodeproj/project.pbxproj | head -1 | sed 's/DEVELOPMENT_TEAM = //g' | tr -d ';"' || true)
    fi
    if [ -z "$team_id" ]; then
        echo -e "${YELLOW}警告: 未能解析 Team ID，Export 可能失败，请在 Xcode 中检查 Signing${NC}"
    else
        echo -e "${GREEN}Team ID: $team_id${NC}"
    fi

    local export_options="build/ios/ipa/ExportOptions.plist"
    cat > "$export_options" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>$team_id</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

    local archive_path="build/ios/ipa/Runner_local.xcarchive"
    rm -rf "$archive_path"

    echo -e "${BLUE}xcodebuild archive ...${NC}"
    xcodebuild -workspace ios/Runner.xcworkspace \
        -scheme Runner \
        -configuration "Release" \
        -archivePath "$archive_path" \
        -allowProvisioningUpdates \
        archive

    echo -e "${BLUE}xcodebuild -exportArchive (development) ...${NC}"
    xcodebuild -exportArchive \
        -archivePath "$archive_path" \
        -exportPath "build/ios/ipa" \
        -exportOptionsPlist "$export_options" \
        -allowProvisioningUpdates

    normalize_exported_ipa_name
}

# 导出目录里通常只有 Runner.ipa（或一个 *.ipa），复制为 narrate.ipa 固定安装路径
normalize_exported_ipa_name() {
    local dest="build/ios/ipa/$IPA_INSTALL_NAME"
    shopt -s nullglob
    local ipas=(build/ios/ipa/*.ipa)
    shopt -u nullglob
    if [ ${#ipas[@]} -eq 0 ]; then
        echo -e "${RED}导出后未找到任何 .ipa${NC}"
        exit 1
    fi
    if [ ${#ipas[@]} -eq 1 ]; then
        cp -f "${ipas[0]}" "$dest"
        echo -e "${GREEN}安装包: $SCRIPT_ROOT/$dest（来自 ${ipas[0]##*/}）${NC}"
    else
        echo -e "${YELLOW}目录内有多个 ipa，请检查 build/ios/ipa；将尝试使用已有 $dest 或 Runner.ipa${NC}"
        if [ ! -f "$dest" ]; then
            cp -f "build/ios/ipa/Runner.ipa" "$dest" 2>/dev/null \
                || cp -f "${ipas[0]}" "$dest"
        fi
    fi
}

resolve_ipa_path() {
    if [ -n "${IOS_IPA_PATH:-}" ]; then
        echo "$IOS_IPA_PATH"
        return
    fi
    local dest="$SCRIPT_ROOT/build/ios/ipa/$IPA_INSTALL_NAME"
    if [ -f "$dest" ]; then
        echo "$dest"
        return
    fi
    local runner_ipa="$SCRIPT_ROOT/build/ios/ipa/Runner.ipa"
    if [ -f "$runner_ipa" ]; then
        echo "$runner_ipa"
        return
    fi
    local f
    f=$(ls "$SCRIPT_ROOT"/build/ios/ipa/*.ipa 2>/dev/null | head -n 1 || true)
    if [ -n "$f" ]; then
        echo "$f"
        return
    fi
    echo ""
}

install_ipa() {
    local ipa_file
    ipa_file="$(resolve_ipa_path)"
    if [ -z "$ipa_file" ] || [ ! -f "$ipa_file" ]; then
        echo -e "${RED}未找到 IPA（可先 export IOS_IPA_PATH=绝对路径）${NC}"
        exit 1
    fi

    # 绝对路径
    ipa_file="$(cd "$(dirname "$ipa_file")" && pwd)/$(basename "$ipa_file")"

    echo -e "${GREEN}IPA: $ipa_file${NC}"
    list_devices

    local n_dev
    n_dev=$(count_usb_devices | tr -d '[:space:]')
    if [ "${n_dev:-0}" -eq 0 ]; then
        echo -e "${RED}未检测到 USB 设备。请连接 iPhone、解锁并点「信任」后重试。${NC}"
        exit 1
    fi

    local udid_arg=()
    if [ -n "${DEVICE_UDID:-}" ]; then
        udid_arg=( -u "$DEVICE_UDID" )
        echo -e "${BLUE}安装目标 UDID: $DEVICE_UDID${NC}"
    elif [ "${n_dev:-0}" -gt 1 ]; then
        echo -e "${RED}检测到多台设备 ($n_dev)，请指定一台后再装，例如:${NC}"
        echo -e "${YELLOW}  DEVICE_UDID=\$(idevice_id -l | head -1) $0${NC}"
        exit 1
    fi

    # 先卸再装，避免「已安装同名 App」导致安装看似成功但未更新/未出现
    if [ -z "${SKIP_UNINSTALL:-}" ]; then
        echo -e "${BLUE}卸载旧包 (若存在): $IOS_BUNDLE_ID${NC}"
        ideviceinstaller "${udid_arg[@]}" -U "$IOS_BUNDLE_ID" 2>/dev/null || true
    fi

    # 使用子命令 install，与常见用法一致：ideviceinstaller install /path/to.ipa
    echo -e "${BLUE}正在安装: ideviceinstaller install \"$ipa_file\"${NC}"
    if ! ideviceinstaller "${udid_arg[@]}" install "$ipa_file"; then
        echo -e "${RED}ideviceinstaller 安装失败（见上方输出）。可尝试:${NC}"
        echo -e "${YELLOW}  brew upgrade libimobiledevice ideviceinstaller${NC}"
        echo -e "${YELLOW}  或在 Xcode 打开 Runner → 选真机 → Product → Run 验证签名与描述文件${NC}"
        exit 1
    fi

    echo -e "${BLUE}已安装列表中是否包含 $IOS_BUNDLE_ID:${NC}"
    if ideviceinstaller "${udid_arg[@]}" -l 2>/dev/null | grep -q "$IOS_BUNDLE_ID"; then
        echo -e "${GREEN}=== 校验通过: 设备上已列出 $IOS_BUNDLE_ID ===${NC}"
    else
        echo -e "${YELLOW}⚠️ 未在 ideviceinstaller -l 中看到 $IOS_BUNDLE_ID，但安装命令已返回成功。${NC}"
        echo -e "${YELLOW}   请在手机主屏搜索「$APP_NAME」；仍没有则换 USB 口/线或换 Xcode 安装验证。${NC}"
        ideviceinstaller "${udid_arg[@]}" -l 2>/dev/null | tail -n 20 || true
    fi
}

main() {
    echo -e "${BLUE}=== narrate make_ios: 本地构建并安装（ideviceinstaller）===${NC}"

    check_requirements
    get_version_info

    if [ "${1:-}" = "clean" ]; then
        echo -e "${BLUE}flutter clean ...${NC}"
        flutter clean
    fi

    echo -e "${BLUE}flutter pub get ...${NC}"
    flutter pub get

    build_flutter_unsigned

    if [ ! -d "$RUNNER_APP_PATH" ]; then
        echo -e "${RED}未找到 $RUNNER_APP_PATH，flutter 构建可能失败${NC}"
        exit 1
    fi

    # 每次完整导出 IPA，避免沿用过期包
    rm -f build/ios/ipa/*.ipa 2>/dev/null || true
    archive_and_export_development

    install_ipa
}

main "$@"
