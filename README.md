# 🛠️ kali-raspi-tool — 树莓派 Kali Linux 脚本工具箱

> 一个专为 **Kali Linux on Raspberry Pi** 设计的一键式配置与管理脚本，简化系统汉化、远程访问、硬件驱动安装等常见操作。

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![Platform: Raspberry Pi](https://img.shields.io/badge/Platform-Raspberry%20Pi-orange)
![OS: Kali Linux](https://img.shields.io/badge/OS-Kali%20Linux-red)

---

## ✨ 功能概览

### 🖥️ 系统设置
- **系统汉化**：一键切换为简体中文（含中文字体安装）
- **完整工具集**：安装 `kali-linux-everything` 元包（所有渗透测试工具）

### 🌐 远程访问
- **x11vnc 配置**：自动部署 VNC 服务（端口 5900），支持图形界面远程控制
- **SSH 控制**：启用/禁用 SSH 服务，查看状态
- **无头模式切换**：在有显示器和无显示器（虚拟显示）模式间切换，适配 VNC 无头使用场景

### 🔌 外设/驱动支持
- **0.91 英寸 OLED 屏幕**：I2C 接口，自动安装驱动并后台运行监控脚本（CPU 温度、IP 等）
- **YAHBOOM HAT RGB 温控风扇**：根据 CPU 温度智能调节风扇转速 + RGB 灯效联动

### 🔄 自动更新
- **一键检查并更新脚本**：从 GitHub 主分支拉取最新版本，无缝升级

---

## 🚀 快速开始

### 前提条件
- 已刷入 **Kali Linux for Raspberry Pi**
- 设备已联网
- 用户具有 `sudo` 权限

### 安装与运行

```bash
# 下载脚本
wget https://raw.githubusercontent.com/lhl77/kali-raspi-tool/main/kali_raspi.sh

# 添加执行权限
chmod +x kali_raspi.sh

# 运行（需 root 或 sudo 权限）
sudo ./kali_raspi.sh
