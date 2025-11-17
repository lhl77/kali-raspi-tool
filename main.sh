#!/bin/bash

# main.sh - Kali Linux 树莓派脚本 v0.2.4 (开发版 - SSH 增强 + 国内镜像更新)
# 作者 lhl77
# GitHub 仓库: https://github.com/lhl77/kali-raspi-tool
# 修改说明: 添加了 SSH 启用/禁用/状态查看功能 (新增功能 2.2)，优化为自动安装 SSH 服务，
#           更新功能增加国内镜像源以提高可访问性，并改进版本号比较逻辑

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本版本
SCRIPT_VERSION="v0.2.4" # <-- 版本号由此行定义

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
    # 尝试从 /etc/os-release 获取信息
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
    # 如果 /etc/os-release 不存在，尝试其他方法
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
    # 最后尝试检查 /etc/debian_version (Kali 基于 Debian)
    elif [ -f /etc/debian_version ]; then
        # 这种方法不够精确，仅作为后备
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

# 显示系统检查结果的横幅
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
    show_banner # 显示系统/版本横幅
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
    show_banner # 显示系统/版本横幅
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
    show_banner # 显示系统/版本横幅
    echo "=================================="
    echo "         远程访问"
    echo "=================================="
    echo "1) 2.1 - 配置 x11vnc VNC 服务 (推荐)"
    # --- 新增 SSH 功能选项 ---
    echo "2) 2.2 - SSH 访问控制 (启用/禁用/状态)"
    # --------------------------
    echo "0) 返回主菜单"
    echo "----------------------------------"
    read -p "请选择功能 (0, 1, 2): " remote_choice
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

    echo "[*] 正在安装 locales-all（包含中文语言环境）..."
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
        echo "[!] 请重新登录或重启系统以使更改生效。"
    else
        echo "[-] 警告：zh_CN.UTF-8 可能未正确生成或列出。"
        echo "    建议手动运行：sudo dpkg-reconfigure locales"
    fi

    local REPLY
    read -p "[?] 是否安装文泉驿微米黑字体以更好显示中文？(按 Y 确认, 其他键跳过): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "[*] 正在安装 fonts-wqy-microhei..."
        if sudo apt install -y fonts-wqy-microhei; then
            echo "[+] 中文字体已安装。"
        else
            echo "[-] 中文字体安装失败。"
        fi
    else
        echo "[*] 已跳过中文字体安装。"
    fi
}
perform_x11vnc_setup() {
    echo "[*] 开始配置 x11vnc VNC 服务..."

    # 安装 x11vnc（如果未安装）
    if ! dpkg -l | grep -q "^ii.*x11vnc"; then
        echo "[*] 正在安装 x11vnc..."
        if ! sudo apt install -y x11vnc; then
            echo "[-] x11vnc 安装失败。"
            return 1
        fi
    else
        echo "[+] x11vnc 已安装。"
    fi

    # 设置 VNC 密码（存储在 /root/.vnc/passwd）
    echo "[*] 设置 VNC 密码（仅用于 root 用户）："
    sudo x11vnc -storepasswd

    # 创建或更新 systemd 服务文件
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
        echo "[+] x11vnc 服务配置已更新。"
        sudo systemctl daemon-reload
        sudo systemctl enable x11vnc.service
    else
        echo "[-] 无法写入 x11vnc 服务文件。"
        return 1
    fi

    # 检测当前是否有物理显示器连接
    local has_display=false
    if xrandr --query &>/dev/null; then
        if xrandr | grep -q " connected" && ! xrandr | grep -q " disconnected"; then
            has_display=true
        fi
    fi

    local xorg_conf="/etc/X11/xorg.conf"
    local dummy_backup="${xorg_conf}_bak_dummy"

    if [[ "$has_display" == true ]]; then
        echo "[*] 检测到物理显示器已连接。"
        # 如果存在 _bak_dummy 备份，说明之前是无头模式，询问是否切换回来
        if [[ -f "$dummy_backup" ]]; then
            echo -e "${YELLOW}[!] 检测到之前配置过无头（虚拟显示器）模式。${NC}"
            read -p "[?] 是否切换回使用物理显示器？(这将删除虚拟显示器配置) (Y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "[*] 正在恢复物理显示器模式..."
                # 删除当前 xorg.conf（如果是 dummy 的）
                if [[ -f "$xorg_conf" ]]; then
                    sudo rm -f "$xorg_conf"
                fi
                # 删除备份标记（表示不再使用 dummy）
                sudo rm -f "$dummy_backup"
                echo "[+] 已切换回物理显示器模式。"
            else
                echo "[*] 保留当前虚拟显示器配置。"
            fi
        else
            echo "[+] 将使用当前物理显示器画面进行 VNC 共享。"
            # 确保没有残留的 dummy 配置
            if [[ -f "$xorg_conf" ]]; then
                echo "[*] 检测到存在 /etc/X11/xorg.conf，但当前有显示器。"
                read -p "[?] 是否保留此配置？(建议删除以避免冲突) (Y=保留, n=删除): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    sudo rm -f "$xorg_conf"
                    echo "[+] 已删除 /etc/X11/xorg.conf。"
                fi
            fi
        fi

    else
        echo "[*] 未检测到物理显示器（无头模式）。"
        # 安装虚拟显示器驱动
        if ! dpkg -l | grep -q "^ii.*xserver-xorg-video-dummy"; then
            echo "[*] 安装虚拟显示器所需包..."
            if ! sudo apt install -y xserver-xorg-core xserver-xorg-video-dummy; then
                echo "[-] 虚拟显示器包安装失败。"
                return 1
            fi
        fi

        # 如果当前有 xorg.conf 且不是 dummy 备份，先备份原文件（谨慎处理）
        if [[ -f "$xorg_conf" ]] && [[ ! -f "$dummy_backup" ]]; then
            echo "[*] 备份现有 X11 配置为 ${xorg_conf}.orig ..."
            sudo cp "$xorg_conf" "${xorg_conf}.orig"
        fi

        # 创建虚拟显示器配置
        echo "[*] 配置虚拟显示器（1280x720）..."
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
            echo "[+] 虚拟显示器配置已写入 $xorg_conf"
            # 创建标记文件，表示当前是 dummy 模式
            sudo touch "$dummy_backup"
            echo "[*] 已标记为无头（虚拟显示器）模式。"
        else
            echo "[-] 无法写入虚拟显示器配置。"
            return 1
        fi
    fi

    echo ""
    echo -e "${GREEN}[+] x11vnc 配置完成！${NC}"
    echo "    - 服务已启用，开机自启。"
    echo "    - VNC 端口: 5900"
    echo "    - 使用 'sudo systemctl start x11vnc' 可立即启动服务（无需重启）。"

    # 提示重启（仅当切换了显示模式时才强烈建议）
    if [[ "$has_display" == false ]] || [[ -f "$dummy_backup" && "$has_display" == true ]]; then
        echo ""
        read -p "[?] 为使显示配置生效，建议重启系统。是否现在重启？(Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "[*] 正在重启..."
            sudo reboot
        else
            echo "[*] 请在方便时手动执行 'sudo reboot'。"
        fi
    fi
}

# --- 新增并完善的 SSH 控制功能函数 ---
perform_ssh_control() {
    echo "[*] SSH 访问控制功能"

    # 1. 检查 openssh-server 是否安装
    if ! dpkg -l | grep -q "^ii.*openssh-server"; then
        echo -e "${YELLOW}[!] 检测到未安装 openssh-server 包。${NC}"
        read -p "[?] 是否现在安装 openssh-server? (按 Y 确认, 其他键跳过): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "[*] 正在安装 openssh-server..."
            if sudo apt update && sudo apt install -y openssh-server; then
                echo -e "${GREEN}[+] openssh-server 安装成功。${NC}"
            else
                echo -e "${RED}[-] openssh-server 安装失败。${NC}"
                return 1 # 安装失败则退出函数
            fi
        else
            echo "[*] 已跳过安装。部分功能可能受限。"
        fi
    else
        echo -e "${GREEN}[+] 检测到已安装 openssh-server 包。${NC}"
    fi

    # 2. 检查 ssh 服务状态 (即使未安装也可能有残留状态)
    local ssh_service_status
    ssh_service_status=$(systemctl is-active ssh 2>/dev/null || echo "unknown")

    echo "    当前 SSH 服务状态:"
    if [[ "$ssh_service_status" == "active" ]]; then
        echo -e "    ${GREEN}● ssh.service - OpenBSD Secure Shell server (Active: active (running))${NC}"
    elif [[ "$ssh_service_status" == "inactive" ]]; then
        echo -e "    ${YELLOW}● ssh.service - OpenBSD Secure Shell server (Active: inactive (dead))${NC}"
    else
        echo -e "    ${YELLOW}● ssh.service - OpenBSD Secure Shell server (状态: 未知或未找到)${NC}"
    fi

    echo ""
    echo "选项:"
    echo "1) 启用并启动 SSH 服务"
    echo "2) 停止并禁用 SSH 服务"
    echo "3) 查看 SSH 服务详细状态"
    echo "0) 返回上一级菜单"
    echo "----------------------------------"
    read -p "请选择操作 (0-3): " ssh_action

    case "$ssh_action" in
        1)
            echo "[*] 正在启用并启动 SSH 服务..."
            if sudo systemctl enable ssh --now; then
                 echo -e "${GREEN}[+] SSH 服务已启用并启动。${NC}"
                 # 获取 IP 地址提示用户
                 local ip_addresses
                 ip_addresses=$(hostname -I 2>/dev/null || echo "")
                 if [[ -n "$ip_addresses" ]]; then
                     echo "[*] 您可以通过以下地址之一连接到此设备的 SSH:"
                     for ip in $ip_addresses; do
                         echo "    ssh kali@$ip"
                     done
                 else
                      echo "[*] 请使用 'ifconfig' 或 'ip addr' 命令查找本机IP地址。"
                 fi
                 echo "[!] 默认用户名通常是 'kali'，密码为您设置的密码。"
            else
                 echo -e "${RED}[-] 启用或启动 SSH 服务失败。${NC}"
            fi
            ;;
        2)
             echo "[*] 正在停止并禁用 SSH 服务..."
             if sudo systemctl disable ssh --now; then
                  echo -e "${GREEN}[+] SSH 服务已停止并禁用。${NC}"
             else
                  echo -e "${RED}[-] 停止或禁用 SSH 服务失败。${NC}"
             fi
             ;;
        3)
             echo "[*] 正在显示 SSH 服务详细状态..."
             echo "----------------------------------"
             sudo systemctl status ssh --no-pager || echo "无法获取 SSH 服务状态。"
             echo "----------------------------------"
             ;;
        0)
             echo "[*] 返回远程访问菜单。"
             return 0
             ;;
        *)
             echo -e "${RED}[-] 无效选项: $ssh_action${NC}"
             sleep 1
             ;;
    esac
}
# ----------------------------

# --- 更新脚本功能 (增加国内镜像 + 改进版本比较 + 优化提示 + 修复版本提取) ---
perform_script_update() {
    local repo_owner="lhl77"
    local repo_name="kali-raspi-tool"
    local script_name="main.sh"

    # 定义多个下载源 URL，包括镜像和官方
    local urls=(
        "https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name" # 官方源
        "https://ghproxy.net/https://raw.githubusercontent.com/$repo_owner/$repo_name/main/$script_name"
    )

    echo "[*] 正在从 GitHub ($repo_owner/$repo_name) 检查更新..."
    echo "[*] 当前脚本版本: $SCRIPT_VERSION"

    local download_success=0
    local temp_script
    temp_script=$(mktemp)

    # 尝试从各个源下载
    for url in "${urls[@]}"; do
        echo "[*] 尝试从源: $url 下载..."
        if curl -s -m 15 -o "$temp_script" "$url"; then # -m 15 设置超时时间为15秒
            # 检查下载的文件是否包含脚本标识，以验证下载是否成功且是正确的文件
            if grep -q "Kali Linux 树莓派脚本" "$temp_script"; then
                echo "[+] 成功从源 $url 下载脚本。"
                download_success=1
                break # 下载成功则跳出循环
            else
                echo "[-] 从源 $url 下载的内容似乎不是有效的脚本。"
            fi
        else
            echo "[-] 从源 $url 下载失败或超时。"
        fi
    done

    if [[ $download_success -eq 1 ]]; then
        echo "[*] 找到新版本脚本。"

        # --- 修改版本提取逻辑 ---
        # 直接查找包含 SCRIPT_VERSION= 定义的行，这行包含了实际的版本号
        local remote_version_line=$(grep -m 1 '^SCRIPT_VERSION=' "$temp_script")
        #echo "[DEBUG] 匹配到的远程版本行: '$remote_version_line'" # 调试输出

        local remote_version=""
        if [[ -n "$remote_version_line" ]]; then
            # 从 SCRIPT_VERSION="vx.x.x" 格式的行中提取双引号内的版本号
            remote_version=$(echo "$remote_version_line" | sed -n 's/.*SCRIPT_VERSION="\([^"]*\)".*/\1/p')
            #echo "[DEBUG] 提取的版本号: '$remote_version'" # 调试输出
        fi
        # --- 结束修改 ---

        if [[ -n "$remote_version" ]]; then
            echo "[*] 远程脚本版本: $remote_version"

            # 使用 sort -V 进行版本号比较
            local version_list=$(printf '%s\n%s' "$SCRIPT_VERSION" "$remote_version" | sort -V)
            local latest_version=$(echo "$version_list" | tail -n 1)

            # --- 修改提示逻辑 ---
            if [[ "$latest_version" == "$remote_version" ]] && [[ "$SCRIPT_VERSION" != "$remote_version" ]]; then
                echo -e "${YELLOW}[*] 发现新版本: $remote_version${NC}" # 黄色提示发现新版本
                local REPLY
                read -p "[?] 是否更新当前脚本 (当前版本: $SCRIPT_VERSION)？(按 Y 确认, 其他键跳过): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # 将临时文件移动到当前脚本位置，覆盖原脚本
                    local current_script_path="$0"
                    if mv "$temp_script" "$current_script_path"; then
                        chmod +x "$current_script_path"
                        echo -e "${GREEN}[+] 脚本更新成功！新版本: $remote_version${NC}"
                        echo "[*] 请重新运行脚本以应用更新。"
                        # 询问用户是否立即退出以便重新运行
                        read -p "[?] 是否现在退出脚本以便重新运行？(按 Y 确认, 其他键继续): " -n 1 -r
                        echo
                        if [[ $REPLY =~ ^[Yy]$ ]]; then
                            exit 0
                        fi
                    else
                        echo "[-] 覆盖脚本文件失败。"
                        rm -f "$temp_script" # 清理临时文件
                    fi
                else
                    echo "[*] 已跳过脚本更新。"
                    rm -f "$temp_script" # 清理临时文件
                fi
            elif [[ "$SCRIPT_VERSION" == "$remote_version" ]]; then
                echo -e "${GREEN}[+] 当前已是最新版本 ($SCRIPT_VERSION)。${NC}" # 绿色提示已是最新版
                rm -f "$temp_script" # 清理临时文件
            else
                # 理论上不太可能发生，但为了完整性考虑
                echo "[*] 检测到的版本 ($remote_version) 不比当前版本 ($SCRIPT_VERSION) 新。"
                echo -e "${GREEN}[+] 当前版本 ($SCRIPT_VERSION) 似乎比检测到的版本 ($remote_version) 更新。${NC}"
                rm -f "$temp_script" # 清理临时文件
            fi
            # --- 结束修改 ---
        else
            echo "[-] 无法从远程脚本中解析出有效的版本号。"
            echo "    远程脚本可能存在格式问题，或版本号格式不兼容。"
            rm -f "$temp_script" # 清理临时文件
        fi
    else
        echo "[-] 所有尝试的源都无法下载有效的脚本。请检查网络连接或稍后再试。"
        rm -f "$temp_script" # 清理临时文件
    fi
}
# ----------------------------

# --- 主程序入口 ---
check_privileges
check_system_version

# 主循环
while true; do
    show_main_menu
    case "$main_choice" in
        1)
            while true; do
                show_system_menu
                case "$system_choice" in
                    1)
                        perform_chinese_setup
                        read -p "按回车键返回系统设置菜单..."
                        ;;
                    0)
                        break
                        ;;
                    *)
                        echo "[-] 无效选项: $system_choice"
                        sleep 1
                        ;;
                esac
            done
            ;;
        2)
            while true; do
                show_remote_menu
                case "$remote_choice" in
                    1)
                        perform_x11vnc_setup
                        read -p "按回车键返回远程访问菜单..."
                        ;;
                    # --- 新增 SSH 功能分支 ---
                    2)
                        perform_ssh_control
                        read -p "按回车键返回远程访问菜单..."
                        ;;
                    # --------------------------
                    0)
                        break
                        ;;
                    *)
                        echo "[-] 无效选项: $remote_choice"
                        sleep 1
                        ;;
                esac
            done
            ;;
        3)
            perform_script_update
            read -p "按回车键返回主菜单..."
            ;;
        0)
            echo "[*] 退出脚本。再见！"
            exit 0
            ;;
        *)
            echo "[-] 无效选项: $main_choice"
            sleep 1
            ;;
    esac
done
