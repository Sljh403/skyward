# 使用GitHub Codespaces编译Skyward Recovery - 完整步骤

## 前提条件
- 有GitHub账号
- 已修改的Skyward源代码（在 `skyward-source` 目录）

## 步骤1: 创建GitHub仓库并上传代码

### 选项A: 使用GitHub网页界面

1. 访问 https://github.com/new
2. 仓库名称: `skyward-piano-remix` (或任意名称)
3. 选择 **Private** (私有仓库)
4. 点击 **Create repository**

5. 在你的电脑上，打开Git Bash或PowerShell，进入修改后的源代码目录：
```bash
cd D:/deepseek-harness/default-workspace/skyward-port/skyward-source

# 初始化git仓库（如果还没有）
git init

# 添加所有文件
git add .

# 提交修改
git commit -m "Add remapped_device support for touch coordinate remapping"

# 连接到你的GitHub仓库（替换YOUR_USERNAME）
git remote add origin https://github.com/YOUR_USERNAME/skyward-piano-remix.git

# 推送代码
git branch -M main
git push -u origin main
```

### 选项B: 使用GitHub CLI (如果已安装 `gh`)

```bash
cd D:/deepseek-harness/default-workspace/skyward-port/skyward-source

# 创建仓库并推送
gh repo create skyward-piano-remix --private --source=. --remote=origin --push
```

## 步骤2: 打开GitHub Codespaces

1. 访问你的仓库页面: `https://github.com/YOUR_USERNAME/skyward-piano-remix`
2. 点击绿色的 **Code** 按钮
3. 选择 **Codespaces** 标签
4. 点击 **Create codespace on main**

等待1-2分钟，Codespaces会自动启动一个完整的Ubuntu开发环境。

## 步骤3: 在Codespaces中编译

Codespaces启动后，你会看到一个VSCode界面。

### 方法A: 使用提供的脚本（最简单）

1. 在Codespaces终端中运行：
```bash
# 下载编译脚本
curl -o compile.sh https://raw.githubusercontent.com/YOUR_USERNAME/skyward-piano-remix/main/codespaces-setup.sh

# 赋予执行权限
chmod +x compile.sh

# 运行编译
./compile.sh
```

### 方法B: 手动执行命令

在Codespaces终端中依次运行：

```bash
# 1. 安装依赖
sudo apt-get update
sudo apt-get install -y protobuf-compiler

# 2. 安装Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

# 3. 添加Android编译目标
rustup target add aarch64-linux-android

# 4. 安装cargo-ndk
cargo install cargo-ndk

# 5. 下载Android NDK (约1GB，需要5-10分钟)
wget https://dl.google.com/android/repository/android-ndk-r25c-linux.zip
unzip android-ndk-r25c-linux.zip
export ANDROID_NDK_HOME=$PWD/android-ndk-r25c

# 6. 编译 (约30分钟)
cargo ndk -t arm64-v8a --platform 30 build --locked --release -p skyward

# 7. 检查结果
ls -lh target/aarch64-linux-android/release/skyward
```

## 步骤4: 下载编译好的二进制文件

编译完成后，二进制文件在 `target/aarch64-linux-android/release/skyward`

### 下载方法1: VSCode资源管理器
1. 在左侧文件浏览器中导航到 `target/aarch64-linux-android/release/`
2. 右键点击 `skyward` 文件
3. 选择 **Download**

### 下载方法2: 使用GitHub CLI (在本地电脑运行)
```bash
# 列出你的Codespaces
gh codespace list

# 复制文件（替换CODESPACE_NAME）
gh codespace cp remote:target/aarch64-linux-android/release/skyward ./skyward -c CODESPACE_NAME
```

### 下载方法3: 通过端口转发和HTTP服务
在Codespaces终端中：
```bash
# 启动简单HTTP服务器
cd target/aarch64-linux-android/release
python3 -m http.server 8000
```
然后在浏览器中访问转发的端口，下载 `skyward` 文件。

## 步骤5: 部署到你的设备

下载完成后，将 `skyward` 文件移动到 `D:\deepseek-harness\default-workspace\skyward-port\compiled\` 目录，然后运行：

```bash
cd D:/deepseek-harness/default-workspace/skyward-port

# 快速测试脚本（如果有的话）
python auto_build_and_flash.py --compiled skyward
```

或手动打包：

```bash
# 1. 更新device.toml
# 确保build/device.toml包含:
# [touch]
# remapped_device = "/dev/input/event9"

# 2. 解压现有recovery
magiskboot.exe unpack work/boot.img

# 3. 更新ramdisk
magiskboot.exe cpio work/ramdisk.cpio "add 0755 system/bin/skyward compiled/skyward"
magiskboot.exe cpio work/ramdisk.cpio "add 0755 system/bin/touch_remap github-repo/touch_remap/touch_remap"
magiskboot.exe cpio work/ramdisk.cpio "add 0644 skyward/device.toml build/device.toml"
magiskboot.exe cpio work/ramdisk.cpio "add 0755 skyward/touch-remap.sh skyward/touch-remap.sh"
magiskboot.exe cpio work/ramdisk.cpio "add 0644 system/etc/init/skyward-touch-remap.rc skyward/skyward-touch-remap.rc"

# 4. 重新打包
magiskboot.exe repack work/boot.img work/new-boot.img

# 5. 刷入
adb reboot bootloader
fastboot flash recovery work/new-boot.img
fastboot reboot recovery
```

## 步骤6: 验证

进入Recovery后：
```bash
# 检查touch_remap是否运行
adb shell ps -A | grep touch

# 检查event9
adb shell ls -l /dev/input/event9

# 检查Recovery日志
adb shell dmesg | grep -i "remapped\|skyward"
```

点击屏幕四角和滑动测试触摸是否正常。

## 故障排除

### 编译错误
- 确保所有依赖都已安装
- 检查Rust版本: `rustc --version` (需要 >= 1.70)
- 检查cargo-ndk: `cargo ndk --version`
- 检查NDK环境变量: `echo $ANDROID_NDK_HOME`

### Codespaces超时
- 免费用户每月有120小时Codespaces使用时间
- 如果编译时间过长，可以保存Codespace状态后继续
- 编译产物会保留在Codespace中，即使关闭后重新打开

### 下载慢
- Codespaces在国外，下载速度可能较慢
- 可以考虑使用代理或VPN
- 或者直接在Codespaces中创建tar.gz打包下载

## 注意事项

- **首次编译需要约30分钟**，请耐心等待
- Codespaces会自动保存状态，关闭后可以继续
- 编译产物大小约1-2MB
- 记得关闭不用的Codespace以节省配额

## 快速命令参考

```bash
# 一键编译（如果已上传脚本到仓库）
bash codespaces-setup.sh

# 手动编译
cargo ndk -t arm64-v8a --platform 30 build --locked --release -p skyward

# 检查编译结果
ls -lh target/aarch64-linux-android/release/skyward
file target/aarch64-linux-android/release/skyward
```
