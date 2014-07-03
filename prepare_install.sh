#!/bin/sh

ORACLE_PASSWORD="abc123"

function disable_selinux() {
    echo -e "\nDisable SELinux... \c"
    sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
    setenforce Permissive
    echo "done."
}

function disable_firewall() {
    echo -e "\nDisable firewall... \c"
    service iptables stop
    chkconfig iptables off
    echo "done."
}

function add_linux_repo {
    echo -e "\nAdd Linux yum repo... \c"

    for file in `ls /etc/yum.repos.d/*repo`; do
        mv $file "$file.bak" 
    done 

    cat >/etc/yum.repos.d/centos.repo <<EOF
[base]
name=CentOS-$releasever - Base
baseurl=http://mirrors.sohu.com/centos/6.5/os/x86_64/
gpgcheck=0
enabled=1

[epel]
name=epel
baseurl=http://mirrors.sohu.com/fedora-epel/6Server/x86_64/
gpgcheck=0
enabled=1
EOF
    echo "done."
}

function install_required_packages {
    echo -e "\nInstall required packages... \c"
    pkgs="binutils compat-libcap1 compat-libstdc++-33 gcc gcc-c++ glibc glibc-devel libgcc libstdc++ libaio libaio-devel libXext libXtst libX11 libXau libxcb libXi make sysstat tigervnc-server"
    yum install -y $pkgs
    echo "done."
}

function add_user_and_group {
    echo -e "\nCreate user oracle... \c"
    groupadd oinstall
    groupadd dba
    groupadd oper
    mkdir -p /u01/oracle
    useradd -g oinstall -Gdba,oper -d /u01/oracle oracle
    passwd oracle <<EOF
$ORACLE_PASSWORD
$ORACLE_PASSWORD
EOF
    chown -R oracle:oinstall /u01

    cat >>/u01/oracle/.bash_profile <<EOF
ORACLE_BASE=/u01
ORACLE_HOME=\$ORACLE_BASE/oracle
ORACLE_SID=orcl
PATH=\$ORACLE_HOME/bin:\$PATH
umask 022
export ORACLE_BASE ORACLE_HOME ORACLE_SID PATH
EOF
    echo "done."
}

function set_system_parameters {
    echo -e "\nSet system parameters... \c"
    cat >>/etc/sysctl.conf <<EOF
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.shmmax = 536870912
kernel.shmmni = 4096
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
EOF

    cat >>/etc/security/limits.conf <<EOF
oracle soft nproc 2047
oracle hard nproc 16384
oracle soft nofile 1024
oracle hard nofile 65536
oracle soft stack 10240
oracle hard stack 32768
EOF
    echo "done."
}
 

disable_selinux
disable_firewall
add_linux_repo
install_required_packages
add_user_and_group
set_system_parameters
