#!/usr/bin/env bash
set -e -o pipefail

start_zwave_js_ui () {
    source ${NVM_DIR:?}/nvm.sh

    echo "Starting Z-Wave JS UI ..."
    echo

    cd /opt/zwave-js-ui
    exec node server/bin/www
}

start_zwave_js_ui
