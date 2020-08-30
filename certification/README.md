# Generate https certification（acme.sh）

## How to install

```bash
curl -L -O -s https://raw.githubusercontent.com/fatesigner/shell_scripts/master/certification/certification.sh
chmod +x ./certification.sh
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
bash ./certification.sh \
-d        [your host name]  \
--dns     [dns_ali or dns_dp]

# example
bash ./certification.sh -d asd.xyz.com --dns dns_ali

# if success, the following file will be output.
Your cert is in  /root/.acme.sh/asd.xyz.com/asd.xyz.com.cer 
Your cert key is in  /root/.acme.sh/asd.xyz.com/asd.xyz.com.key 
The intermediate CA cert is in  /root/.acme.sh/asd.xyz.com/ca.cer 
And the full chain certs is there:  /root/.acme.sh/asd.xyz.com/fullchain.cer
```

## Tested OS
| Platform | Status|
|----|-------|
|Debian|passing
|Ubuntu|passing