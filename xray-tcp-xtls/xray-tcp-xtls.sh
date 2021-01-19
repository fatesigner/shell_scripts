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
# shellcheck disable=SC2034
psd="/proc/sys/kernel/random/uuid"
UUID=$(cat /proc/sys/kernel/random/uuid)

while [[ $# -ge 1 ]]; do
  case $1 in
    -u|--uuid)
      shift
      UUID="$1"
      shift
      ;;
    -h|--host)
      shift
      host="$1"
      shift
      ;;
    -d|--dns)
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

  if [ ! -f "/usr/local/etc/xray/config.json" ]; then
	  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
  fi

  mkdir -p /usr/local/etc/xray/logs
  chown -R nobody:nogroup /usr/local/etc/xray/logs

  # config
  cat <<EOT > /usr/local/etc/xray/config.json
{
  "log": {
    "loglevel": "warning",
    "access": "/usr/local/etc/xray/logs/access.log",
    "error": "/usr/local/etc/xray/logs/error.log"
  },
  "dns": {
    "servers": [
      "https+local://1.1.1.1/dns-query",
      "localhost"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      },
      {
        "type": "field",
        "domain": [
          "geosite:category-ads-all"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-direct",
            "level": 0
          }
        ],
        "decryption": "none",
        "fallbacks": [
          {
            "dest": 80
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "xtls",
        "xtlsSettings": {
          "allowInsecure": false,
          "minVersion": "1.2",
          "alpn": [
            "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "/usr/local/etc/xray/ssl/xray.crt",
              "keyFile": "/usr/local/etc/xray/ssl/xray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ]
}
EOT

}

function installNginx(){
  echo -e "${Info} install nginx"
  if [ ! -f "/etc/nginx/nginx.conf" ]; then
    apt install gnupg2 ca-certificates lsb-release
	  # shellcheck disable=SC2006
	  echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
	  curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
	  apt-key fingerprint ABF5BD827BD9BF62
	  apt update
    apt install nginx
  fi
}

function installCer(){
  if [ ! -f "/root/.acme.sh/$host/$host.key" ]; then
	  bash <(curl -L -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/certification/certification.sh) -d "$host" --dns "$dns"

	  # 转移证书至 nginx
    mkdir -p /usr/local/etc/xray/ssl/

	  ~/.acme.sh/acme.sh --install-cert --ecc -d "$host" \
    --keypath /usr/local/etc/xray/ssl/xray.key  \
    --fullchainpath /usr/local/etc/xray/ssl/xray.crt \
    --reloadcmd "systemctl restart xray"

    chown -R nobody:nogroup /usr/local/etc/xray/ssl
	  chown -R nobody:nogroup /usr/local/etc/xray/ssl/xray.crt
	  chown -R nobody:nogroup /usr/local/etc/xray/ssl/xray.key
  fi
}

if [ "${host}" ]; then
  apt update
  apt install curl

  installCer
  installV2ray
  installNginx

  systemctl daemon-reload
  systemctl enable xray
  systemctl restart xray
  systemctl restart nginx

  echo -e "${Info} the host is $host $UUID"
fi
