#!/usr/bin/env bash
set -E -e -o pipefail

set_umask() {
    # Configure umask to allow write permissions for the group by default
    # in addition to the owner.
    umask 0002
}

start_zwave_js_ui () {
    source ${NVM_DIR:?}/nvm.sh

    echo "Starting Z-Wave JS UI ..."
    echo

    cd /opt/zwave-js-ui
    exec node server/bin/www
}

set_umask
start_zwave_js_ui
