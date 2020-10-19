# VLESS：TCP + XTLS
## To view the details goto [VLESS](https://www.v2fly.org/config/protocols/vless.html#outboundconfigurationobject) 

## How to install

```bash
curl -L -O -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/vless-tcp-xtls/vless-tcp-xtls.sh
chmod +x ./vless-tcp-xtls.sh
```

### before use
> Choose your dns verification mode, set the dns key and secret.

```bash
# dns_ali
export Ali_Key="1234"
export Ali_Secret="sADDsdasdgdsf"

# dnspod
export DP_Id="1234"
export DP_Key="sADDsdasdgdsf"
```

### then 

```bash
bash ./vless-tcp-xtls.sh \
--host       [your host name]  \
--dns     [dns_ali or dns_dp]
--uuid    [v2ray client id, optional]

# example
bash ./vless-tcp-xtls.sh --host asd.xyz.com --dns dns_ali --uuid e78b8e2c-85cd-4b33-847b-7ec741231d9a
```

## Tested OS
| Platform | Status|
|----|-------|
|Debian|passing
|Ubuntu|passing

# root
```bash
sudo passwd
su - root
```

# v2ray

```bash
# config location
vi /usr/local/etc/v2ray/config.json

# test config
/usr/local/bin/v2ray -test -config /usr/local/etc/v2ray/config.json

# restart
systemctl daemon-reload 
systemctl enable v2ray
systemctl start v2ray
systemctl disable v2ray
systemctl stop v2ray
systemctl restart v2ray
service v2ray status
```

# nginx
```bash
# config location
vi /etc/nginx/nginx.conf

# test config
nginx -c /etc/nginx/nginx.conf -t

# restart
systemctl restart nginx.service || systemctl status nginx.service
systemctl restart nginx || systemctl nginx status
service nginx restart || service nginx status
```

# ssh
```bash
vim /etc/ssh/sshd_config
/etc/init.d/ssh restart
systemctl restart sshd
```

# bbr
```bash
apt install wget
wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh"
chmod +x tcp.sh
./tcp.sh
```

# return trip
```bash
apt install mtr
mtr -rTn [your local ip]
```

# speedtest
```bash
apt-get install python-pip
pip install speedtest-cli
pip install speedtest-cli –-upgrade
speedtest-cli
```
