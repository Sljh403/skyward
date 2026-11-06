#!/bin/bash
# GitHub Codespaces - Skyward Recovery 编译脚本
# 在Codespaces中运行此脚本一键完成编译

set -e  # 遇到错误立即退出

echo "=========================================="
echo "Skyward Recovery 编译脚本"
echo "=========================================="
echo ""

# 1. 安装依赖
echo "[1/6] 安装系统依赖..."
sudo apt-get update -qq
sudo apt-get install -y protobuf-compiler

# 2. 安装Rust
echo "[2/6] 安装Rust工具链..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source $HOME/.cargo/env
else
    echo "Rust已安装，跳过"
fi

# 添加Android目标
echo "[3/6] 添加Android编译目标..."
rustup target add aarch64-linux-android

# 3. 安装cargo-ndk
echo "[4/6] 安装cargo-ndk..."
if ! command -v cargo-ndk &> /dev/null; then
    cargo install cargo-ndk
else
    echo "cargo-ndk已安装，跳过"
fi

# 4. 下载Android NDK
echo "[5/6] 下载Android NDK r25c..."
NDK_VERSION="r25c"
NDK_DIR="android-ndk-${NDK_VERSION}"
NDK_ZIP="${NDK_DIR}-linux.zip"

if [ ! -d "$NDK_DIR" ]; then
    if [ ! -f "$NDK_ZIP" ]; then
        echo "下载NDK (约1GB)，请耐心等待..."
        wget -q --show-progress https://dl.google.com/android/repository/${NDK_ZIP}
    fi
    echo "解压NDK..."
    unzip -q ${NDK_ZIP}
else
    echo "NDK已存在，跳过下载"
fi

export ANDROID_NDK_HOME="$PWD/$NDK_DIR"
echo "ANDROID_NDK_HOME=$ANDROID_NDK_HOME"

# 5. 编译Skyward Recovery
echo "[6/6] 编译Skyward Recovery..."
echo "预计需要30分钟（首次编译）..."
echo ""

# 确保在正确的目录
if [ ! -f "Cargo.toml" ]; then
    echo "错误: 未找到Cargo.toml，请确保在skyward项目根目录运行此脚本"
    exit 1
fi

# 编译
cargo ndk -t arm64-v8a --platform 30 build --locked --release -p skyward

# 6. 检查结果
echo ""
echo "=========================================="
echo "编译完成！"
echo "=========================================="
echo ""

BINARY_PATH="target/aarch64-linux-android/release/skyward"
if [ -f "$BINARY_PATH" ]; then
    ls -lh "$BINARY_PATH"
    echo ""
    echo "✅ 编译成功！"
    echo "二进制文件位置: $BINARY_PATH"
    echo ""
    echo "下载命令（在Codespaces中）:"
    echo "  点击左侧资源管理器 → 右键 $BINARY_PATH → Download"
    echo ""
    echo "或使用GitHub CLI下载（需要在本地运行）:"
    echo "  gh codespace cp remote:$BINARY_PATH ./skyward"
else
    echo "❌ 编译失败: 未找到输出文件"
    exit 1
fi
