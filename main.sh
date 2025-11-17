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
SCRIPT_VERSION="v0.2.5"

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
    echo "1) 系统设置"
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
    echo "0) 返回主菜单"
    echo "----------------------------------"
    read -p "请选择功能 (0, 1): " system_choice
}

show_remote_menu() {
    clear
    show_banner
    echo "=================================="
    echo "         远程访问"
    echo "=================================="
    echo "1) 2.1 - 配置 x11vnc VNC 服务 (推荐)"
    echo "2) 2.2 - SSH 访问控制 (启用/禁用/状态)"
    echo "3) 2.3 - 手动切换 VNC 显示模式（有显示器 ↔ 无头）"
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
        else
            echo "[-] 字体安装失败。"
        fi
    else
        echo "[*] 已跳过字体安装。"
    fi
}

perform_x11vnc_setup() {
    echo "[*] 开始配置 x11vnc VNC 服务..."

    if ! dpkg -l | grep -q "^ii.*x11vnc"; then
        echo "[*] 安装 x11vnc..."
        if ! sudo apt install -y x11vnc; then
            echo "[-] x11vnc 安装失败。"
            return 1
        fi
    fi

    echo "[*] 设置 VNC 密码（存储于 /root/.vnc/passwd）："
    sudo x11vnc -storepasswd

    local service_file="/lib/systemd/system/x11vnc.service"
    if sudo tee "$service_file" > /dev/null <<EOF
[Unit]
Description=Start x11vnc at startup.
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -nap -forever -loop -repeat -rfbauth /root/.vnc/passwd -rfbport 5900

[Install]
WantedBy=multi-user.target
EOF
    then
        echo "[+] x11vnc 服务配置完成。"
        sudo systemctl daemon-reload
        sudo systemctl enable x11vnc.service
    else
        echo "[-] 服务文件写入失败。"
        return 1
    fi

    local has_display=false
    if xrandr --query &>/dev/null; then
        if xrandr | grep -q " connected" && ! xrandr | grep -q " disconnected"; then
            has_display=true
        fi
    fi

    local xorg_conf="/etc/X11/xorg.conf"
    local dummy_backup="${xorg_conf}_bak_dummy"

    if [[ "$has_display" == true ]]; then
        echo "[*] 检测到物理显示器。"
        if [[ -f "$dummy_backup" ]]; then
            echo -e "${YELLOW}[!] 检测到之前使用虚拟显示器。${NC}"
            read -p "[?] 是否切换回物理显示器？(Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                sudo rm -f "$xorg_conf" "$dummy_backup"
                echo "[+] 已切换回物理显示器模式。"
            fi
        else
            echo "[+] 将共享当前显示器画面。"
            if [[ -f "$xorg_conf" ]]; then
                read -p "[?] 存在 xorg.conf，是否删除以避免冲突？(y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    sudo rm -f "$xorg_conf"
                    echo "[+] 已删除 xorg.conf。"
                fi
            fi
        fi
    else
        echo "[*] 未检测到显示器（无头模式）。"
        if ! dpkg -l | grep -q "^ii.*xserver-xorg-video-dummy"; then
            echo "[*] 安装虚拟显示器驱动..."
            if ! sudo apt install -y xserver-xorg-core xserver-xorg-video-dummy; then
                echo "[-] 驱动安装失败。"
                return 1
            fi
        fi

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
            echo "[+] 虚拟显示器配置已启用。"
        else
            echo "[-] 虚拟配置写入失败。"
            return 1
        fi
    fi

    echo -e "${GREEN}[+] x11vnc 配置完成！端口: 5900${NC}"
    echo "    使用 'sudo systemctl start x11vnc' 可立即启动服务。"

    if [[ "$has_display" == false ]] || [[ -f "$dummy_backup" ]]; then
        read -p "[?] 为使显示配置生效，建议重启。是否现在重启？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo reboot
        fi
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
    echo "[*] 手动切换 VNC 显示模式"

    local xorg_conf="/etc/X11/xorg.conf"
    local dummy_backup="${xorg_conf}_bak_dummy"

    local has_display=false
    if xrandr --query &>/dev/null; then
        if xrandr | grep -q " connected" && ! xrandr | grep -q " disconnected"; then
            has_display=true
        fi
    fi

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
