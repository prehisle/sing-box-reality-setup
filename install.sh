#!/usr/bin/env bash
# sing-box-reality-setup: 用 233boy/sing-box 脚本一键部署 VLESS + Reality 节点
#
# 安装: curl -fsSL https://raw.githubusercontent.com/prehisle/sing-box-reality-setup/main/install.sh | bash
# 自定义: ... | bash -s -- --port 443 --sni www.microsoft.com
# 卸载: ... | bash -s -- --uninstall
# 选项: --port PORT   监听端口(默认 2066)
#       --uuid UUID   用户 UUID(默认自动生成)
#       --sni HOST    伪装域名 serverName(默认 www.amazon.com)
#       --uninstall   卸载 sing-box 及其配置
#
# 注意: Reality 的私钥/公钥由 sing-box 自动生成,每次安装的节点链接都不同。
#       只在你有权管理的服务器上使用。
set -euo pipefail

SB_INSTALL_URL="https://github.com/233boy/sing-box/raw/main/install.sh"
PORT="2066"
UUID="auto"
SNI="www.amazon.com"
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --port) PORT="${2:?--port 需要参数}"; shift 2 ;;
    --uuid) UUID="${2:?--uuid 需要参数}"; shift 2 ;;
    --sni) SNI="${2:?--sni 需要参数}"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help) echo "用法: install.sh [--port PORT] [--uuid UUID] [--sni HOST] [--uninstall]"; exit 0 ;;
    *) echo "未知参数: $1" >&2; exit 1 ;;
  esac
done

err() { echo "错误: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || err "需要 root 权限,请用 root 运行"
command -v systemctl >/dev/null 2>&1 || err "需要 systemd"
case "$(uname -m)" in x86_64|amd64|aarch64|arm64) ;; *) err "仅支持 x86_64 / aarch64" ;; esac

if [ "$UNINSTALL" -eq 1 ]; then
  if command -v sing-box >/dev/null 2>&1; then
    echo "==> 卸载 sing-box"
    printf 'y\n' | sing-box uninstall
  else
    echo "==> 未检测到 sing-box,无需卸载"
  fi
  exit 0
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
  err "端口无效: $PORT"
fi
if ! [[ "$SNI" =~ ^[A-Za-z0-9.-]+$ ]]; then
  err "--sni 只能包含字母、数字、. 和 -"
fi
if [ "$UUID" != "auto" ] && ! [[ "$UUID" =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]]; then
  err "UUID 格式不正确: $UUID"
fi

if ss -lnt 2>/dev/null | awk '{print $4}' | grep -q ":$PORT\$"; then
  err "端口 $PORT 已被占用,请换一个端口(--port)"
fi

if ! command -v sing-box >/dev/null 2>&1 || [ ! -d /etc/sing-box ]; then
  echo "==> 安装 sing-box(233boy 脚本)"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL "$SB_INSTALL_URL" -o "$tmp/install.sh"
  # 233boy 安装器结束时的退出码不可靠,以下面的命令检查为准
  bash "$tmp/install.sh" || true
else
  echo "==> 已安装 sing-box,跳过安装"
fi

command -v sing-box >/dev/null 2>&1 || err "安装后未找到 sing-box 命令"

# 233boy 安装器会自动创建一个 Hysteria2 默认节点,这里删除它,只保留我们要的节点
for f in /etc/sing-box/conf/Hysteria2-*.json; do
  [ -e "$f" ] || continue
  echo "==> 删除安装器自动生成的默认节点: $(basename "$f")"
  printf 'y\n' | sing-box del "$(basename "$f" .json)" >/dev/null 2>&1 || true
  [ -e "$f" ] && err "无法删除默认节点: $f"
done

echo "==> 添加 VLESS-Reality 配置 (端口 $PORT, SNI $SNI)"
sing-box add reality "$PORT" "$UUID" "$SNI"

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
  echo "==> ufw 已启用,放行 $PORT/tcp"
  ufw allow "$PORT/tcp" >/dev/null
fi

echo "==> 完成。节点链接:"
sing-box url || true
echo ""
echo "提示: 云厂商安全组也需要放行 TCP $PORT。"
echo "管理命令: sing-box (菜单) | sing-box info | sing-box url | sing-box restart"
