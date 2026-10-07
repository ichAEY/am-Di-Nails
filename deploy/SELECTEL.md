# Di Nails on the existing TANEM Selectel VPS

- Domain: `di-nails.tanem.ru`
- A record at REG.RU: `di-nails -> 135.106.229.21`
- Server: `135.106.229.21` (Ubuntu / Nginx)
- Deployment directory: `/var/www/di-nails`
- GitHub Actions secret required in **this** repository: `TANEM_SELECTEL_SSH_KEY`
- Workflow: `.github/workflows/selectel.yml`, deploys after pushes to `main` and on manual dispatch.

## One-time server setup (run as root, without changing any existing vhosts)

```bash
install -d -o tanem-deploy -g www-data -m 0755 /var/www/di-nails
install -m 0644 /dev/stdin /etc/nginx/sites-available/di-nails <<'NGINX'
# Only di-nails.tanem.ru. HTTPS is enabled after this vhost using Certbot.
server {
    listen 80;
    listen [::]:80;
    server_name di-nails.tanem.ru;
    root /var/www/di-nails;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
NGINX
ln -sfn /etc/nginx/sites-available/di-nails /etc/nginx/sites-enabled/di-nails
nginx -t && systemctl reload nginx
```

Once GitHub Actions has uploaded `index.html` into this folder and DNS points to the VPS, issue SSL:

```bash
certbot --nginx -d di-nails.tanem.ru --redirect --non-interactive
nginx -t && systemctl reload nginx
curl -fsSI https://di-nails.tanem.ru/
```

The deploy workflow validates production data, uploads **only** the public site files over SSH, and checks TLS, redirect and public site content. No customer data JSON, GitHub workflow, documentation, scripts or test files are publicly uploaded.

If the SSH secret is missing, copy the contents of the existing local `~/.ssh/tanem_github_deploy` **private key** into the GitHub repository's Actions secret `TANEM_SELECTEL_SSH_KEY`; do not commit the key. If `tanem-deploy` cannot write to `/var/www/di-nails`, run the root setup above first. The server key fingerprint is pinned to the same Selectel server as 7 Nebo.
