# set kubectl completion 
source <(kubectl completion bash)
# set args
read -t 15 -p  "podCIDR(default 10.244.0.0/16 timeout 15s):" _podCIDR
podCIDR=${_podCIDR:-"10.244.0.0/16"}
# add iptables rules
ports=(
6443
10250
)
for n in ${ports[*]}
do
  [ `iptables -L -nv|grep dpt:"$n " -c` -ge 1 ]||{
    echo iptables -I INPUT -p tcp --dport $n -j ACCEPT
    iptables -I INPUT -p tcp --dport $n -j ACCEPT
  }
done
# flannel(vxlan) use port 8472
iptables -I INPUT -p udp --dport 8472 -j ACCEPT
# 
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
# shutdown selinux
echo setenforce 0
setenforce 0
# disable swap
echo swapoff -a
swapoff -a
# kubeadm init
echo kubeadm init --pod-network-cidr=$podCIDR
kubeadm init --pod-network-cidr=$podCIDR &> kubeadm.log
# prepare env 
mkdir -p $HOME/.kube
/bin/cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
# set flannel (https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml)
cat kube-flannel.yml |sed s%"10.244.0.0/16"%$podCIDR%g |sed s%"quay.io/coreos/flannel:v0.10.0-amd64"%"kubernetes-master:5000/coreos/flannel:v0.10.0-amd64"%g >my-kube-flannel.yml
cat my-kube-flannel.yml | kubectl apply -f -

# create the kubeAdminJoin.sh script
cat >kubeAdminJoin.sh <<eof
# set kubectl completion 
source <(kubectl completion bash)
# add iptables rules
ports=(
10250
)
for n in \${ports[*]}
do
  [ `iptables -L -nv|grep dpt:"\$n " -c` -ge 1 ]||{
    echo iptables -I INPUT -p tcp --dport \$n -j ACCEPT
    iptables -I INPUT -p tcp --dport \$n -j ACCEPT
  }
done
# flannel(vxlan) use port 8472
iptables -I INPUT -p udp --dport 8472 -j ACCEPT
# 
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 > /proc/sys/net/bridge/bridge-nf-call-ip6tables
# shutdown selinux
setenforce 0
# disable swap
swapoff -a
# kubeadm init
eof
 
grep "kubeadm join.*token.*sha.*" kubeadm.log >>kubeAdminJoin.sh

 
