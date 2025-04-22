server_url: https://${HEADSCALE_HOSTNAME}:8080
listen_addr: 0.0.0.0:8080

metrics_listen_addr: 127.0.0.1:9090
grpc_listen_addr: 127.0.0.1:50443
grpc_allow_insecure: false

noise:
  private_key_path: /var/lib/headscale/noise_private.key

prefixes:
  v4: 100.64.0.0/10
  v6: fd7a:115c:a1e0::/48

derp:
  server:
    enabled: false
  paths:
    - /etc/headscale/derp.yaml

disable_check_updates: true
ephemeral_node_inactivity_timeout: 30m

database:
  type: sqlite3
  sqlite:
    path: /var/lib/headscale/db.sqlite

log:
  format: text
  level: info

dns:
  magic_dns: false
  nameservers:
    global:
      - ${SUBNET_ROUTER_PRIVATE_IP}
  search_domains:
    - ${PRIVATE_DOMAIN}

unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"

logtail:
  enabled: false

randomize_client_port: false
