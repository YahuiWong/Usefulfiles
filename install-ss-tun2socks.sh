#!/bin/sh
#
# Script for automatic setup of an SS-TUN2SOCKS server on CentOS 7.3 Minimal.
#

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'yum install' failed."; }
bigecho()  { echo; echo -e "\033[36m $1 \033[0m"; }

# Disable FireWall
bigecho "Disable Firewall..."
systemctl stop firewalld.service
systemctl disable firewalld.service

# Install Lib
bigecho "Install Library, Pleast wait..."
yum -y install git gettext gcc autoconf libtool make asciidoc xmlto c-ares-devel libev-devel \
  openssl-devel net-tools curl ipset iproute perl wget gcc bind-utils vim || exiterr2

# 查找 TPROXY 模块
find /lib/modules/$(uname -r) -type f -name '*.ko*' | grep 'xt_TPROXY'
# Install haveged
if ! type haveged 2>/dev/null; then
    bigecho "Install Haveged, Pleast wait..."
    HAVEGED_VER=1.9.1-1
    HAVEGED_URL="http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/h/haveged-$HAVEGED_VER.el7.x86_64.rpm"
    yum -y install "$HAVEGED_URL" || exiterr2
    systemctl start haveged
    systemctl enable haveged
fi

# Install pdnsd
if ! type pdnsd 2>/dev/null; then
    bigecho "Install Pdnsd, Pleast wait..."
    PDNSD_VER=1.2.9a
    PDNSD_URL="http://members.home.nl/p.a.rombouts/pdnsd/releases/pdnsd-$PDNSD_VER-par_sl6.x86_64.rpm"
    yum -y install "$PDNSD_URL" || exiterr2
fi
# udp don`t need thisdnsforwarder
# # Build aclocal-1.15, it's needed by dnsforwarder
# if ! type aclocal-1.15 2>/dev/null; then
#     bigecho "Build aclocal-1.15, Pleast wait..."
#     AUTOMAKE_VER=1.15
#     AUTOMAKE_FILE="automake-$AUTOMAKE_VER"
#     AUTOMAKE_URL="https://ftp.gnu.org/gnu/automake/$AUTOMAKE_FILE.tar.gz"
#     if ! wget --no-check-certificate -O $AUTOMAKE_FILE.tar.gz $AUTOMAKE_URL; then
#         bigecho "Failed to download file!"
#         exit 1
#     fi
#     tar xf $AUTOMAKE_FILE.tar.gz
#     pushd $AUTOMAKE_FILE
#     ./configure
#     make && make install
#     popd
# fi

# # Build dnsforwarder
# if ! type dnsforwarder 2>/dev/null; then
#     bigecho "Build dnsforwarder, Pleast wait..."
#     git clone https://github.com/holmium/dnsforwarder.git
#     pushd dnsforwarder
#     ./configure --enable-downloader=no
#     make && make install
#     popd
# fi

# Build chinadns
if ! type chinadns 2>/dev/null; then
    bigecho "Build chinadns, Pleast wait..."
    CHINADNS_VER=1.3.2
    CHINADNS_FILE="chinadns-$CHINADNS_VER"
    CHINADNS_URL="https://github.com/shadowsocks/ChinaDNS/releases/download/$CHINADNS_VER/$CHINADNS_FILE.tar.gz"
    if ! wget --no-check-certificate -O $CHINADNS_FILE.tar.gz $CHINADNS_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $CHINADNS_FILE.tar.gz
    pushd $CHINADNS_FILE
    ./configure
    make && make install
    popd
fi

# Build Libsodium
if [ ! -f "/usr/lib/libsodium.so" ]; then
    bigecho "Build Libsodium, Pleast wait..."
    LIBSODIUM_VER=1.0.13
    LIBSODIUM_FILE="libsodium-$LIBSODIUM_VER"
    LIBSODIUM_URL="https://download.libsodium.org/libsodium/releases/$LIBSODIUM_FILE.tar.gz"
    if ! wget --user-agent="Mozilla/5.0 (X11;U;Linux i686;en-US;rv:1.9.0.3) Geco/2008092416 Firefox/3.0.3" --no-check-certificate -O $LIBSODIUM_FILE.tar.gz $LIBSODIUM_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $LIBSODIUM_FILE.tar.gz
    pushd $LIBSODIUM_FILE
    ./configure --prefix=/usr && make
    make install
    popd
    ldconfig
fi

# Build MbedTLS
if [ ! -f "/usr/lib/libmbedtls.so" ]; then
    bigecho "Build MbedTLS, Pleast wait..."
    MBEDTLS_VER=2.6.0
    MBEDTLS_FILE="mbedtls-$MBEDTLS_VER"
    MBEDTLS_URL="https://tls.mbed.org/code/releases/$MBEDTLS_FILE-gpl.tgz"
    if ! wget --no-check-certificate -O $MBEDTLS_FILE-gpl.tgz $MBEDTLS_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $MBEDTLS_FILE-gpl.tgz
    pushd $MBEDTLS_FILE
    make SHARED=1 CFLAGS=-fPIC
    make DESTDIR=/usr install
    popd
    ldconfig
fi
git config http.postBuffer 524288000
#Build shadowsocksr-libev
if ! type ssr-redir 2>/dev/null; then
    bigecho "Build shadowsocksr-libev, Pleast wait..."
    git clone https://github.com/shadowsocksr-backup/shadowsocksr-libev.git
    pushd shadowsocksr-libev
    ./configure --prefix=/usr/local/ssr-libev
    make && make install
    popd
    pushd /usr/local/ssr-libev/bin
    mv ss-redir ssr-redir
    mv ss-local ssr-local
    ln -sf ssr-local ssr-tunnel
    mv ssr-* /usr/local/bin/
    popd
    rm -fr /usr/local/ssr-libev
fi

# Install SS-TUN2SOCKS
if ! type ss-tun2socks 2>/dev/null; then
    bigecho "Install SS-TProxy, Pleast wait..."
    git clone https://github.com/YahuiWong/ss-tun2socks.git
    pushd ss-tun2socks
    cp -af ss-tun2socks /usr/local/bin/
    cp -af tun2socks.bin/tun2socks.ARCH /usr/local/bin/tun2socks #（先解压，注意 ARCH）
    chown root:root /usr/local/bin/tun2socks /usr/local/bin/ss-tun2socks
    chmod +x /usr/local/bin/tun2socks /usr/local/bin/ss-tun2socks
    mkdir -m 0755 -p /etc/tun2socks
    cp -af pdnsd.conf /etc/tun2socks/
    cp -af chnroute.txt /etc/tun2socks/
    cp -af chnroute.ipset /etc/tun2socks/
    cp -af ss-tun2socks.conf /etc/tun2socks/
    chown -R root:root /etc/tun2socks
    chmod 0644 /etc/tun2socks/*
    popd

    # Systemctl
    pushd ss-tun2socks
    cp -af ss-tun2socks.service /etc/systemd/system/
    popd
    systemctl daemon-reload
    systemctl enable ss-tun2socks.service
fi

# Display info
bigecho "#######################################################"
bigecho "Please modify /etc/tproxy/ss-tun2socks.conf before start."
bigecho "#ss-tun2socks update_chnip"
#ss-tun2socks update_chnip
bigecho "#ss-tun2socks start"
#ss-tun2socks start
#bigecho "#######################################################"
#bigecho "ss-tunnel 测试"
#dig @127.0.0.1 -p60053 www.google.com
#bigecho "国内 DNS 测试"
#dig @114.114.114.114 -p53 www.baidu.com
#bigecho "ss-redir 测试"
#dig @208.67.222.222 -p443 www.google.com
