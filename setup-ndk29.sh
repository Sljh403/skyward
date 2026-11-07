#!/bin/bash
set -e

echo "=== Setting up NDK r29 for Skyward compilation ==="

# NDK r29 下载地址
NDK_VERSION="r29"
NDK_BUILD="14206865"
NDK_URL="https://dl.google.com/android/repository/android-ndk-r29-linux.zip"
NDK_DIR="$HOME/android-ndk-r29"

# 检查是否已经安装
if [ -d "$NDK_DIR" ]; then
    echo "NDK r29 already installed at $NDK_DIR"
else
    echo "Downloading NDK r29..."
    cd /tmp
    wget -q --show-progress "$NDK_URL" -O android-ndk-r29-linux.zip
    
    echo "Extracting NDK r29..."
    unzip -q android-ndk-r29-linux.zip
    mv android-ndk-r29 "$NDK_DIR"
    rm android-ndk-r29-linux.zip
    
    echo "✅ NDK r29 installed to $NDK_DIR"
fi

# 设置环境变量
export ANDROID_NDK_HOME="$NDK_DIR"
export NDK_HOME="$NDK_DIR"

# 确保 Rust 环境已加载
source "$HOME/.cargo/env"

# 验证 NDK 版本
echo ""
echo "=== NDK Version Information ==="
cat "$NDK_DIR/source.properties" | grep "Pkg.Revision"

# 编译 Skyward
echo ""
echo "=== Building Skyward with NDK r29 ==="
cd /workspaces/skyward
cargo ndk -t arm64-v8a --platform 30 build --locked --release -p skyward

echo ""
echo "✅ Build complete!"
echo "Binary location: target/aarch64-linux-android/release/skyward"
ls -lh target/aarch64-linux-android/release/skyward

# 验证编译信息
echo ""
echo "=== Binary Information ==="
file target/aarch64-linux-android/release/skyward
