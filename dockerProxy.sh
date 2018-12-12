mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/http-proxy.conf<<eof
[Service]
Environment="HTTPS_PROXY=http://127.0.0.1:18888" "HTTP_PROXY=http://127.0.0.1:18888" "NO_PROXY=localhost,127.0.0.1,registry.docker-cn.com"
eof

systemctl daemon-reload

systemctl restart docker
