[Documentation](https://github.com/ColetteContreras/ssrp/wiki)

### Install

```
(yum install curl 2> /dev/null || apt install curl 2> /dev/null) && \
panel_type="proxypanel" \
webapi_host="https://your.webapi.host" \
webapi_key="YOUR_NODE_KEY" \
webapi_node_id=1 \
license_key="" \
bash <(curl -L https://bit.ly/2ZFrhgU)
```

### Commands

| Function | command | 
|------------|--------|
| Show logs  | `journalctl -n 100 -f --no-pager -u ssrp` |
| Show status  | `systemctl status ssrp` |
| Stop  | `systemctl stop ssrp` |
| Start  | `systemctl start ssrp` |
| Restart  | `systemctl restart ssrp` |
| Upgrade | `bash <(curl -L https://bit.ly/2ZFrhgU)` |
| Uninstall | `bash <(curl -L https://bit.ly/33x3j8x)` |


### Encryption Methods
```
aes-256-cfb  bf-cfb       chacha20     chacha20-ietf  aes-128-cfb
aes-192-cfb  aes-128-ctr  aes-192-ctr  aes-256-ctr    cast5-cfb
rc4-md5      salsa20      aes-256-gcm  aes-192-gcm    aes-128-gcm
chacha20-ietf-poly1305    des-cfb
```

### SSR Protocols

```
auth_aes128_md5  auth_aes128_sha1  auth_chain_a
```

### SSR Obfuscations

```
plain  http_simple  tls1.2_ticket_auth
```

