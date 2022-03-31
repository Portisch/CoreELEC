# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present Team CoreELEC (https://coreelec.org)

PKG_NAME="hyperion.ng"
PKG_VERSION="db0fb5f25e3e415c24dc0c999df4b32360fa2ae2"
#PKG_SHA256="755771f17114611722f0b0879322b8c7cf1aa7e7ff8e8b592e544d5b26412aa6"
PKG_REV="109"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/Lord-Grey/hyperion.ng"
PKG_URL="https://github.com/Lord-Grey/hyperion.ng/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain Python3 avahi libusb libamcodec qt-everywhere protobuf flatbuffers:host flatbuffers libcec libjpeg-turbo qmdnsengine"
PKG_SECTION="service"
PKG_SHORTDESC="Hyperion.NG: an AmbiLight controller"
PKG_LONGDESC="Hyperion.NG($PKG_VERSION) is an modern opensource AmbiLight implementation."

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Hyperion.NG"
PKG_ADDON_TYPE="xbmc.service"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_NO_SYSTEM_FROM_IMPORTED=ON \
                       -DCMAKE_BUILD_TYPE=Release \
                       -DUSE_SYSTEM_PROTO_LIBS=ON \
                       -DUSE_SYSTEM_FLATBUFFERS_LIBS=ON \
                       -DUSE_SYSTEM_QMDNS_LIBS=ON \
                       -DPLATFORM=amlogic \
                       -DENABLE_AMLOGIC=ON \
                       -DENABLE_DISPMANX=OFF \
                       -DENABLE_FB=ON \
                       -DENABLE_DEV_WS281XPWM=OFF \
                       -DENABLE_X11=OFF \
                       -DENABLE_V4L2=ON \
                       -DENABLE_OSX=OFF \
                       -DENABLE_DEV_SPI=ON \
                       -DENABLE_MDNS=ON \
                       -DENABLE_DEV_TINKERFORGE=OFF \
                       -DENABLE_TESTS=OFF \
                       -DENABLE_DEPLOY_DEPENDENCIES=OFF \
                       -Wno-dev"

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp $PKG_BUILD/.$TARGET_NAME/bin/* $ADDON_BUILD/$PKG_ADDON_ID/bin
}
