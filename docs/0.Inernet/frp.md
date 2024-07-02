### 一、内网穿透Frp：

**下载地址：**[https://github.com/fatedier/frp/releases](https://github.com/fatedier/frp/releases)

### 1.1、概述：


#### 1.1.1：frp内网穿透工具：
是一个高性能的反向代理应用，可以帮助您轻松地进行内网穿透，对外网提供服务，支持 tcp, http, https 等协议类型，并且 web 服务支持根据域名进行路由转发。

#### 1.1.2：frp的作用：
利用处于内网或防火墙后的机器，对外网环境提供 http 或 https 服务。
对于 http 服务支持基于域名的虚拟主机，支持自定义域名绑定，使多个域名可以共用一个80端口。
利用处于内网或防火墙后的机器，对外网环境提供 tcp 服务，例如在家里通过 ssh 访问处于公司内网环境内的主机。
可查看通过代理的所有 http 请求和响应的详细信息。（待开发）


### 2.1、项目思路及重难点内容

!!! warning "温馨提示"
    - 以下步骤只针对针对于centos 操作系统


#### 2.1.1：项目拓扑图：


#### 2.1.2：实验思路：
| 第一步 | 购买一台云服务器作为frp-server端，主要是需要一个固定公网地址，如果公司有固定公网地址最好 |
| --- | --- |
| 第二步 | 在公司或者内网准备一台主机作为frp-client端 |
| 第三步 | 在公司或者内网准备一台主机来部署vpn |
| 第四步 | 利用穿透来实现连接VPN |


#### 2.1.3：frp配置文件说明：


```shell
[root@localhost frpc]# ll
总用量 21136
-rwxr-xr-x 1 root root 10466752 8月  18 2021 frpc
-rw-r--r-- 1 root root     6818 8月  18 2021 frpc_full.ini
-rw-r--r-- 1 root root      283 5月   2 23:35 frpc.ini
-rwxr-xr-x 1 root root 11133376 8月  18 2021 frps
-rw-r--r-- 1 root root     2199 8月  18 2021 frps_full.ini
-rw-r--r-- 1 root root       26 8月  18 2021 frps.ini
-rw-r--r-- 1 root root    11358 8月  18 2021 LICENSE
-rw-r--r-- 1 root root       21 8月  18 2021 run.sh
drwxrwxr-x 2 root root       88 8月  18 2021 systemd

文件说明：
frpc                    # 客户端二进制文件
frpc_full.ini           # 客户端配置文件完整示例
frpc.ini                # 客户端配置文件
frps                    # 服务端二进制文件
frps_full.ini           # 服务端配置文件完整示例
frps.in1                # 服务端配置文件
```



### 3.1、Frp部署：

#### 3.1.1：部署frps：
> 注释：一般frps 是公网上的一台云服务器，这里可以是任意的云平台，注意一定记得开安全组！！！


```shell
[root@VM-16-9-centos frps]# cat frps.ini 
[common]
bind_port = 50070
vhost_http_port = 50080
vhost_https_port = 50443
token = $pF@7zz^LDuh7^xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx    这个token是用于服务端和客户端连接



# 启动
./frps -c ./frps.ini
```

#### 3.1.2：部署frpc：

```shell
[root@moban frp_0.38.0_linux_amd64]# cat frpc.ini
[common]
server_addr = 115.29.189.57
# server_addr表示与frps连接的地址
server_port = 50081
# 与frps连接的端口
token = pass@word1
# 配置token用来验证

[openvpn]
type = udp
local_ip = 192.168.8.82
local_port = 51194
remote_port = 51194

# remote_port表示用户访问公网地址+端口,就反向代理到local_ip+端口


# 启动
./frps -c ./frps.ini
```
#### 3.1.3：nj地区：192.165.0.20
```shell
[root@moban frp_0.26.0_linux_amd64]# cat frpc.ini
[common]
tls_enable=true
server_addr = 39.104.160.84
server_port = 50070
token = $pF@xxxxxx
[openvpn-nj]
type=udp
local_ip=192.165.0.21
local_port=31194
remote_port=31194


[root@moban frp_0.26.0_linux_amd64]# cat frp.sh 
./frpc -c ./frpc.ini

```
#### 3.1.4：bj地区：
```shell
[root@frp-40 frpc]# cat frpc.ini
[common]
tls_enable=true
server_addr = 39.104.160.84
server_port = 50070
token = $pF@7zz^LDuh7^X0Uxxxxx

```


### 4.1、vpn部署：

#### 4.4.1：vpn部署脚本：
```shell
#!/bin/bash
# 搭建vpenvpn脚本
# 作者:lixie
# 日期:2021-10-19


# openvpn是服务端,easy-rsa是证书管理工具

yum -y install wget
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum -y install openvpn easy-rsa &> /dev/null

# 获取openvpn和easy-rsa的版本
OPENVER=$(rpm -qi openvpn  |awk -F": "  'NR==2{print $2}')
EASYVER=$(rpm -qi easy-rsa  |awk -F": "  'NR==2{print $2}')

#echo "openvpn-$OPENVER"
#echo "easy-rsa-$EASYVER"

#生成服务器配置文件
#cp /usr/share/doc/openvpn-$OPENVER/sample/sample-config-files/server.conf  /etc/openvpn/

cat << EOF >>  /etc/openvpn/server/server.conf
local 0.0.0.0
port 41194
proto udp
dev tun
ca /etc/openvpn/certs/ca.crt
cert /etc/openvpn/certs/server.crt
dh /etc/openvpn/certs/dh.pem
push "route 192.168.0.0 255.255.0.0"
server 10.10.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
client-to-client
keepalive 10 120
comp-lzo
max-clients 100
persist-key
persist-tun
status /var/log/openvpn/openvpn-status.log
log-append  /var/log/openvpn/openvpn.log
verb 3
key /etc/openvpn/certs/server.key
cipher AES-256-CBC
client-config-dir /etc/openvpn/ccd
auth-user-pass-verify /etc/openvpn/checkpsw.sh via-env
username-as-common-name
script-security 3
verify-client-cert none


EOF

# 注意！！！ 这里创建完配置文件后，需要做个配置文件的软连接，因为当前版本的 openvpn systemd 启动文件中读取的是.service.conf配置
cd /etc/openvpn/server/ && ln -sf server.conf .service.conf


#准备证书签发相关文件

cp -r /usr/share/easy-rsa/ /etc/openvpn/easy-rsa-server

#准备签发证书相关变量的配置文件
cp /usr/share/doc/easy-rsa-$EASYVER/vars.example /etc/openvpn/easy-rsa-server/3/vars


#CA的证书有效期默为为10年,可以适当延长,比如:36500天
sed -i '/3650/ s/3650/36500/g' /etc/openvpn/easy-rsa-server/3/vars

#服务器证书默为为825天
sed -i '/825/ s/825/82500/g' /etc/openvpn/easy-rsa-server/3/vars


 初始化数据,在当前目录下生成pki目录及相关文件
cd /etc/openvpn/easy-rsa-server/3/
pwd
./easyrsa init-pki


 创建CA机构
cd /etc/openvpn/easy-rsa-server/3
./easyrsa build-ca nopass <<EOF


EOF


# 创建服务端证书申请

cd /etc/openvpn/easy-rsa-server/3
./easyrsa gen-req server nopass <<EOF


EOF

## 颁发服务端证书
#
cd /etc/openvpn/easy-rsa-server/3
./easyrsa sign server server <<EOF
yes

EOF



# 创建 Diffie-Hellman 密钥,这个步骤完了服务器部分就完成了
cd /etc/openvpn/easy-rsa-server/3
./easyrsa gen-dh


#为客户端准备证书环境
cp -r /usr/share/easy-rsa/ /etc/openvpn/easy-rsa-client
cp /usr/share/doc/easy-rsa-$EASYVER/vars.example /etc/openvpn/easy-rsa-client/3/vars
cd /etc/openvpn/easy-rsa-client/3/
./easyrsa init-pki


# 将CA和服务器证书相关文件复制到服务器相应的目录

mkdir /etc/openvpn/certs
cp /etc/openvpn/easy-rsa-server/3/pki/ca.crt  /etc/openvpn/certs/
cp /etc/openvpn/easy-rsa-server/3/pki/issued/server.crt  /etc/openvpn/certs/
cp /etc/openvpn/easy-rsa-server/3/pki/private/server.key  /etc/openvpn/certs/
cp /etc/openvpn/easy-rsa-server/3/pki/dh.pem  /etc/openvpn/certs/


# 修改服务器端配置文件


# 创建日志目录

mkdir /etc/openvpn/ccd
mkdir /var/log/openvpn
chown openvpn.openvpn /var/log/openvpn

cat <<EOF>> /etc/openvpn/psw-file
LIXIE ABC123,
EOF
chmod 600 /etc/openvpn/psw-file
chown openvpn:openvpn /etc/openvpn/psw-file





chmod +x /etc/openvpn/checkpsw.sh
chown -R openvpn:openvpn /etc/openvpn/


#在服务器开启ip_forward转发功能
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf && sysctl -p &> /dev/null
echo 'iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -j MASQUERADE' >> /etc/rc.d/rc.local
chmod +x /etc/rc.d/rc.local
/etc/rc.d/rc.local



systemctl daemon-reload
systemctl start openvpn-server@.service.service
systemctl enable openvpn-server@.service.service
```


#### 4.4.2：新增用户脚本：

```shell
cat <<EOF>> /etc/openvpn/checkpsw.sh
#!/bin/sh
###########################################################
# checkpsw.sh (C) 2004 Mathias Sundman <mathias@openvpn.se>
#
# This script will authenticate OpenVPN users against
# a plain text file. The passfile should simply contain
# one row per user with the username first followed by
# one or more space(s) or tab(s) and then the password.
PASSFILE="/etc/openvpn/psw-file"
LOG_FILE="/var/log/openvpn/password.log"
TIME_STAMP=`date "+%Y-%m-%d %T"`
###########################################################
if [ ! -r "${PASSFILE}" ]; then
  echo "${TIME_STAMP}: Could not open password file \"${PASSFILE}\" for reading." >>  ${LOG_FILE}
  exit 1
fi
CORRECT_PASSWORD=`awk '!/^;/&&!/^#/&&$1=="'${username}'"{print $2;exit}' ${PASSFILE}`
if [ "${CORRECT_PASSWORD}" = "" ]; then
  echo "${TIME_STAMP}: User does not exist: username=\"${username}\", password=
\"${password}\"." >> ${LOG_FILE}
  exit 1
fi
if [ "${password}" = "${CORRECT_PASSWORD}" ]; then
  echo "${TIME_STAMP}: Successful authentication: username=\"${username}\"." >> ${LOG_FILE}
  exit 0
fi
echo "${TIME_STAMP}: Incorrect password: username=\"${username}\", password=
\"${password}\"." >> ${LOG_FILE}
exit 1
EOF
```

> 注意：需要给这个脚本一个执行权限


#### 4.4.3：部署iptables：
> 防火墙配置（firewalld配置或者iptables配置选一个）

```shell
# firewalld配置
firewall-cmd --permanent --add-masquerade
firewall-cmd --permanent --add-service=openvpn
# 或者添加自定义端口
# firewall-cmd --permanent  --add-port=1194/tcp
firewall-cmd --permanent --direct --passthrough ipv4 -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
firewall-cmd --reload
# iptables （和上面的网段配置不同，修改下面的网段即可）
yum install iptables-services
systemctl enable iptables
iptables -X
iptables -F
iptables -Z
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
service iptables save
iptables -t nat -A POSTROUTING -s 10.10.0.0/255.255.255.0 -o eth0 -j MASQUERADE
iptables -A FORWARD -s 10.10.0.0/24 -d 192.168.0.0/24 -i tun0 -j ACCEPT
iptables -A FORWARD -s 192.168.0.0/24 -d 10.10.0.0/24 -i eth0 -j ACCEPT
service iptables save
```


#### 4.4.4：准备客户端证书：

备注：安装openvpn客户端软件：config配置文件中添加ca证书和.opvn
```shell
client
dev tun
proto udp
# 公网ip需要修改
remote  公网地址  41194       
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt

comp-lzo
verb 3
cipher AES-256-CBC
auth-user-pass
```

### 5.1：其他案例配置：




#### **附件：**

学习博客：[https://www.jianshu.com/p/09603d9e0b6c](https://www.jianshu.com/p/09603d9e0b6c)
