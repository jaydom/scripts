apt-get install polipo -y

read -t 15 -p  "ssserver(default 127.0.0.1:1080 timeout 15s):" _ssserver
ssserver=${_ssserver:-"127.0.0.1:1080"}
read -t 15 -p  "proxyPort(default 18888 timeout 15s):" _proxyPort
proxyPort=${_proxyPort:-"18888"}

cat >/etc/polipo/config<<eof
logFile = /var/log/polipo/polipo.log
socksParentProxy = "$ssserver"
socksProxyType = socks5
proxyAddress = "0.0.0.0"
proxyPort = $proxyPort
logLevel = 99
logSyslog = true
daemonise=true
chunkHighMark = 50331648
objectHighMark = 16384
serverMaxSlots = 64
serverSlots = 16
serverSlots1 = 32
eof

systemctl stop polipo
systemctl start polipo
