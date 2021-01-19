# XRAY：TCP
## To view the details goto [XRAY](https://github.com/XTLS/Xray-core) 

## How to install

```bash
curl -L -O -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/xray-tcp-xtls/xray-tcp-xtls.sh
chmod +x ./xray-tcp-xtls.sh
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
bash ./xray-tcp-xtls.sh \
--host       [your host name]  \
--dns     [dns_ali or dns_dp]
--uuid    [xray client id, optional]

# example
bash ./xray-tcp-xtls.sh --host asd.xyz.com --dns dns_ali --uuid e78b8e2c-85cd-4b33-847b-7ec741231d9a
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

# xray

```bash
# config location
vi /usr/local/etc/xray/config.json

# test config
/usr/local/bin/xray -test -config /usr/local/etc/xray/config.json

# restart
systemctl daemon-reload 
systemctl enable xray
systemctl start xray
systemctl disable xray
systemctl stop xray
systemctl restart xray
service xray status
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
