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

# ---------------------------------------
# No /flash/dtb.xml exist:
# On first access of a variable by 'get_dtbxml_value' or 'get_dtbxml_multivalues'
# by CE settings current defined default values are read by dtb-xml.sh and
# migrated to /flash/dtb.xml.
#
# If a matching value is found the option is set in dtb.xml. If no matching
# value is found or the path is not found in dtb.img it get set to 'migrated'.
# On next access of a option set to 'migrated' the dtb-xml.sh script try again
# to read current value from dtb.img as it maybe turn to applicable after a
# update of dtb.img by tar update.
# -> need to check if a valid option is set in dtb.xml but it become non applicable
#
# /flash/dtb.xml get only be edited by dtb-xml.sh script and remain untouched
# on update of the system. When a update is done user defined values are
# applied to /flash/dtb.img by dtb.xml after update of dtb.img itself so no
# extra reboot is needed.
#
# -> how can a new default value be forced by update?
# Now if a new default value get introduced it will be overwritten by the users
# dtb.xml value after update of dtb.img.
# -> somehow the value need to be removed or updated in dtb.xml
#
# On bricked devices: remove /flash/dtb.xml and copy default dtb.img on /flash
