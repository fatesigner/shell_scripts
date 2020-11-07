#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[info]${Font_color_suffix}"
Error="${Red_font_prefix}[error]${Font_color_suffix}"

export hostArr=()
export dns=''
export debug=''

while [[ $# -ge 1 ]]; do
  case $1 in
  -d)
    shift
    hostArr+=("$1")
    shift
    ;;
  --dns)
    shift
    dns="$1"
    shift
    ;;
  *)
    if [[ "$1" != 'error' ]]; then echo -ne "\nInvalid option: '$1'\n\n"; fi
    echo -ne "Usage:\n\t bash $(basename "$0")\t-d/--host [\033[33m\033[04m https host name\033[0m]\n\t\t\t\t-h/--dns  [\033[33m\033[04mDNS API\033[0m]\n\t\t\t\t\n"
    exit 1
    ;;
  esac
done

# check if run as root
[[ "$EUID" -ne '0' ]] && echo -e "${Error} This script must be run as root." && exit 1

# check if empty
if [ -z "$dns" ]; then
  echo -e "${Error} The dns can not be empty."
  exit 1
fi

if ((${#hostArr[@]})); then
  echo
else
  echo -e "${Error} The host can not be empty."
  exit 1
fi

hostCMD=()
for t in "${hostArr[@]}"; do
  hostCMD+=(-d "$t")
done

function installCer() {
  apt install socat -y
  curl https://get.acme.sh | sh
  ~/.acme.sh/acme.sh --upgrade --auto-upgrade
  ~/.acme.sh/acme.sh --issue --debug --keylength ec-256 --dns "$dns" "${hostCMD[@]}"

}

echo -e "${Info} dns：$dns"
echo -e "${Info} host：" "${hostArr[@]}"
installCer