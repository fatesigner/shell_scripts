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
  if [ ! -f "/usr/local/etc/v2ray/config.json" ]; then
	  bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
  fi
  # config
  cat <<EOT > /usr/local/etc/v2ray/config.json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-origin",
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
          "alpn": [
            "http/1.1"
          ],
          "certificates": [
            {
              "certificateFile": "/usr/local/etc/v2ray/ssl/v2ray.crt",
              "keyFile": "/usr/local/etc/v2ray/ssl/v2ray.key"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked"
      }
    ]
  }
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
    mkdir -p /usr/local/etc/v2ray/ssl/

	  ~/.acme.sh/acme.sh --install-cert --ecc -d "$host" \
    --keypath /usr/local/etc/v2ray/ssl/v2ray.key  \
    --fullchainpath /usr/local/etc/v2ray/ssl/v2ray.crt

	  chown -R nobody:nogroup /usr/local/etc/v2ray/ssl/
  fi
}

if [ "${host}" ]; then
  apt update
  apt install curl

  installCer
  installV2ray
  installNginx

  systemctl daemon-reload
  systemctl enable v2ray
  systemctl restart v2ray
  systemctl restart nginx

  echo -e "${Info} the host is $host $UUID"
fi
