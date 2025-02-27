#!/bin/sh

# Used to prevent timeouts in travis
progress_idicator(){
  while true
  do
    echo -n "."
    sleep 30
  done
}

progress_idicator &

OS_NAME=$1
OS_VERSION=$2

if [ "$OS_NAME" = "centos" ]; then

# Clean the yum cache
yum -y clean all
yum -y clean expire-cache

# First, install all the needed packages.
yum install -y wget gettext flex bison binutils gcc gcc-c++ texinfo kernel-headers rpm-build kernel-devel boost-devel cmake git tar gzip make autotools

wget http://checkinstall.izto.org/files/source/checkinstall-1.6.2.tar.gz
tar xzvf checkinstall-1.6.2.tar.gz
cd checkinstall-1.6.2
./configure
make
make install
cd ..
rm -rf checkinstall*

mkdir -p build
cd build
../configure --target=x86_64-hermit --prefix=/opt/hermit --disable-shared --disable-nls --disable-gdb --disable-libdecnumber --disable-readline --disable-sim --disable-libssp --enable-tls --disable-multilib
make
checkinstall -R -y --exclude=build --pkggroup=main --maintainer=stefan@eonerc.rwth-aachen.de --pkgsource=https://hermitcore.org --pkgname=binutils-hermit --pkgversion=2.30.51 --pkglicense=GPL2 make install

else

export DEBIAN_FRONTEND="noninteractive"

apt-get -qq update
apt-get install -y wget curl gnupg checkinstall gawk dialog apt-utils flex bison binutils texinfo gcc-6 g++-6 libmpfr-dev libmpc-dev libgmp-dev libisl-dev packaging-dev build-essential libtool autotools-dev autoconf pkg-config apt-transport-https libc6-dev 

echo "deb [trusted=yes] https://dl.bintray.com/hermitcore/$OS_NAME $OS_VERSION main" | tee -a /etc/apt/sources.list 
apt-get update
apt-get install -y --allow-unauthenticated binutils-hermit gcc-hermit-bootstrap newlib-hermit pte-hermit libhermit
export PATH=/opt/hermit/bin:$PATH

wget ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.15.tar.bz2 -O isl-0.15.tar.bz2
tar jxf isl-0.15.tar.bz2
mv isl-0.15 isl
rm isl-0.15.tar.bz2

# don't run fixincludes, this is accidentally done by dh and kinda broken		
#  reference: https://gcc.gnu.org/ml/gcc/2013-04/msg00171.html		
#  reference: https://ewontfix.com/12/		
sed -i 's/STMP_FIXINC=stmp-fixinc/STMP_FIXINC=/g' gcc/configure

mkdir -p build
cd build
../configure --target=x86_64-hermit --prefix=/opt/hermit --with-newlib --disable-multilib --without-libatomic --with-tune=generic --enable-languages=c,c++,go,fortran,lto --disable-nls --disable-shared --disable-libssp --enable-threads=posix --disable-libgomp --enable-tls --enable-lto --disable-symvers
make -j2 > /dev/null
apt-get remove -y gcc-hermit-bootstrap
mkdir -p /opt/hermit/libexec/gcc/x86_64-hermit/6.3.0/install-tools
mkdir -p /opt/hermit/x86_64-hermit/include/c++
mkdir -p /opt/hermit/lib/g/opt/hermit/lib/gcc/x86_64-hermit/6.3.0/install-tools/includecc
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/install-tools/include
mkdir -p /opt/hermit/x86_64-hermit/lib/go/6.3.0/x86_64-hermit
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/include
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/finclude
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/include-fixed
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/include-tools
mkdir -p /opt/hermit/lib/gcc/x86_64-hermit/6.3.0/plugin
mkdir -p /opt/hermit/share/gcc-6.3.0/python/libstdcxx/v6
checkinstall -D -y --exclude=build --pkggroup=main --maintainer=stefan@eonerc.rwth-aachen.de --pkgsource=https://hermitcore.org --pkgname=gcc-hermit --pkgversion=6.3.0 --conflicts=gcc-hermit-rs --pkglicense=GPL2 make install

cd ..
mkdir -p tmp
dpkg-deb -R build/gcc-hermit_6.3.0-1_amd64.deb tmp
rm -f build/gcc-hermit_6.3.0-1_amd64.deb

fi
