#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[info]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"

export UUID=''
export host=''
export dns='dns_ali'
export tmpWORD=''
export tmpMirror=''

# create uuid
#$UUID=`sudo head /dev/urandom | tr -dc a-z0-9- | head -c 36 ; echo ''`
UUID=$(cat /proc/sys/kernel/random/uuid)

while [[ $# -ge 1 ]]; do
  case $1 in
    -u|--uuid)
      shift
      UUID="$1"
      shift
      ;;
    -d)
      shift
      host="$1"
      shift
      ;;
    --dns)
      shift
      dns="$1"
      shift
      ;;
    *)
      if [[ "$1" != 'error' ]]; then echo -ne "\nInvaild option: '$1'\n\n"; fi
      echo -ne " Usage:\n\tbash $(basename "$0")\t-u/--uuid [\033[33m\033[04mclient id\033[0m]\n\t\t\t\t-h/--host [\033[33m\033[04mhttps host name\033[0m]\n\t\t\t\t-h/--dns [\033[33m\033[04mDNS API\033[0m]\n\t\t\t\t\n"
      exit 1;
      ;;
    esac
  done

# check if run as root
[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;

echo -e "${Info} UUID：$UUID"
echo -e "${Info} host：$host"
echo -e "${Info} dns：$dns"

# check host empty
if [ -z "$host" ]; then
  echo -e "${Error} The host can not be empty."
  exit 1
fi

# read -t 30 -p "input the host:" host

function installV2ray(){
  echo -e "${Info} install v2Ray"
  if [ ! -f "/usr/local/etc/v2ray/config.json" ]; then
    apt update
    apt install curl
    curl -O https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
    bash install-release.sh
  fi
  # config
  cat <<EOT > /usr/local/etc/v2ray/config.json
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbound": {
    "port": 1090,
    "listen": "127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$UUID",
          "alterId": 64
        }
      ]
    },
    "streamSettings": {
      "network": "ds",
      "dsSettings": {
        "path": "/var/lib/haproxy/v2ray/v2ray.sock"
      }
    }
  },
  "outbound": {
    "protocol": "freedom",
    "settings": {}
  },
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "outboundTag": "blocked"
        }
      ]
    }
  }
}
EOT

  # 创建用于运行v2ray的用户，且不允许执行解释器
  useradd v2ray -s /usr/sbin/nologin
  chown -R v2ray:v2ray /var/log/v2ray
  #修改v2ray.service文件，加入User和Group两项
  cat <<EOT > /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray - A unified platform for anti-censorship
Documentation=https://v2ray.com https://guide.v2fly.org
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
# If the version of systemd is 240 or above, then uncommenting Type=exec and commenting out Type=simple
#Type=exec
Type=simple
# Runs as root or add CAP_NET_BIND_SERVICE ability can bind 1 to 1024 port.
# This service runs as root. You may consider to run it as another user for security concerns.
# By uncommenting User=v2ray and commenting out User=root, the service will run as user v2ray.
# More discussion at https://github.com/v2ray/v2ray-core/issues/1011
#User=root
User=v2ray
Group=v2ray
CapabilityBoundingSet=CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=yes

ExecStartPre=/usr/bin/mkdir -p /var/lib/haproxy/v2ray/
ExecStartPre=/usr/bin/rm -rf /var/lib/haproxy/v2ray/*.sock

ExecStart=/usr/local/bin/v2ray -config /usr/local/etc/v2ray/config.json

ExecStartPost=/usr/bin/sleep 1
ExecStartPost=/usr/bin/chmod 777 /var/lib/haproxy/v2ray/v2ray.sock

Restart=on-failure
# Don't restart in the case of configuration error
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOT

}

function installHaproxy(){
  if [ ! -f "/etc/haproxy/haproxy.cfg" ]; then
    apt install haproxy
  fi
  if [ ! -x "/etc/haproxy/ssl" ]; then
    # 为 haproxy 生成证书
    mkdir -p /etc/haproxy/ssl/
  fi
  cat /root/.acme.sh/"$host"/fullchain.cer /root/.acme.sh/"$host"/"$host".key > /etc/haproxy/ssl/"$host".pem
  cat <<EOT > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    ca-base /etc/ssl/certs
    crt-base /etc/ssl/private

    # 仅使用支持 FS 和 AEAD 的加密套件
    ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
    ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
    # 禁用 TLS 1.2 之前的 TLS
    ssl-default-bind-options no-sslv3 no-tlsv10 no-tlsv11

    tune.ssl.default-dh-param 2048

defaults
    log global
    # 我们需要使用 tcp 模式
    mode tcp
    option dontlognull
    timeout connect 5s
    # 空闲连接等待时间，这里使用与 V2Ray 默认 connIdle 一致的 300s
    timeout client  300s
    timeout server  300s

frontend tls-in
    # 监听 443 tls，tfo 根据自身情况决定是否开启，证书放置于 /etc/ssl/private/example.com.pem
    bind *:443 tfo ssl crt /etc/haproxy/ssl/$host.pem
    tcp-request inspect-delay 5s
    tcp-request content accept if HTTP
    # 将 HTTP 流量发给 web 后端
    use_backend web if HTTP
    # 将其他流量发给 vmess 后端
    default_backend vmess

backend web
    server server1 127.0.0.1:8080

backend vmess
    # 填写 chroot 后的路径
    server server1 /v2ray/v2ray.sock
EOT
}

function installNginx(){
  echo -e "${Info} install nginx"
  if [ ! -f "/etc/nginx/nginx.conf" ]; then
    apt install nginx
  fi
  cat <<EOT > /etc/nginx/nginx.conf
# For more formation on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/
user root;
worker_processes  auto;
worker_rlimit_nofile 100000;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
  worker_connections 2048;
  multi_accept       on;
  use                epoll;
}

http {
  charset           UTF-8;
  include           /etc/nginx/mime.types;
  default_type      application/octet-stream;
  log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                     '"\$http_user_agent" "\$http_x_forwarded_for"';

  access_log         /var/log/nginx/access.log  main;
  error_log          /var/log/nginx/error.log crit;
  sendfile           on;
  server_tokens      off;
  tcp_nopush         on;
  tcp_nodelay        on;
  keepalive_timeout          10;
  client_header_timeout      10;
  client_body_timeout        10;
  send_timeout               10;
  reset_timedout_connection  on;
  limit_conn_zone            \$binary_remote_addr zone=addr:5m;
  limit_conn addr            100;
  client_max_body_size       10m;

  open_file_cache max=100000 inactive=20s;
  open_file_cache_valid      30s;
  open_file_cache_min_uses   2;
  open_file_cache_errors     on;

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;

  # Settings for a TLS enabled server.
  server {
    listen              8080;
    server_name  $host;

    root               /usr/share/nginx/html;

    error_page 404 /404.html;
      location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
      location = /50x.html {
    }
  }
}
EOT
}

function installCer(){
  if [ ! -f "/root/.acme.sh/$host/$host.key" ]; then
    bash <(curl -L -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/certification/certification.sh) -d "$host" --dns "$dns"
  fi
}

if [ "${host}" ]; then
  echo -e "${Info} the host is $host $UUID"
  installCer
  installV2ray
  installHaproxy
  installNginx
  
  if [ ! -x "/var/lib/haproxy/v2ray" ]; then
    mkdir /var/lib/haproxy/v2ray
  fi
  chown v2ray:v2ray /var/lib/haproxy/v2ray
  systemctl daemon-reload
  systemctl enable v2ray
  systemctl restart v2ray
  systemctl restart haproxy
  systemctl restart nginx
fi