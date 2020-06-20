#!/bin/sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2020-present Team CoreELEC (https://coreelec.org)
#
#  Update dtb.img by dtb.xml
#
#####################################################
#
# Comand Line Arguments
# -v = Show verbose output
# -s = set system root prefix
# -m = migrate dtb.img settings to dtb.xml
#
#####################################################

verbose=0
changed=0
migrate=0
update_migrated=0
update_node=''
SYSTEM_ROOT=''
BOOT_ROOT='/flash'

while [ $# -ne 0 ]; do
  arg="$1"
  case "$arg" in
      -v)
        verbose=1
        ;;
      -s)
        shift
        PATH="$PATH:$1/usr/bin"
        SYSTEM_ROOT="$1"
        ;;
      -m)
        migrate=1
        ;;
      -u)
        shift
        update_migrated=1
        update_node="$1"
        ;;
      *)
        echo "Unknown option: '$arg'"
        exit
        ;;
  esac
  shift
done

xml_file="$BOOT_ROOT/dtb.xml"
default_xml_file="$SYSTEM_ROOT/usr/share/bootloader/dtb.xml"
dtb_file="$BOOT_ROOT/dtb.img"

function log() {
  [ "$verbose" == 1 ] && echo "$@"
}

function update_migrated_xml() {
  log ""
  log "Update migrated dtb.xml from dtb.img"
  log ""

  node_status=$(xmlstarlet sel -t -v "//$update_node/@status" $xml_file)
  if [ -z "$node_status" ]; then
    log "update_migrated_xml: no node specified"
    return
  fi
  log "------------------------------------------"
  log " node:  $update_node, status: '$node_status'"
  option_nodes=$(xmlstarlet sel -t -m "//$update_node/*" -v "name()" -n $xml_file)

  for option in $option_nodes; do
    cmd_count=$(xmlstarlet sel -t -c "count(//$update_node/$option/cmd)" $xml_file)

    if [ "$cmd_count" == 0 ]; then
      continue
    fi

    for cnt in $(seq 1 $cmd_count); do
      cmd_path=$(xmlstarlet sel -t -v "//$update_node/$option/cmd[$cnt]/@path" $xml_file)
      cmd_type=$(xmlstarlet sel -t -m "//$update_node/$option/cmd[$cnt]" -v "concat('-t ', @type)" $xml_file)
      act_value=$(fdtget $cmd_type $dtb_file $cmd_path 2>/dev/null)
      if [ "$?" == 0 ]; then
        cmd_value=$(xmlstarlet sel -t -m "//$update_node/$option" -m "cmd[$cnt]/value" -v "concat(.,' ')" $xml_file)
        [ -n "$cmd_value" ] && cmd_value=${cmd_value::-1}
        if [ "$act_value" != "$cmd_value" ]; then
          continue 2
        fi
      else
        continue 2
      fi
    done
    name_option=$(xmlstarlet sel -t -v "//$update_node/$option/@name" -n $xml_file)
    xmlstarlet ed -L -u "//$update_node/@status" -v "$name_option" $xml_file
    xmlstarlet ed -L -d "//$update_node/${update_node}_migrated" $xml_file
    changed=1
    log " option status changed from '$node_status' to '$name_option'"
  done
  if [ "$changed" == 0 ]; then
    log " option status stay unchanged at '$node_status'"
  fi
  log "------------------------------------------"
  log ""
}

function migrate_dtb_to_xml() {
  log ""
  log "Migrate dtb.xml from dtb.img"
  log ""

  root_nodes=$(xmlstarlet sel -t -m '/*/*' -v "name()" -n $xml_file)
  for node in $root_nodes; do
    node_status=$(xmlstarlet sel -t -v "//$node/@status" $xml_file)
    log "------------------------------------------"
    log " node:  $node, status: '$node_status'"
    option_nodes=$(xmlstarlet sel -t -m "//$node/*" -v "name()" -n $xml_file)
    name_option_available=0

    for option in $option_nodes; do
      cmd_count=$(xmlstarlet sel -t -c "count(//$node/$option/cmd)" $xml_file)
      for cnt in $(seq 1 $cmd_count); do
        cmd_path=$(xmlstarlet sel -t -v "//$node/$option/cmd[$cnt]/@path" $xml_file)
        cmd_type=$(xmlstarlet sel -t -m "//$node/$option/cmd[$cnt]" -v "concat('-t ', @type)" $xml_file)
        act_value=$(fdtget $cmd_type $dtb_file $cmd_path 2>/dev/null)
        if [ "$?" == 0 ]; then
          cmd_value=$(xmlstarlet sel -t -m "//$node/$option" -m "cmd[$cnt]/value" -v "concat(.,' ')" $xml_file)
          [ -n "$cmd_value" ] && cmd_value=${cmd_value::-1}
          if [ "$act_value" != "$cmd_value" ]; then
            continue 2
          fi
        else
          continue 2
        fi
      done
      name_option_available=1
      name_option=$(xmlstarlet sel -t -v "//$node/$option/@name" -n $xml_file)
      if [ "$node_status" != "$name_option" ]; then
        log " migrate dtb.xml node '$node' to '$name_option'"
        xmlstarlet ed -L -u "//$node/@status" -v "$name_option" $xml_file
        continue 2
      else
        log " option status already set, do not migrate option"
      fi
    done
    if [ "$name_option_available" == 0 ]; then
      xmlstarlet ed -L -s "//$node" -t elem -n "${node}_migrated" $xml_file
      xmlstarlet ed -L -u "//$node/@status" -v "migrated" $xml_file
      xmlstarlet ed -L -i "//${node}_migrated" -t attr -n "name" -v "migrated" $xml_file
      log " option not applicable by default dtb.xml, migrate to '${node}_migrated'"
    fi
  done
  log "------------------------------------------"
  log ""
}

function update_dtb_by_dtb_xml() {
  root_nodes=$(xmlstarlet sel -t -m '/*/*' -v "name()" -n $xml_file)

  log ""
  for node in $root_nodes; do
    log "------------------------------------------"
    log " node:   $node"

    node_status=$(xmlstarlet sel -t -v "//$node/@status" $xml_file)
    log " status: $node_status"
    log ""
    cmd_count=$(xmlstarlet sel -t -c "count(//$node/node()[@name='$node_status']/cmd)" $xml_file)

    if [ "$cmd_count" == 0 ]; then
      log " no cmd for node status found"
      continue
    fi

    changed=0
    for cnt in $(seq 1 $cmd_count); do
      cmd_path=$(xmlstarlet sel -t -v "//$node/node()[@name='$node_status']/cmd[$cnt]/@path" $xml_file)
      cmd_type=$(xmlstarlet sel -t -m "//$node/node()[@name='$node_status']/cmd[$cnt]" -v "concat('-t ', @type)" $xml_file)
      act_value=$(fdtget $cmd_type $dtb_file $cmd_path 2>/dev/null)
      if [ "$?" == 0 ]; then
        cmd_value=$(xmlstarlet sel -t -m "//$node/node()[@name='$node_status']" -m "cmd[$cnt]/value" -v "concat('\"', .,'\" ')" $xml_file)
        [ -n "$cmd_value" ] && cmd_value=${cmd_value::-1}
        cmd="fdtput $cmd_type $dtb_file $cmd_path $cmd_value"
        cmd_value="${cmd_value//\"}"
        if [ "$act_value" != "$cmd_value" ]; then
          changed=1
          break
        else
          log " cmd[$cnt]: unchanged, $cmd_path: '$cmd_value' == '$act_value'"
        fi
      else
        log " not applicable"
      fi
    done

    if [ "$changed" == 1 ]; then
      option_nodes=$(xmlstarlet sel -t -m "//$node/*" -v "name()" -n $xml_file)
      name_option_available=0

      for option in $option_nodes; do
        cmd_count=$(xmlstarlet sel -t -c "count(//$node/$option/cmd)" $xml_file)
        for cnt in $(seq 1 $cmd_count); do
          cmd_path=$(xmlstarlet sel -t -v "//$node/$option/cmd[$cnt]/@path" $xml_file)
          cmd_type=$(xmlstarlet sel -t -m "//$node/$option/cmd[$cnt]" -v "concat('-t ', @type)" $xml_file)
          act_value=$(fdtget $cmd_type $dtb_file $cmd_path 2>/dev/null)
          if [ "$?" == 0 ]; then
            cmd_value=$(xmlstarlet sel -t -m "//$node/$option" -m "cmd[$cnt]/value" -v "concat(.,' ')" $xml_file)
            [ -n "$cmd_value" ] && cmd_value=${cmd_value::-1}
            if [ "$act_value" != "$cmd_value" ]; then
              continue 2
            fi
          else
            continue 2
          fi
        done
        name_option_available=1
        break
      done

      if [ "$name_option_available" == 1 ]; then
        eval $cmd
        log " cmd[$cnt]: changed, $cmd_path: '$act_value' -> '$cmd_value', result: $?"
        log " cmd[$cnt]: $cmd"
      else
        xmlstarlet ed -L -s "//$node" -t elem -n "${node}_migrated" $xml_file
        xmlstarlet ed -L -u "//$node/@status" -v "migrated" $xml_file
        xmlstarlet ed -L -i "//${node}_migrated" -t attr -n "name" -v "migrated" $xml_file
        log " option not applicable by default dtb.xml, migrate to '${node}_migrated'"
      fi
    fi
  done
  log "------------------------------------------"
  log ""
}

function update_dtb_xml() {
  root_node_version=$(xmlstarlet sel -t -v "//dtb-settings/@version" $xml_file)
  default_root_node_version=$(xmlstarlet sel -t -v "//dtb-settings/@version" $default_xml_file)

  log ""
  log "------------------------------------------"
  log " dtb-settings version:           $root_node_version"
  log " dtb-settings default version:   $default_root_node_version"

  # default dtb.xml version changed, overwrite user dtb.xml
  if [ $root_node_version -lt $default_root_node_version ]; then
    log " update complete dtb.xml by default dtb.xml"
    cp -p $default_xml_file $xml_file
  fi

  root_nodes=$(xmlstarlet sel -t -m '/*/*' -v "name()" -n $xml_file)
  default_root_nodes=$(xmlstarlet sel -t -m '/*/*' -v "name()" -n $default_xml_file)

  # compare all default dtb.xml nodes with user dtb.xml
  for default_node in $default_root_nodes; do
    log "------------------------------------------"
    log " default node:   $default_node"

    default_node_status=$(xmlstarlet sel -t -v "//$default_node/@status" $default_xml_file)
    default_node_version=$(xmlstarlet sel -t -v "//$default_node/@version" $default_xml_file)
    log " default status: $default_node_status, version: $default_node_version"
    node_status=$(xmlstarlet sel -t -v "//$default_node/@status" $xml_file)
    # new node in default dtb.xml found
    if [ "${#node_status}" == 0 ]; then
      log " node in current dtb.xml not found, get it from default dtb.xml"
      new_node=$(xmlstarlet sel -t -c "//$default_node" $default_xml_file)
      xmlstarlet ed --subnode "/dtb-settings" -t text -n "" -v "$new_node" $xml_file | \
              xmlstarlet unesc | xmlstarlet format > tmp_file
      mv tmp_file $xml_file
    # node already exist in dtb.xml, check if version update
    else
      node_version=$(xmlstarlet sel -t -v "//$default_node/@version" $xml_file)
      log " status: $node_status, version: $node_version"
      # newer version update node
      if [ $node_version -lt $default_node_version ]; then
        log " update node to version $default_node_version"
        xmlstarlet ed -L -d "//$default_node" $xml_file
        new_node=$(xmlstarlet sel -t -c "//$default_node" $default_xml_file)
        xmlstarlet ed --subnode "/dtb-settings" -t text -n "" -v "$new_node" $xml_file | \
                xmlstarlet unesc | xmlstarlet format > tmp_file
        mv tmp_file $xml_file
        option_nodes=$(xmlstarlet sel -t -m "//$default_node/*" -v "name()" -n $xml_file)
        # check if old status still apply and set it if true
        for option in $option_nodes; do
          option_node_name=$(xmlstarlet sel -t -v "//$default_node/$option/@name" $xml_file)
          if [ $node_status == $option_node_name ]; then
            xmlstarlet ed -L -u "//$default_node/@status" -v "$node_status" $xml_file
            log " updated node status to: $node_status"
            break
          fi
        done
      fi
    fi
  done

  # compare all user dtb.xml nodes with default dtb.xml
  for node in $root_nodes; do
    log "------------------------------------------"
    log " node:   $node"
    node_status=$(xmlstarlet sel -t -v "//$node/@status" $default_xml_file)
    if [ "${#node_status}" == 0 ]; then
      xmlstarlet ed -L -d "//$node" $xml_file
      log " node got removed by default dtb.xml"
    else
      log " node still in use by default dtb.xml"
    fi
  done

  log "------------------------------------------"
  log ""
}

if [ ! -f $dtb_file ]; then
  log "Error, not found: $dtb_file, exit now"
  exit 2
fi

grep -q " $BOOT_ROOT vfat ro," /proc/mounts
rw="$?"

if [ "$rw" == "0" ]; then
  log "Try to remount '$BOOT_ROOT' in 'rw' mode"
  mount -o rw,remount "$BOOT_ROOT"
  if [ "$?" != "0" ]; then
    echo "Failed to remount '$BOOT_ROOT' in 'rw' mode"
    exit 12
  fi
fi

if [ ! -f $xml_file ]; then
  if [ -f $default_xml_file ]; then
    log "Creating dtb.xml..."
    cp -p $default_xml_file $xml_file
  else
    log "Error, not found: '$default_xml_file', exit now"
    exit 2
  fi
fi

if [ "$migrate" == 1 ]; then
  migrate_dtb_to_xml
elif [ "$update_migrated" == 1 ]; then
  update_migrated_xml
else
  update_dtb_xml
  update_dtb_by_dtb_xml
fi

if [ "$rw" == "0" ]; then
  log "Try to remount '$BOOT_ROOT' in 'ro' mode"
  mount -o ro,remount "$BOOT_ROOT"
  if [ "$?" != "0" ]; then
    echo "Failed to remount '$BOOT_ROOT' in 'ro' mode"
    exit 12
  fi
fi

exit $changed
