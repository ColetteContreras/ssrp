# ssr-poseidon

### Install

```
panel_type="proxypanel" \
webapi_host="https://your.webapi.host" \
webapi_key="YOUR_NODE_KEY" \
webapi_node_id=1 \
bash <(curl https://raw.githubusercontent.com/ColetteContreras/ssrp/master/install.sh)
```

### Commands

| Function | command | 
|------------|--------|
| Show logs  | `journalctl -x -n 300 --no-pager -u ssrp` |
| Show status  | `systemctl status ssrp` |
| Stop  | `systemctl stop ssrp` |
| Start  | `systemctl start ssrp` |
| Restart  | `systemctl restart ssrp` |
| Upgrade | `bash <(curl https://raw.githubusercontent.com/ColetteContreras/ssrp/master/install.sh)` |
| Uninstall | `bash <(curl https://raw.githubusercontent.com/ColetteContreras/ssrp/master/uninstall.sh)` |
