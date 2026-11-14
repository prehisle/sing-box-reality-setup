# sing-box-reality-setup

用 [233boy/sing-box](https://github.com/233boy/sing-box) 脚本一键部署 VLESS + Reality 节点。

## 安装

```bash
curl -fsSL https://raw.githubusercontent.com/prehisle/sing-box-reality-setup/main/install.sh | bash
```

自定义参数:

```bash
curl -fsSL https://raw.githubusercontent.com/prehisle/sing-box-reality-setup/main/install.sh | bash -s -- --port 443 --sni www.microsoft.com
```

| 选项 | 默认 | 说明 |
|---|---|---|
| `--port PORT` | `2066` | 监听端口 |
| `--uuid UUID` | 自动生成 | 用户 UUID |
| `--sni HOST` | `www.amazon.com` | 伪装域名(serverName) |
| `--uninstall` | | 卸载 sing-box 及全部配置 |

脚本会:

1. 通过 233boy 官方脚本安装 sing-box(如未安装)。
2. 删除安装器自动生成的 Hysteria2 默认节点。
3. 添加 VLESS-Reality 节点,Reality 密钥由 sing-box 自动生成。
4. 输出 `vless://` 链接。

## 注意

- **每次安装生成的密钥和链接都不同**。脚本不会复现已有服务器的节点,要迁移旧节点需要原服务器的私钥,脚本不处理。
- 云厂商安全组需放行对应的 TCP 端口。
- 只在你有权管理的服务器上使用,并遵守当地法律和服务商条款。
- 管理命令:`sing-box`(菜单)、`sing-box info`、`sing-box url`、`sing-box restart`。
