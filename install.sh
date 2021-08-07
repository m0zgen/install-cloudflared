#!/bin/bash
# Install Cloudflared to CentOS
# Created by Y.G., https://sys-adm.in
# https://sys-adm.in/systadm/nix/867-dns-over-https-doh-ot-cloudflare-v-centos-fedora-debian-ubuntu.html

# Download package
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation
yum -y install https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm

# Create user
useradd -s /usr/sbin/nologin -r -M cloudflared

# Create Config
echo "CLOUDFLARED_OPTS=--port 5053 --upstream https://1.1.1.1/dns-query --upstream https://1.0.0.1/dns-query" > /etc/default/cloudflared

# Create systemd unit
cat > /etc/systemd/system/cloudflared.service <<_EOF_
[Unit]
Description=cloudflared DNS over HTTPS proxy
After=syslog.target network-online.target

[Service]
Type=simple
User=cloudflared
EnvironmentFile=/etc/default/cloudflared
ExecStart=/usr/local/bin/cloudflared proxy-dns \$CLOUDFLARED_OPTS
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
_EOF_

# Install service
systemctl daemon-reload
systemctl enable --now cloudflared
systemctl status cloudflared
cloudflared -v

# Additional config way
mkdir /etc/cloudflared/

cat > /etc/cloudflared/config.yml <<_EOF_
proxy-dns: true
proxy-dns-port: 5053
proxy-dns-upstream:
  - https://1.1.1.1/dns-query
  - https://1.0.0.1/dns-query
  # Uncomment the following if you also want to use IPv6 for external DOH lookups
  #- https://[2606:4700:4700::1111]/dns-query
  #- https://[2606:4700:4700::1001]/dns-query
_EOF_

cloudflared service install --legacy
systemctl restart cloudflared
systemctl status cloudflared

# Check works
dig @127.0.0.1 -p 5053 google.com

echo "You can use Cloudflared like as: 127.0.0.1#5053"
echo "Done!"
