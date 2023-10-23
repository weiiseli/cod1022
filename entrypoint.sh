#!/usr/bin/env bash

# 设置各变量
UUID='34477103-9790-4091-b320-25bd02de3d4c'
VMESS_WSPATH='/vmess'
VLESS_WSPATH='/vless'
TROJAN_WSPATH='/trojan'
SS_WSPATH='/shadowsocks'
NEZHA_SERVER=''
NEZHA_PORT=''
NEZHA_KEY=''
NEZHA_TLS='1'

# 检查 wget 命令
check_wget() {
  ISWGET=0 && [ "$(type -p wget)" ] && ISWGET=1
}

generate_config() {
  cat > config.json << EOF
{
    "log": {
        "access": "/dev/null",
        "error": "/dev/null",
        "loglevel": "none"
    },
    "inbounds": [
        {
            "port": 8080,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "flow": "xtls-rprx-vision"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 3001
                    },
                    {
                        "path": "${VLESS_WSPATH}",
                        "dest": 3002
                    },
                    {
                        "path": "${VMESS_WSPATH}",
                        "dest": 3003
                    },
                    {
                        "path": "${TROJAN_WSPATH}",
                        "dest": 3004
                    },
                    {
                        "path": "${SS_WSPATH}",
                        "dest": 3005
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp"
            }
        },
        {
            "port": 3001,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none"
            }
        },
        {
            "port": 3002,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "level": 0
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "${VLESS_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ],
                "metadataOnly": false
            }
        },
        {
            "port": 3003,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "${UUID}",
                        "alterId": 0
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "${VMESS_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ],
                "metadataOnly": false
            }
        },
        {
            "port": 3004,
            "listen": "127.0.0.1",
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "${UUID}"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "${TROJAN_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ],
                "metadataOnly": false
            }
        },
        {
            "port": 3005,
            "listen": "127.0.0.1",
            "protocol": "shadowsocks",
            "settings": {
                "clients": [
                    {
                        "method": "chacha20-ietf-poly1305",
                        "password": "${UUID}"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "${SS_WSPATH}"
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ],
                "metadataOnly": false
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom",
            "settings": {}
        },
        {
            "tag": "WARP",
            "protocol": "wireguard",
            "settings": {
                "secretKey": "GAl2z55U2UzNU5FG+LW3kowK+BA/WGMi1dWYwx20pWk=",
                "address": [
                    "172.16.0.2/32",
                    "2606:4700:110:8f0a:fcdb:db2f:3b3:4d49/128"
                ],
                "peers": [
                    {
                        "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=",
                        "endpoint": "engage.cloudflareclient.com:2408"
                    }
                ]
            }
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "domain": [
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag": "WARP"
            }
        ]
    },
    "dns": {
        "server": [
            "8.8.8.8",
            "8.8.4.4"
        ]
    }
}
EOF
}

generate_web() {
  cat > web.sh << EOF
#!/usr/bin/env bash

check_file() {
  [ ! -e web.js ] && wget -O web.js https://gitlab.com/Misaka-blog/xray-for-nodejs/-/raw/main/web.js
}

run() {
  chmod +x web.js && ./web.js -c ./config.json >/dev/null 2>&1 &
}

check_file
run
EOF
}

generate_nezha() {
  cat > nezha.sh << EOF
#!/usr/bin/env bash

# 哪吒的4个参数
NEZHA_SERVER="$NEZHA_SERVER"
NEZHA_PORT="$NEZHA_PORT"
NEZHA_KEY="$NEZHA_KEY"
NEZHA_TLS="$NEZHA_TLS"

# 检测是否已运行
check_run() {
  pidof -q nezha-agent && echo "哪吒客户端正在运行中!" && exit
}

# 三个变量不全则不安装哪吒客户端
check_variable() {
  [[ -z "\${NEZHA_SERVER}" || -z "\${NEZHA_PORT}" || -z "\${NEZHA_KEY}" ]] && exit
}

# 下载最新版本 Nezha Agent
download_agent() {
  if [ ! -e nezha-agent ]; then
    if [ "$ISWGET" = 1 ]; then
      URL=\$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
      wget -t 2 -T 10 -N \${URL}
      unzip -qod ./ nezha-agent_linux_amd64.zip && rm -f nezha-agent_linux_amd64.zip
    else
      echo " wget is not found. "
    fi
  fi
  chmod +x nezha-agent
}

# 运行客户端
run() {
  TLS=\${NEZHA_TLS:+'--tls'}
  [[ ! \$PROCESS =~ nezha-agent && -e nezha-agent ]] && ./nezha-agent -s \${NEZHA_SERVER}:\${NEZHA_PORT} -p \${NEZHA_KEY} \${TLS} 2>&1 &
}

check_run
check_variable
download_agent
run
EOF
}

check_wget
generate_config
generate_web
generate_nezha

[ -e web.sh ] && bash web.sh
[ -e nezha.sh ] && bash nezha.sh