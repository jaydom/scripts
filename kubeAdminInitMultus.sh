# check docker images
dockerImageList=(
"kubernetes-master:5000/coreos/flannel:v0.10.0-amd64"
"kubernetes-master:5000/busybox:1.29"
"kubernetes-master:5000/nfvpe/multus:latest"
)
for i in ${dockerImageList[*]}
do
  docker pull $i
  [ $? == "0" ]||{
     echo "缺少镜像"
     exit 1
  }
done

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
# set flannel & multus (https://raw.githubusercontent.com/intel/multus-cni/master/images/{flannel-deamonset.yml,multus-deamonset.yml})
cat multus/flannel-daemonset.yml |kubectl apply -f -
cat multus/multus-daemonset.yml |kubectl apply -f -
# create CRD and add macvlan conf
cat multus/demo/macvlan-conf.yml |kubectl create -f -

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
# set eth1 
ip link set eth1 promisc on
# kubeadm init
eof
 
grep "kubeadm join.*token.*sha.*" kubeadm.log >>kubeAdminJoin.sh

 
