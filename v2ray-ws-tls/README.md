# v2ray：TCP + TLS + Web
## To view the details goto [tcp_tls_web](https://guide.v2fly.org/advanced/tcp_tls_web.html) 

## How to install

```bash
curl -L -O -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/v2ray-ws-tls/v2ray-ws-tls.sh
chmod +x ./v2ray-ws-tls.sh
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
bash ./v2ray-ws-tls.sh \
-d        [your host name]  \
--dns     [dns_ali or dns_dp]
--uuid    [v2ray client id, optional]

# example
bash ./v2ray-ws-tls.sh -d asd.xyz.com --dns dns_ali --uuid e78b8e2c-85cd-4b33-847b-7ec741231d9a
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

# haproxy
```bash
# test config
haproxy -c -V -f /etc/haproxy/haproxy.cfg
haproxy -db -f /etc/haproxy/haproxy.cfg

# restart
systemctl restart haproxy || systemctl status haproxy.service
systemctl stop haproxy
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
