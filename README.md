### Install

```
(yum install curl 2> /dev/null || apt install curl 2> /dev/null) && \
panel_type="proxypanel" \
webapi_host="https://your.webapi.host" \
webapi_key="YOUR_NODE_KEY" \
webapi_node_id=1 \
bash <(curl -L https://bit.ly/2ZFrhgU)
```

### Commands

| Function | command | 
|------------|--------|
| Show logs  | `journalctl -x -n 300 --no-pager -u ssrp` |
| Show status  | `systemctl status ssrp` |
| Stop  | `systemctl stop ssrp` |
| Start  | `systemctl start ssrp` |
| Restart  | `systemctl restart ssrp` |
| Upgrade | `bash <(curl https://bit.ly/2ZFrhgU)` |
| Uninstall | `bash <(curl -L https://bit.ly/33x3j8x)` |
