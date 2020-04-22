# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Team CoreELEC (https://coreelec.org)

PKG_NAME="dtb-xml"
PKG_VERSION="1.0"
PKG_LICENSE="GPL"
PKG_SITE="https://coreelec.org"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Tool to handle custom dtb.img tweaks"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/coreelec
  mkdir -p ${INSTALL}/usr/share/bootloader
    install -m 0755 ${PKG_DIR}/scripts/dtb-xml.sh ${INSTALL}/usr/lib/coreelec/dtb-xml
    install -m 0644 ${PKG_DIR}/config/dtb.xml ${INSTALL}/usr/share/bootloader/dtb.xml
}
