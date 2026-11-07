@echo off
chcp 65001 >nul
echo ========================================
echo 推送Skyward修改到GitHub
echo ========================================
echo.

REM 切换到脚本所在目录
cd /d "%~dp0"

REM 检查git状态
echo [1/4] 检查git仓库...
git status >nul 2>&1
if errorlevel 1 (
    echo 错误: 当前目录不是git仓库
    pause
    exit /b 1
)

echo 已检测到Git仓库
echo.

REM 显示当前分支
echo [2/4] 当前分支:
git branch --show-current
echo.

REM 提示输入GitHub用户名
set /p GITHUB_USER="请输入你的GitHub用户名: "
if "%GITHUB_USER%"=="" (
    echo 用户名不能为空
    pause
    exit /b 1
)

echo.
echo [3/4] 添加远程仓库...
git remote add my-fork https://github.com/%GITHUB_USER%/skyward.git 2>nul
if errorlevel 1 (
    echo 远程仓库已存在，更新URL...
    git remote set-url my-fork https://github.com/%GITHUB_USER%/skyward.git
)
echo 远程仓库: https://github.com/%GITHUB_USER%/skyward
echo.

REM 推送
echo [4/4] 推送到GitHub...
echo.
echo 正在推送 piano-touch-remap 分支...
git push my-fork piano-touch-remap

if errorlevel 1 (
    echo.
    echo 推送失败！
    echo.
    echo 可能的原因：
    echo 1. 你还没有Fork原始仓库
    echo 2. 需要先访问 https://github.com/kirklin/skyward 点击Fork按钮
    echo 3. 或者需要GitHub身份验证
    echo.
    pause
    exit /b 1
)

echo.
echo ========================================
echo 推送成功！
echo ========================================
echo.
echo 下一步：
echo 1. 访问 https://github.com/%GITHUB_USER%/skyward
echo 2. 选择 piano-touch-remap 分支
echo 3. 点击 Code 按钮 然后 Codespaces 然后 Create codespace
echo 4. 在Codespaces终端运行: bash codespaces-setup.sh
echo.
pause
