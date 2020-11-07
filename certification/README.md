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
--dns     [dns_ali or dns_dp] \
-d        [your host name]

# example
bash ./certification.sh --dns dns_ali -d xyz.com -d *.xyz.com

# if success, the following file will be output.
Your cert is in  /root/.acme.sh/xyz.com_ecc/asd.xyz.com.cer 
Your cert key is in  /root/.acme.sh/xyz.com_ecc/asd.xyz.com.key 
The intermediate CA cert is in  /root/.acme.sh/xyz.com_ecc/ca.cer 
And the full chain certs is there:  /root/.acme.sh/xyz.com_ecc/fullchain.cer
```

## Tested OS
| Platform | Status|
|----|-------|
|Debian|passing
|Ubuntu|passing