#!/bin/bash

# kali_raspi.sh - Kali Linux 树莓派脚本 
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
SCRIPT_VERSION="v0.3.5"

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
        echo -e "${GREEN}  系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        #echo -e "${GREEN}  脚本版本: $SCRIPT_VERSION${NC}"
        echo -e "${GREEN}==================================${NC}"
    else
        echo -e "${RED}==================================${NC}"
        echo -e "${RED}  警告: 此脚本为 Kali Linux 设计${NC}"
        echo -e "${RED}  检测到系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        #echo -e "${RED}  脚本版本: $SCRIPT_VERSION${NC}"
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
    echo "3) 外设/驱动"
    echo "4) 更新脚本 (来自 GitHub: lhl77/kali-raspi-tool)"
    echo "0) 退出"
    echo "----------------------------------"
    read -p "请选择分类 (0-4): " main_choice
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

show_hardware_menu() {
    clear
    show_banner
    echo "=================================="
    echo "         硬件驱动"
    echo "=================================="
    echo "1) 3.1 - 0.91英寸 OLED I2C 屏幕驱动 + 监控脚本"
    echo "0) 返回主菜单"
    echo "----------------------------------"
    read -p "请选择功能 (0-1): " hardware_choice
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
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
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

    # 安装 x11vnc
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

    # 设置 VNC 密码
    echo "[*] 设置 VNC 密码（存储于 /root/.vnc/passwd）："
    sudo x11vnc -storepasswd

    # 创建或覆盖 systemd 服务文件
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
        
        # 重新加载 systemd 配置并启用服务
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
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
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

    local xorg_conf_dir="/etc/X11/xorg.conf.d"
    local dummy_conf_file="${xorg_conf_dir}/10-dummy.conf"
    local dummy_backup_marker="${dummy_conf_file}_bak" # 用于标记是否处于虚拟模式

    # 确保 xorg.conf.d 目录存在
    if [[ ! -d "$xorg_conf_dir" ]]; then
        echo "[*] 创建 Xorg 配置目录 $xorg_conf_dir..."
        if ! sudo mkdir -p "$xorg_conf_dir"; then
            echo "[-] 创建目录 $xorg_conf_dir 失败。"
            return 1
        fi
        
    fi

    # 虚拟模式状态检测 (首要依据) 
    # 关键：通过检查标记文件是否存在来判断是否处于虚拟模式
    local is_dummy_mode=false
    if [[ -f "$dummy_backup_marker" ]]; then
        is_dummy_mode=true
    fi

    # 物理显示器状态检测 (仅在非虚拟模式下进行有意义的检测)
    local has_display=false
    if [[ "$is_dummy_mode" == false ]]; then
        # 只有在非虚拟模式下，检测物理显示器才有意义
        local xrandr_output
        # 尝试执行 xrandr，但不因失败而停止脚本或做出强假设
        if xrandr_output=$(xrandr --query 2>/dev/null); then
            # 检查输出中是否存在带有 " connected " (注意空格) 的行
            if echo "$xrandr_output" | grep -q " connected "; then
                has_display=true
            fi
        else
            # xrandr 失败，静默处理
            :
        fi
    fi

    echo ""
    if [[ "$is_dummy_mode" == true ]]; then
        echo -e "${YELLOW}[!] 当前为虚拟显示器（无头）模式。${NC}"
    else
        if [[ "$has_display" == true ]]; then
            echo -e "${GREEN}[+] 检测到物理显示器已连接。${NC}"
        else
            echo -e "${YELLOW}[?] 未检测到物理显示器或状态未知。${NC}"
        fi
        echo -e "${GREEN}[+] 当前使用物理显示器或默认配置。${NC}"
    fi

    # --- 显示操作选项 ---
    echo ""
    echo "可用操作："
    if [[ "$is_dummy_mode" == true ]]; then
        echo "1) 切换回物理显示器模式"
    else
        if [[ "$has_display" == true ]]; then
            echo "1) 强制切换到无头模式（忽略物理显示器）"
        else
            echo "1) 切换到无头模式（启用虚拟显示器）"
        fi
    fi
    echo "0) 返回上一级菜单"
    echo "----------------------------------"
    read -p "请选择 (0 或 1): " mode_choice

    if [[ "$mode_choice" != "1" ]]; then
        echo "[*] 已取消。"
        return 0
    fi

    # 统一处理驱动安装 (仅在需要切入虚拟模式时) 
    if [[ "$is_dummy_mode" == false ]]; then
        if ! dpkg -l | grep -q "^ii.*xserver-xorg-video-dummy"; then
            echo "[*] 安装虚拟显示器驱动 xserver-xorg-video-dummy..."
            if sudo apt update && sudo apt install -y xserver-xorg-video-dummy; then
                 echo "[+] 虚拟显示器驱动安装成功。"
            else
                echo "[-] 虚拟显示器驱动安装失败。"
                return 1
            fi
        else
             echo "[+] 虚拟显示器驱动已安装。"
        fi
    fi

    if [[ "$is_dummy_mode" == true ]]; then
        echo "[*] 正在切换回物理显示器模式..."
        sudo rm -f "$dummy_conf_file" "$dummy_backup_marker"
        echo -e "${GREEN}[+] 已切换回物理显示器模式。请重启生效。${NC}"
    else
        echo "[*] 正在切换到无头模式..."

        if [[ -f "$dummy_conf_file" ]] && [[ ! -f "${dummy_conf_file}.orig"* ]]; then
             local timestamp=$(date +%Y%m%d_%H%M%S)
             sudo cp "$dummy_conf_file" "${dummy_conf_file}.orig_${timestamp}"
             echo "[*] 原始配置文件已备份为 ${dummy_conf_file}.orig_${timestamp}。"
        fi

        if sudo tee "$dummy_conf_file" > /dev/null <<'EOF_DUMMY_CONF'
Section "Monitor"
    Identifier "Monitor0"
    HorizSync 28.0-80.0
    VertRefresh 48.0-75.0
    Modeline "1600x900_60.00" 118.25 1600 1696 1856 2112 900 903 908 934 -hsync +vsync
EndSection

Section "Device"
    Identifier "Card0"
    Driver "dummy"
    VideoRam 256000
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "Card0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1600x900_60.00"
    EndSubSection
EndSection
EOF_DUMMY_CONF
        then
            sudo touch "$dummy_backup_marker"
            echo -e "${GREEN}[+] 虚拟显示器已启用 (配置文件: $dummy_conf_file)。请重启生效。${NC}"
        else
            echo "[-] 虚拟显示器配置写入失败。"
            return 1
        fi
    fi

    # 重启提示
    echo -e "${YELLOW}[!] 需要重启系统才能使更改生效。${NC}"
    read -p "[?] 是否现在重启？(Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
        sudo reboot
    else
        echo "[*] 请稍后手动执行 'sudo reboot'。"
    fi
}

install_kali_full() {
    echo "[*] Kali Linux 完整工具集安装"
    echo ""

    # 检查是否为 Kali 系统
    if [ "$IS_KALI" -ne 1 ]; then
        echo -e "${RED}[-] 错误：此功能仅适用于 Kali Linux 系统。${NC}"
        echo -e "${RED}    检测到系统: $SYSTEM_NAME $SYSTEM_VERSION${NC}"
        return 1
    fi
    echo -e "${GREEN}[+] 确认为 Kali Linux 系统 ($SYSTEM_VERSION)${NC}"

    # 检查磁盘空间 (可选但推荐)
    # 简单估算，kali-linux-everything 及其依赖可能需要数 GB 空间
    local required_space_gb=15 # 估算值，可根据需要调整
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
        # (y/N): N 是大写，为默认值。回车等同于 'N' (即取消)
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # 用户选择继续，什么也不做，让流程自然落到下面的 else
            : # 空指令占位符
        else
           echo "[*] 已取消安装。"
           return 0
        fi
    else
        # 空间充足的情况直接在这里处理
        echo -e "${GREEN}[+] 磁盘空间检查通过 (可用 ~${available_space_gb}GB)${NC}"
    fi

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

manage_oled091_driver() {
    local install_dir="/usr/share/raspi-oled-091"
    local status="未安装"
    local action_prompt=""

    # 判断安装状态
    if [[ -d "$install_dir" ]] && [[ -f "$install_dir/main.py" ]]; then
        status="已安装"
        action_prompt="卸载"
    else
        status="未安装"
        action_prompt="安装"
    fi

    clear
    show_banner
    echo "=================================="
    echo "   0.91英寸 OLED 屏幕驱动管理"
    echo "=================================="
    echo "当前状态: $status"
    echo "----------------------------------"
    echo "1) $action_prompt 驱动"
    # 可以添加更多选项，比如 "查看日志", "手动启动/停止" 等
    echo "0) 返回上一级菜单"
    echo "----------------------------------"
    read -p "请选择操作 (0-1): " manage_choice

    case "$manage_choice" in
        1)
            if [[ "$status" == "未安装" ]]; then
                echo "[*] 开始安装流程..."
                do_install_oled091_driver
            else
                echo "[*] 开始卸载流程..."
                do_uninstall_oled091_driver
            fi
            read -p "按回车返回..."
            ;;
        0)
            # 返回上级菜单，不需要做任何事
            ;;
        *)
            echo "[-] 无效选项"
            sleep 1
            ;;
    esac
}

do_install_oled091_driver() {
    echo "[*] 开始安装 0.91英寸 OLED 屏幕驱动..."

    local repo_owner="lhl77"
    local repo_name="raspi-oled-091"
    local release_version="v1.0"
    local zip_name="raspi-oled-091.zip"
    #local install_dir="/usr/share/${repo_name}"
    local install_dir="/usr/share"
    local script_path="${install_dir}/main.py"

    # --- 步骤 1: 检查并创建安装目录 ---
    echo "[*] 创建安装目录 $install_dir..."
    if ! sudo mkdir -p "$install_dir"; then
        echo "[-] 创建目录失败。"
        return 1
    fi

    # --- 步骤 2: 下载 ZIP 文件 (使用镜像) ---
    local urls=(
        "https://ghproxy.net/https://github.com/$repo_owner/$repo_name/releases/download/$release_version/$zip_name"
        "https://github.com/$repo_owner/$repo_name/releases/download/$release_version/$zip_name"
    )
    local download_success=0
    local temp_zip
    temp_zip=$(mktemp --suffix=.zip)

    for url in "${urls[@]}"; do
        echo "[*] 尝试从源下载: $url"
        if curl -s -m 30 -o "$temp_zip" "$url"; then
            # 检查文件是否为有效的 ZIP
            if file "$temp_zip" | grep -q "Zip archive"; then
                echo "[+] 下载成功。"
                download_success=1
                break
            else
                echo "[-] 下载内容无效 (非 ZIP 文件)。"
                rm -f "$temp_zip"
            fi
        else
            echo "[-] 下载失败或超时。"
        fi
    done

    if [[ $download_success -ne 1 ]]; then
        echo "[-] 所有源均下载失败。"
        return 1
    fi

    # --- 步骤 3: 解压到目标目录 ---
    echo "[*] 解压文件到 $install_dir..."
    if ! sudo unzip -o -q "$temp_zip" -d "$install_dir"; then
        echo "[-] 解压失败。"
        rm -f "$temp_zip"
        return 1
    fi
    rm -f "$temp_zip"
    echo "[+] 文件解压完成。"

    # --- 步骤 4: 安装系统依赖 ---
    echo "[*] 安装系统依赖 (i2c-tools, python3-smbus)..."
    # 优先尝试 python3-smbus，如果失败再尝试 python-smbus
    if ! sudo apt-get install -y i2c-tools python3-smbus; then
        echo "[*] python3-smbus 安装失败，尝试 python-smbus..."
        if ! sudo apt-get install -y i2c-tools python-smbus; then
            # 如果还是失败，尝试使用 --break-system-packages
            echo "[*] 常规安装失败，尝试使用 --break-system-packages..."
            if ! sudo apt-get install -y --break-system-packages i2c-tools python3-smbus && \
               ! sudo apt-get install -y --break-system-packages i2c-tools python-smbus; then
                echo "[-] 系统依赖安装失败，请手动检查。"
                return 1
            fi
        fi
    fi
    echo "[+] 系统依赖安装成功。"

    # --- 步骤 5: 检查 I2C 是否启用 ---
    echo "[*] 检查 I2C 总线..."
    if ! i2cdetect -y 1 &>/dev/null; then
        echo -e "${YELLOW}[!] I2C 可能未启用。${NC}"
        echo "    请运行 'sudo raspi-config' -> 'Interface Options' -> 'I2C' 启用。"
        read -p "[?] 是否现在运行 raspi-config? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
            sudo raspi-config
        fi
        # 再次检查
        if ! i2cdetect -y 1 &>/dev/null; then
            echo "[-] I2C 仍未启用，无法继续。"
            return 1
        fi
    fi
    echo "[+] I2C 检测正常。"

    # --- 步骤 6: 升级 pip 并安装 Python 包 ---
    echo "[*] 升级 pip, setuptools, wheel..."
    # 尝试标准升级
    if ! sudo python3 -m pip install --upgrade pip setuptools wheel; then
        echo "[*] 标准 pip 升级失败，尝试使用 --break-system-packages..."
        # 如果标准升级失败，则尝试带 --break-system-packages 参数
        if ! sudo python3 -m pip install --upgrade --break-system-packages pip setuptools wheel; then
            echo "[-] pip 升级失败（即使使用 --break-system-packages），将继续尝试安装 Adafruit-SSD1306..."
            # 注意：这里不再 return 1，而是继续向下执行
        else
             echo "[+] pip, setuptools, wheel 升级成功（使用 --break-system-packages）。"
        fi
    else
        echo "[+] pip, setuptools, wheel 升级成功。"
    fi

    echo "[*] 安装 Python 包 Adafruit-SSD1306..."
    if ! sudo pip install Adafruit-SSD1306; then
        echo "[*] 标准安装失败，尝试使用 --break-system-packages..."
        if ! sudo pip install --break-system-packages Adafruit-SSD1306; then
            echo "[-] Adafruit-SSD1306 安装失败。"
            return 1
        fi
    fi
    echo "[+] Python 包安装成功。"

    # --- 步骤 7: 配置定时任务 ---
    echo "[*] 配置开机自启定时任务..."
    local crontab_entry="@reboot /usr/bin/python3 $script_path"
    local temp_crontab
    temp_crontab=$(mktemp)

    # 导出现有定时任务
    crontab -l > "$temp_crontab" 2>/dev/null || echo "# Created by kali_raspi.sh" > "$temp_crontab"

    # 检查是否已存在该任务
    if ! grep -qF "$crontab_entry" "$temp_crontab"; then
        echo "$crontab_entry" >> "$temp_crontab"
        if crontab "$temp_crontab"; then
            echo "[+] 开机自启任务已添加。"
        else
            echo "[-] 添加定时任务失败。"
            rm -f "$temp_crontab"
            return 1
        fi
    else
        echo "[*] 开机自启任务已存在。"
    fi
    rm -f "$temp_crontab"

    # --- 步骤 8: 立即后台运行一次 ---
    echo "[*] 正在启动 OLED 屏幕..."
    # 先确保没有旧进程
    pkill -f "python.*$script_path" 2>/dev/null || true
    # 后台运行
    nohup /usr/bin/python3 "$script_path" > /dev/null 2>&1 &
    local pid=$!
    # 等待几秒看是否启动
    sleep 3
    if kill -0 $pid 2>/dev/null; then
        echo -e "${GREEN}[+] OLED 屏幕驱动安装并启动成功！${NC}"
        echo "    屏幕应已点亮。脚本将在后台持续运行。"
    else
        echo -e "${YELLOW}[!] 警告：脚本启动后可能已退出，检查 /tmp/nohup.out 或日志。${NC}"
    fi

    echo ""
    echo "提示："
    echo "  - 重启后屏幕将自动点亮。"
    echo "  - 如需停止，运行: pkill -f 'python.*$script_path'"
    echo "  - 如需卸载，删除 $install_dir 目录和 crontab 中的任务。"
}

do_uninstall_oled091_driver() {
    local install_dir="/usr/share/raspi-oled-091"
    local script_path="${install_dir}/main.py"
    local crontab_entry="@reboot /usr/bin/python3 $script_path"

    echo "[*] 开始卸载 0.91英寸 OLED 屏幕驱动..."

    # --- 步骤 1: 停止正在运行的相关进程 ---
    echo "[*] 停止正在运行的 OLED 脚本..."
    pkill -f "python.*$script_path" 2>/dev/null || true
    # 如果你想更彻底，也可以 pkill -f "python.*main.py" （但风险稍高）

    # --- 步骤 2: 删除安装目录 ---
    if [[ -d "$install_dir" ]]; then
        echo "[*] 删除安装目录 $install_dir..."
        if sudo rm -rf "$install_dir"; then
            echo "[+] 安装目录已删除。"
        else
            echo "[-] 删除安装目录失败。"
            # 可以选择在这里 return 1，但通常还是尝试清理其他部分
        fi
    else
        echo "[*] 安装目录不存在。"
    fi

    # --- 步骤 3: 移除 Crontab 中的开机自启任务 ---
    echo "[*] 从 Crontab 中移除开机自启任务..."
    local temp_crontab
    temp_crontab=$(mktemp)

    # 导出当前用户的 crontab
    crontab -l > "$temp_crontab" 2>/dev/null || touch "$temp_crontab"

    # 检查是否存在我们的任务条目
    if grep -qF "$crontab_entry" "$temp_crontab"; then
        # 存在则过滤掉该行并写回
        grep -vF "$crontab_entry" "$temp_crontab" | crontab -
        echo "[+] 开机自启任务已移除。"
    else
        echo "[*] Crontab 中未找到相关开机自启任务。"
    fi

    rm -f "$temp_crontab"

    # --- 步骤 4: (可选) 提示用户卸载 Python 包 ---
    # 卸载 Adafruit-SSD1306 需要 pip uninstall，但这可能影响其他项目，
    # 通常不建议在卸载驱动时自动卸载全局包。
    # echo "[*] 注意：如需卸载 Adafruit-SSD1306 库，请手动运行:"
    # echo "      sudo pip uninstall Adafruit-SSD1306"

    echo -e "${GREEN}[+] OLED 屏幕驱动卸载完成。${NC}"
}

perform_script_update() {
    local repo_owner="lhl77"
    local repo_name="kali-raspi-tool"
    local script_name="kali_raspi.sh"

    # --- 关键修改：为每个请求生成唯一的时间戳 ---
    local timestamp=$(date +%s%N)  # 使用纳秒级时间戳保证唯一性

    local urls=(
        "https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name?_=$timestamp"
        "https://ghproxy.net/https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name?_=$timestamp"
    )

    echo "[*] 正在检查更新..."
    echo "[*] 当前脚本版本: $SCRIPT_VERSION"

    local download_success=0
    local temp_script
    temp_script=$(mktemp)

    for url in "${urls[@]}"; do
        echo "[*] 尝试从源下载: $url"
        # --- 增加 curl 参数防止缓存 ---
        if curl -s -m 15 \
               -o "$temp_script" "$url"; then
            # 验证是否是有效的 shell 脚本
            if grep -q "Kali Linux 树莓派脚本" "$temp_script"; then
                echo "[+] 成功下载最新脚本。"
                download_success=1
                break
            else
                echo "[-] 下载内容无效（非预期脚本）。"
                rm -f "$temp_script"
                temp_script=$(mktemp)  # 重建临时文件用于下一次循环
            fi
        else
            echo "[-] 下载失败或超时。"
        fi
    done

    if [[ $download_success -eq 1 ]]; then
        # 提取远程版本号
        local remote_version_line=$(grep -m 1 '^SCRIPT_VERSION=' "$temp_script")
        local remote_version=""
        if [[ -n "$remote_version_line" ]]; then
            remote_version=$(echo "$remote_version_line" | sed -E 's/.*SCRIPT_VERSION="([^"]*)".*/\1/')
        fi

        if [[ -n "$remote_version" ]]; then
            echo "[*] 远程版本: $remote_version"

            # 比较版本号
            local version_list=$(printf '%s\n%s' "$SCRIPT_VERSION" "$remote_version" | sort -V)
            local latest_version=$(echo "$version_list" | tail -n 1)

            if [[ "$latest_version" == "$remote_version" ]] && [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
                echo -e "${YELLOW}[*] 发现新版本: $remote_version${NC}"
                read -p "[?] 是否更新？(Y/n): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
                    if mv "$temp_script" "$0"; then
                        chmod +x "$0"
                        echo -e "${GREEN}[+] 更新成功！新版本: $remote_version${NC}"
                        read -p "[?] 是否退出以便重新运行？(Y/n): " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z "$REPLY" ]]; then
                            exit 0
                        fi
                    else
                        echo "[-] 覆盖当前脚本失败。"
                        rm -f "$temp_script"
                    fi
                else
                    rm -f "$temp_script"
                fi
            elif [[ "$SCRIPT_VERSION" == "$remote_version" ]]; then
                echo -e "${GREEN}[+] 当前已是最新版本。${NC}"
                rm -f "$temp_script"
            else
                echo -e "${GREEN}[+] 当前版本($SCRIPT_VERSION) 比远程版本($remote_version) 更新！${NC}"
                rm -f "$temp_script"
            fi
        else
            echo "[-] 无法解析远程版本号，请检查远程脚本格式。"
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
            while true; do
                show_hardware_menu
                case "$hardware_choice" in
                    1) manage_oled091_driver;;
                    0) break;;
                    *) echo "[-] 无效选项"; sleep 1;;
                esac
            done
            ;;
        4)
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
