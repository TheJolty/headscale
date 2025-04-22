# {
#  email ${ACME_EMAIL}
# }

${HEADSCALE_HOSTNAME} {
  tls /etc/caddy/certs/demosfelipetrindade.top.crt /etc/caddy/certs/demosfelipetrindade.top.key

  redir /admin /admin/
  handle_path /admin/* {
    root * /var/headscale-admin/
    file_server {
      index index.html
    }
    header {
      Cache-Control "public, max-age=31536000, immutable"
    }
  }

  handle {
    reverse_proxy 127.0.0.1:8080
  }
}