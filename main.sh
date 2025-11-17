#!/bin/bash

# main.sh - Kali Linux 树莓派脚本 
# 作者 lhl77
# GitHub 仓库: https://github.com/lhl77/kali-raspi-tool


set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本版本
SCRIPT_VERSION="v0.2.8"

check_privileges() {
  if [[ $EUID -ne 0 ]] && ! sudo -v &>/dev/null; then
    echo "[-] 错误：此脚本需要 root 权限或有效的 sudo 配置。"
    exit 1
  fi
  if [[ $EUID -ne 0 ]]; then
     echo "[*] 测试 sudo 权限..."
     sudo -l &>/dev/null || { echo "[-] sudo 权限测试失败。"; exit 1; }
     echo "[+] sudo 权限可用。"
  fi
}

# 检查系统版本
check_system_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$NAME" == "Kali GNU/Linux" ]]; then
            SYSTEM_NAME="Kali"
            SYSTEM_VERSION="$VERSION_ID"
            IS_KALI=1
        else
            SYSTEM_NAME="$NAME"
            SYSTEM_VERSION="$VERSION_ID"
            IS_KALI=0
        fi
    elif command -v lsb_release &> /dev/null; then
        if [[ $(lsb_release -i | cut -f2) == "Kali"* ]]; then
            SYSTEM_NAME="Kali"
            SYSTEM_VERSION=$(lsb_release -r | cut -f2)
            IS_KALI=1
        else
            SYSTEM_NAME=$(lsb_release -i | cut -f2)
            SYSTEM_VERSION=$(lsb_release -r | cut -f2)
            IS_KALI=0
        fi
    elif [ -f /etc/debian_version ]; then
        if grep -q "kali" /etc/debian_version 2>/dev/null; then
            SYSTEM_NAME="Kali"
            SYSTEM_VERSION="Unknown (from /etc/debian_version)"
            IS_KALI=1
        else
            SYSTEM_NAME="Debian-based (Unknown)"
            SYSTEM_VERSION="Unknown"
            IS_KALI=0
        fi
    else
        SYSTEM_NAME="Unknown"
        SYSTEM_VERSION="Unknown"
        IS_KALI=0
    fi
}

show_banner() {
    if [ "$IS_KALI" -eq 1 ]; then
        echo -e "${GREEN}==================================${NC}"
        echo -e "${GREEN}  检测到系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        echo -e "${GREEN}  脚本版本: $SCRIPT_VERSION${NC}"
        echo -e "${GREEN}==================================${NC}"
    else
        echo -e "${RED}==================================${NC}"
        echo -e "${RED}  警告: 此脚本为 Kali Linux 设计${NC}"
        echo -e "${RED}  检测到系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        echo -e "${RED}  脚本版本: $SCRIPT_VERSION${NC}"
        echo -e "${RED}==================================${NC}"
    fi
    echo ""
}

show_main_menu() {
    clear
    show_banner
    echo "=================================="
    echo "     树莓派 Kali Linux 工具箱 $SCRIPT_VERSION"
    echo "=================================="
    echo "分类菜单："
    echo "1) Kali Linux系统"
    echo "2) 远程访问"
    echo "3) 更新脚本 (来自 GitHub: lhl77/kali-raspi-tool)"
    echo "0) 退出"
    echo "----------------------------------"
    read -p "请选择分类 (0-3): " main_choice
}

show_system_menu() {
    clear
    show_banner
    echo "=================================="
    echo "         系统设置"
    echo "=================================="
    echo "1) 1.1 - 系统汉化（设置为简体中文）"
    echo "2) 1.2 - 安装 Kali Linux 完整工具集 (kali-linux-everything)"
    echo "0) 返回主菜单"
    echo "----------------------------------"
    read -p "请选择功能 (0-2): " system_choice
}

show_remote_menu() {
    clear
    show_banner
    echo "=================================="
    echo "         远程访问"
    echo "=================================="
    echo "1) 2.1 - 配置 x11vnc VNC 服务"
    echo "2) 2.2 - SSH 访问控制 (启用/禁用/状态)"
    echo "3) 2.3 - 切换 VNC 显示模式（有显示器 ↔ 无头）"
    echo "0) 返回主菜单"
    echo "----------------------------------"
    read -p "请选择功能 (0, 1, 2, 3): " remote_choice
}

perform_chinese_setup() {
    echo "[*] 开始执行汉化操作..."

    if [ -f /etc/default/locale ]; then
        sudo cp /etc/default/locale /etc/default/locale.bak_$(date +%Y%m%d_%H%M%S)
        echo "[*] 已备份 /etc/default/locale"
    fi

    echo "[*] 设置 LANG 和 LC_ALL 为 zh_CN.UTF-8"
    sudo tee /etc/default/locale > /dev/null <<EOF
LANG=zh_CN.UTF-8
LC_ALL=zh_CN.UTF-8
EOF

    echo "[*] 正在更新软件包列表..."
    if ! sudo apt update -y; then
       echo "[-] 软件包列表更新失败。"
       return 1
    fi

    echo "[*] 正在安装 locales-all..."
    if ! sudo apt install -y locales-all; then
        echo "[-] locales-all 安装失败。"
        return 1
    fi

    echo "[*] 正在生成 zh_CN.UTF-8 locale..."
    if ! sudo locale-gen zh_CN.UTF-8; then
        echo "[-] zh_CN.UTF-8 locale 生成失败。"
    fi

    if locale -a | grep -q "^zh_CN\.utf8$"; then
        echo "[+] 汉化配置成功！"
        echo "[!] 请重新登录或重启以生效。"
    else
        echo "[-] 警告：zh_CN.UTF-8 可能未正确生成。"
    fi

    read -p "[?] 是否安装文泉驿微米黑字体？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[*] 安装 fonts-wqy-microhei..."
        if sudo apt install -y fonts-wqy-microhei; then
            echo "[+] 中文字体已安装。"
            echo "[!] 请重新登录或重启以生效汉化配置。"
        else
            echo "[-] 字体安装失败。"
        fi
    else
        echo "[*] 已跳过字体安装。"
    fi
}

perform_x11vnc_setup() {
    echo "[*] 开始配置 x11vnc VNC 服务..."

    # 1. 安装 x11vnc (如果尚未安装)
    if ! dpkg -l | grep -q "^ii.*x11vnc"; then
        echo "[*] 安装 x11vnc..."
        if ! sudo apt update; then
            echo "[-] apt 更新失败。"
            return 1
        fi
        if ! sudo apt install -y x11vnc; then
            echo "[-] x11vnc 安装失败。"
            return 1
        fi
        echo "[+] x11vnc 安装成功。"
    else
        echo "[+] x11vnc 已安装。"
    fi

    # 2. 设置 VNC 密码
    echo "[*] 设置 VNC 密码（存储于 /root/.vnc/passwd）："
    sudo x11vnc -storepasswd

    # 3. 创建或覆盖 systemd 服务文件
    local service_file="/lib/systemd/system/x11vnc.service"
    echo "[*] 配置 systemd 服务文件: $service_file"
    
    # 注意：使用 -auth guess 让 x11vnc 自动寻找合适的认证方式，
    # 这样无论当前是物理显示还是虚拟显示都能适配。
    # -display :0 也可以尝试，但 -auth guess 更通用。
    # 如果遇到权限问题，可能需要调整 DISPLAY 环境变量或使用 -findauth
    if sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target graphical-session.target

[Service]
Type=simple
# -auth guess: 自动查找 X 授权文件
# -forever: 即使客户端断开也持续监听
# -loop: 断开后重新等待新连接
# -noxdamage: 解决某些环境下的性能问题 (可选)
# -repeat: 正确处理键盘重复按键
# -rfbauth: 指定密码文件
# -rfbport: 指定监听端口
# -shared: 允许多个客户端同时连接 (可选)
# -o /var/log/x11vnc.log -l /var/log/x11vnc.log: 日志输出 (可选)
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -repeat -rfbauth /root/.vnc/passwd -rfbport 5900 -shared -noxdamage -o /var/log/x11vnc.log
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
EOF
    then
        echo "[+] x11vnc 服务配置完成。"
        
        # 4. 重新加载 systemd 配置并启用服务
        echo "[*] 重新加载 systemd 配置..."
        sudo systemctl daemon-reload
        
        echo "[*] 启用 x11vnc 服务开机自启..."
        sudo systemctl enable x11vnc.service
        
        echo -e "${GREEN}[+] x11vnc 配置完成！端口: 5900${NC}"
        echo "    使用 'sudo systemctl start x11vnc' 可立即启动服务。"
        echo "    注意：请确保 X Server 已运行（例如，用户已登录图形界面）。"
        echo "          若要在无头模式下工作，请先使用 '2.3 - 手动切换 VNC 显示模式' 配置虚拟显示器。"
        
    else
        echo "[-] 服务文件写入失败。"
        return 1
    fi
}

perform_ssh_control() {
    echo "[*] SSH 访问控制功能"

    if ! dpkg -l | grep -q "^ii.*openssh-server"; then
        echo -e "${YELLOW}[!] 未安装 openssh-server。${NC}"
        read -p "[?] 是否现在安装？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if sudo apt update && sudo apt install -y openssh-server; then
                echo -e "${GREEN}[+] openssh-server 安装成功。${NC}"
            else
                echo -e "${RED}[-] 安装失败。${NC}"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}[+] openssh-server 已安装。${NC}"
    fi

    local ssh_status=$(systemctl is-active ssh 2>/dev/null || echo "unknown")
    echo "    当前 SSH 服务状态:"
    if [[ "$ssh_status" == "active" ]]; then
        echo -e "    ${GREEN}● active (running)${NC}"
    elif [[ "$ssh_status" == "inactive" ]]; then
        echo -e "    ${YELLOW}● inactive (dead)${NC}"
    else
        echo -e "    ${YELLOW}● 状态未知${NC}"
    fi

    echo ""
    echo "选项:"
    echo "1) 启用并启动 SSH"
    echo "2) 停止并禁用 SSH"
    echo "3) 查看详细状态"
    echo "0) 返回"
    read -p "请选择 (0-3): " ssh_action

    case "$ssh_action" in
        1)
            if sudo systemctl enable ssh --now; then
                echo -e "${GREEN}[+] SSH 已启用并启动。${NC}"
                ip=$(hostname -I | awk '{print $1}')
                [[ -n "$ip" ]] && echo "[*] 连接命令: ssh kali@$ip"
            else
                echo -e "${RED}[-] 操作失败。${NC}"
            fi
            ;;
        2)
            if sudo systemctl disable ssh --now; then
                echo -e "${GREEN}[+] SSH 已停止并禁用。${NC}"
            else
                echo -e "${RED}[-] 操作失败。${NC}"
            fi
            ;;
        3)
            sudo systemctl status ssh --no-pager
            ;;
        0)
            return 0
            ;;
        *)
            echo -e "${RED}[-] 无效选项${NC}"
            ;;
    esac
}

switch_vnc_display_mode() {
    echo "[*] 切换 VNC 显示模式"

    local xorg_conf="/etc/X11/xorg.conf"
    local dummy_backup="${xorg_conf}_bak_dummy"

    local has_display=false
    local xrandr_output

    # 执行一次 xrandr 并捕获输出
    if xrandr_output=$(xrandr --query 2>/dev/null); then
        # 检查输出中是否存在带有 " connected " (注意空格) 的行
        # 这种模式更精确地匹配状态，例如 "HDMI-1 connected primary ..."
        # 而避免匹配 "DP-1 disconnected"
        if echo "$xrandr_output" | grep -q " connected "; then
            has_display=true
        fi
    else
        # xrandr 命令失败（例如，没有运行 X server）
        # 可以选择默认为无显示器 (has_display=false) 或其他处理
        echo "[!] 警告: 无法执行 xrandr 查询显示状态。假设无物理显示器。" >&2
        # has_display 保持为 false
    fi

# 调试输出 (可选)
# echo "[DEBUG] xrandr output: $xrandr_output"
# echo "[DEBUG] has_display: $has_display"

    echo ""
    if [[ "$has_display" == true ]]; then
        echo -e "${GREEN}[+] 检测到物理显示器已连接。${NC}"
    else
        echo -e "${YELLOW}[-] 未检测到物理显示器（无头状态）。${NC}"
    fi

    local is_dummy_mode=false
    if [[ -f "$dummy_backup" ]]; then
        is_dummy_mode=true
        echo -e "${YELLOW}[!] 当前为虚拟显示器（无头）模式。${NC}"
    else
        echo -e "${GREEN}[+] 当前使用物理显示器或默认配置。${NC}"
    fi

    echo ""
    echo "可用操作："
    if [[ "$has_display" == true && "$is_dummy_mode" == true ]]; then
        echo "1) 切换回物理显示器模式"
    elif [[ "$has_display" == false && "$is_dummy_mode" == false ]]; then
        echo "1) 切换到无头模式（启用虚拟显示器）"
    elif [[ "$has_display" == true && "$is_dummy_mode" == false ]]; then
        echo "1) 强制切换到无头模式（忽略物理显示器）"
    elif [[ "$has_display" == false && "$is_dummy_mode" == true ]]; then
        echo "1) 重新应用虚拟显示器配置（修复）"
    fi
    echo "0) 返回上一级菜单"
    echo "----------------------------------"
    read -p "请选择 (0 或 1): " mode_choice

    if [[ "$mode_choice" != "1" ]]; then
        echo "[*] 已取消。"
        return 0
    fi
    
    # 在这里统一处理虚拟驱动的安装

    if [[ ("$has_display" == false || "$mode_choice" == "1") && (! -f "$dummy_backup" || "$is_dummy_mode" == false) ]]; then
        if ! dpkg -l | grep -q "^ii.*xserver-xorg-video-dummy"; then
            echo "[*] 安装虚拟显示器驱动 xserver-xorg-video-dummy..."
            if sudo apt update && sudo apt install -y xserver-xorg-video-dummy; then # xserver-xorg-core 通常是依赖项
                 echo "[+] 虚拟显示器驱动安装成功。"
            else
                echo "[-] 虚拟显示器驱动安装失败。"
                return 1
            fi
        else
             echo "[+] 虚拟显示器驱动已安装。"
        fi
    fi

    if [[ "$has_display" == false ]] || [[ "$mode_choice" == "1" ]]; then
        if ! dpkg -l | grep -q "^ii.*xserver-xorg-video-dummy"; then
            echo "[*] 安装虚拟显示器驱动..."
            if ! sudo apt update && sudo apt install -y xserver-xorg-core xserver-xorg-video-dummy; then
                echo "[-] 驱动安装失败。"
                return 1
            fi
        fi
    fi

    if [[ "$has_display" == true && "$is_dummy_mode" == true ]]; then
        sudo rm -f "$xorg_conf" "$dummy_backup"
        echo -e "${GREEN}[+] 已切换回物理显示器模式。${NC}"

    elif [[ "$has_display" == false && "$is_dummy_mode" == false ]]; then
        if [[ -f "$xorg_conf" ]] && [[ ! -f "$dummy_backup" ]]; then
            sudo cp "$xorg_conf" "${xorg_conf}.orig_$(date +%Y%m%d_%H%M%S)"
            echo "[*] 原始配置已备份。"
        fi
        if sudo tee "$xorg_conf" > /dev/null <<EOF
Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    Option      "IgnoreEDID" "true"
EndSection

Section "Monitor"
    Identifier  "DummyMonitor"
    HorizSync   28.0-80.0
    VertRefresh 48.0-75.0
EndSection

Section "Screen"
    Identifier  "DummyScreen"
    Device      "DummyDevice"
    Monitor     "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth   24
        Modes   "1280x720"
    EndSubSection
EndSection
EOF
        then
            sudo touch "$dummy_backup"
            echo -e "${GREEN}[+] 虚拟显示器已启用。${NC}"
        else
            echo "[-] 配置写入失败。"
            return 1
        fi

    elif [[ "$has_display" == true && "$is_dummy_mode" == false ]]; then
        if sudo tee "$xorg_conf" > /dev/null <<EOF
Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    Option      "IgnoreEDID" "true"
EndSection

Section "Monitor"
    Identifier  "DummyMonitor"
    HorizSync   28.0-80.0
    VertRefresh 48.0-75.0
EndSection

Section "Screen"
    Identifier  "DummyScreen"
    Device      "DummyDevice"
    Monitor     "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth   24
        Modes   "1280x720"
    EndSubSection
EndSection
EOF
        then
            sudo touch "$dummy_backup"
            echo -e "${GREEN}[+] 已强制切换到无头模式。${NC}"
        else
            echo "[-] 配置失败。"
            return 1
        fi

    elif [[ "$has_display" == false && "$is_dummy_mode" == true ]]; then
        if sudo tee "$xorg_conf" > /dev/null <<EOF
Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    Option      "IgnoreEDID" "true"
EndSection

Section "Monitor"
    Identifier  "DummyMonitor"
    HorizSync   28.0-80.0
    VertRefresh 48.0-75.0
EndSection

Section "Screen"
    Identifier  "DummyScreen"
    Device      "DummyDevice"
    Monitor     "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth   24
        Modes   "1280x720"
    EndSubSection
EndSection
EOF
        then
            sudo touch "$dummy_backup"
            echo -e "${GREEN}[+] 虚拟显示器配置已修复。${NC}"
        else
            echo "[-] 修复失败。"
            return 1
        fi
    fi

    echo -e "${YELLOW}[!] 需要重启系统才能生效。${NC}"
    read -p "[?] 是否现在重启？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "[*] 请稍后手动执行 'sudo reboot'。"
    fi
}

install_kali_full() {
    echo "[*] Kali Linux 完整工具集安装"
    echo ""

    # 1. 检查是否为 Kali 系统
    if [ "$IS_KALI" -ne 1 ]; then
        echo -e "${RED}[-] 错误：此功能仅适用于 Kali Linux 系统。${NC}"
        echo -e "${RED}    检测到系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        return 1
    fi
    echo -e "${GREEN}[+] 确认为 Kali Linux 系统 ($SYSTEM_VERSION)${NC}"

    # 2. 检查磁盘空间 (可选但推荐)
    # 简单估算，kali-linux-everything 及其依赖可能需要数 GB 空间
    local required_space_gb=10 # 估算值，可根据需要调整
    local available_space_kb
    local available_space_gb
    available_space_kb=$(df / | awk 'NR==2 {print $4}') # 获取根分区可用空间 KB
    if [[ -z "$available_space_kb" ]]; then
        echo -e "${YELLOW}[!] 警告：无法确定磁盘空间。将继续安装。${NC}"
        available_space_gb=0 # 设为0，跳过检查
    else
        # 使用 awk 进行浮点运算 (更精确) 或者简单的 bash 整数运算
        # 这里使用简单的整数除法 (KB -> GB: 除以 1024^2)
        available_space_gb=$(( available_space_kb / 1024 / 1024 ))
    fi

    if [[ $available_space_gb -lt $required_space_gb ]]; then
        echo -e "${YELLOW}[!] 警告：根分区可用空间可能不足 (~${available_space_gb}GB < ${required_space_gb}GB)。${NC}"
        read -p "[?] 空间可能不足，仍要继续吗? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
           echo "[*] 已取消安装。"
           return 0
        fi
    else
        echo -e "${GREEN}[+] 磁盘空间检查通过 (可用 ~${available_space_gb}GB)${NC}"
    fi

    # 3. 用户最终确认
    echo ""
    echo -e "${YELLOW}即将安装 'kali-linux-everything' Meta 包。${NC}"
    echo "    这将下载并安装大量的工具和依赖项。"
    echo "    过程可能耗时较长，取决于网络速度和硬件性能。"
    echo "    请确保系统已连接到互联网。"
    echo ""
    read -p "[?] 确认开始安装? (输入 'YES' 继续): " confirmation
    echo

    if [[ "$confirmation" != "YES" ]]; then
        echo "[*] 输入不匹配，已取消安装。"
        return 0
    fi

    echo "[*] 开始安装 Kali Linux 完整工具集..."
    echo "[*] 正在更新软件包列表..."
    if ! sudo apt update; then
        echo -e "${RED}[-] apt update 失败。${NC}"
        return 1
    fi

    echo "[*] 正在升级现有软件包 (推荐)..."
    # 使用 -y 自动确认升级
    if ! sudo apt upgrade -y; then
        echo -e "${YELLOW}[!] apt upgrade 遇到问题或被中断，但这不是致命错误。${NC}"
        # 不返回错误，因为用户可能选择 'n' 或网络中断等非致命原因
        # 可以让用户自行决定是否继续安装 meta 包
        read -p "[?] 是否忽略升级错误并继续安装 kali-linux-everything? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
           echo "[*] 已取消安装。"
           return 0
        fi
    fi

    echo "[*] 正在安装 kali-linux-everything Meta 包..."
    # 使用 -y 自动确认安装
    if sudo apt install -y kali-linux-everything; then
        echo -e "${GREEN}[+] Kali Linux 完整工具集安装成功！${NC}"
        echo -e "${GREEN}[+] 建议重启系统以确保所有更改生效。${NC}"
    else
        echo -e "${RED}[-] Kali Linux 完整工具集安装过程中出现错误。${NC}"
        # 提供故障排除建议
        echo "    可尝试手动运行以下命令排查问题："
        echo "      sudo apt update"
        echo "      sudo apt install -f # 修复依赖"
        echo "      sudo apt install kali-linux-everything"
        return 1
    fi
}

perform_script_update() {
    local repo_owner="lhl77"
    local repo_name="kali-raspi-tool"
    local script_name="main.sh"

    local urls=(
        "https://ghproxy.net/https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name"
        "https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name"
    )

    echo "[*] 正在检查更新..."
    echo "[*] 当前脚本版本: $SCRIPT_VERSION"

    local download_success=0
    local temp_script
    temp_script=$(mktemp)

    for url in "${urls[@]}"; do
        echo "[*] 尝试从源: $url 下载..."
        if curl -s -m 15 -o "$temp_script" "$url"; then
            if grep -q "Kali Linux 树莓派脚本" "$temp_script"; then
                echo "[+] 成功下载脚本。"
                download_success=1
                break
            else
                echo "[-] 下载内容无效。"
            fi
        else
            echo "[-] 下载失败或超时。"
        fi
    done

    if [[ $download_success -eq 1 ]]; then
        local remote_version_line=$(grep -m 1 '^SCRIPT_VERSION=' "$temp_script")
        local remote_version=""
        if [[ -n "$remote_version_line" ]]; then
            remote_version=$(echo "$remote_version_line" | sed -n 's/.*SCRIPT_VERSION="\([^"]*\)".*/\1/p')
        fi

        if [[ -n "$remote_version" ]]; then
            echo "[*] 远程版本: $remote_version"
            local version_list=$(printf '%s\n%s' "$SCRIPT_VERSION" "$remote_version" | sort -V)
            local latest_version=$(echo "$version_list" | tail -n 1)

            if [[ "$latest_version" == "$remote_version" ]] && [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
                echo -e "${YELLOW}[*] 发现新版本: $remote_version${NC}"
                read -p "[?] 是否更新？(Y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if mv "$temp_script" "$0"; then
                        chmod +x "$0"
                        echo -e "${GREEN}[+] 更新成功！新版本: $remote_version${NC}"
                        read -p "[?] 是否退出以便重新运行？(Y/n): " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            exit 0
                        fi
                    else
                        echo "[-] 覆盖失败。"
                        rm -f "$temp_script"
                    fi
                else
                    rm -f "$temp_script"
                fi
            elif [[ "$SCRIPT_VERSION" == "$remote_version" ]]; then
                echo -e "${GREEN}[+] 当前已是最新版本。${NC}"
                rm -f "$temp_script"
            else
                echo -e "${GREEN}[+] 当前版本较新。${NC}"
                rm -f "$temp_script"
            fi
        else
            echo "[-] 无法解析远程版本号。"
            rm -f "$temp_script"
        fi
    else
        echo "[-] 所有源均无法下载有效脚本。"
        rm -f "$temp_script"
    fi
}

# === 主程序入口 ===
check_privileges
check_system_version

while true; do
    show_main_menu
    case "$main_choice" in
        1)
            while true; do
                show_system_menu
                case "$system_choice" in
                    2) install_kali_full;read -p "按回车返回主菜单...";;
                    1) perform_chinese_setup; read -p "按回车返回...";;
                    0) break;;
                    *) echo "[-] 无效选项"; sleep 1;;
                esac
            done
            ;;
        2)
            while true; do
                show_remote_menu
                case "$remote_choice" in
                    1) perform_x11vnc_setup; read -p "按回车返回...";;
                    2) perform_ssh_control; read -p "按回车返回...";;
                    3) switch_vnc_display_mode; read -p "按回车返回...";;
                    0) break;;
                    *) echo "[-] 无效选项"; sleep 1;;
                esac
            done
            ;;
        3)
            perform_script_update
            read -p "按回车返回主菜单..."
            ;;
        0)
            echo "[*] 退出脚本。再见！"
            exit 0
            ;;
        *)
            echo "[-] 无效选项"
            sleep 1
            ;;
    esac
done
