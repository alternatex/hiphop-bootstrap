#!/bin/bash

cat <<VM-SETUP
# -------------------------------------------------------------------------------------------------------- #
                                                
	  _   _                         ____                    _   _         U  ___ u      ____    
	 |'| |'|          ___         U|  _"\ u                |'| |'|         \/"_ \/    U|  _"\ u 
	/| |_| |\        |_"_|        \| |_) |/     U  u      /| |_| |\        | | | |    \| |_) |/ 
	U|  _  |u         | |          |  __/       /___\     U|  _  |u    .-,_| |_| |     |  __/   
	 |_| |_|        U/| |\u        |_|         |__"__|     |_| |_|      \_)-\___/      |_|      
	 //   \\     .-,_|___|_,-.     ||>>_                   //   \\           \\        ||>>_    
	(_") ("_)     \_)-' '-(_/     (__)__)                 (_") ("_)         (__)      (__)__)   

	
  based on instructions found @ https://github.com/facebook/hiphop-php/wiki/Building-and-Installing-on-Ubuntu-11.10

  scripted. w/debian in mind. tested on: http://cdimage.debian.org/debian-cd/current-live/i386/iso-hybrid/debian-live-6.0.3-i386-standard.iso

# -------------------------------------------------------------------------------------------------------- #
VM-SETUP

# setup base system
apt-get update

# install required libraries
sudo apt-get install git-core cmake g++ libboost-dev libmysqlclient-dev libxml2-dev libmcrypt-dev libicu-dev openssl build-essential binutils-dev libcap-dev libgd2-xpm-dev zlib1g-dev libtbb-dev libonig-dev libpcre3-dev autoconf libtool libcurl4-openssl-dev libboost-system-dev libboost-program-options-dev libboost-filesystem-dev wget memcached libreadline-dev libncurses-dev libmemcached-dev libbz2-dev libc-client2007e-dev php5-mcrypt php5-imagick libgoogle-perftools-dev libcloog-ppl0

# get hiphop src / set paths
git clone git://github.com/facebook/hiphop-php.git
cd hiphop-php
export CMAKE_PREFIX_PATH=`/bin/pwd`/../
export HPHP_HOME=`/bin/pwd`
export HPHP_LIB=`/bin/pwd`/bin
cd ..

# build third-party libraries: libevent
wget http://www.monkey.org/~provos/libevent-1.4.14b-stable.tar.gz
tar -xzvf libevent-1.4.14b-stable.tar.gz
cd libevent-1.4.14b-stable
cp ../hiphop-php/src/third_party/libevent-1.4.14.fb-changes.diff .
patch -p1 < libevent-1.4.14.fb-changes.diff
./configure --prefix=$CMAKE_PREFIX_PATH
make
make install
cd ..

# build third-party libraries: libCurl (note: system time incorrect > ./configure will fail.)
wget http://curl.haxx.se/download/curl-7.21.2.tar.gz
tar -xvzf curl-7.21.2.tar.gz
cd curl-7.21.2
cp ../hiphop-php/src/third_party/libcurl.fb-changes.diff .
patch -p1 < libcurl.fb-changes.diff
./configure --prefix=$CMAKE_PREFIX_PATH
make
make install
cd ..

# build third-party libraries: libmemcached
wget http://launchpad.net/libmemcached/1.0/0.49/+download/libmemcached-0.49.tar.gz
tar -xzvf libmemcached-0.49.tar.gz
cd libmemcached-0.49
./configure --prefix=$CMAKE_PREFIX_PATH
make
make install
cd ..

# build hiphop
cd hiphop-php
git submodule init
git submodule update
cmake .
make

# create test script
echo "hiphop-php basic test" && cd .. && mkdir test && cd $_;
define(){ IFS='\n' read -r -d '' ${1}; }
define APPJS <<'EOF'
<?php
	echo "test";
?>
EOF
echo $APPJS >> helloworld.php

# compile 
$HPHP_HOME/src/hphp/hphp helloworld.php --keep-tempdir=1 --log=3

# gather temp directory from build
outdir=`ls -trd /tmp/hphp_* | tail -1`

# run 
echo `"${outdir}/program"`

# cleanup
rm -fR /tmp/hphp_*