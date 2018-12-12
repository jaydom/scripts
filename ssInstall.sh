read -t 30 -p  "ssserver(default 127.0.0.1:3128 timeout 30s):" _ssserver
ssserver=${_ssserver:-"127.0.0.1:3128"}
ssserverIP=${ssserver%%:*}
ssserverPort=${ssserver##*:}
read -t 15 -p  "key(default gsta123 timeout 15s):" _key
key=${_key:-"gsta123"}

apt-get install python-pip -y 

apt-get install git -y 

pip install git+https://github.com/shadowsocks/shadowsocks.git@master &&\

echo sslocal -s $ssserverIP -p $ssserverPort -k $key >sslocal.sh
