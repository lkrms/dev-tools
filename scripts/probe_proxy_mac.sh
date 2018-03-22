#!/bin/bash

PROXY_LIST=("10.10.10.1 3128")

function set_proxy {

    echo "PROXY_LAST_IP=$PROXY_NEW_IP" > $PROXY_SCRIPT

    if [ $# -gt 0 ]; then

        echo "export http_proxy=http://$1:$2" >> $PROXY_SCRIPT
        echo "export https_proxy=http://$1:$2" >> $PROXY_SCRIPT
        echo "export all_proxy=http://$1:$2" >> $PROXY_SCRIPT

        git config --global http.proxy "http://$1:$2"

    else

        echo "unset http_proxy" >> $PROXY_SCRIPT
        echo "unset https_proxy" >> $PROXY_SCRIPT
        echo "unset all_proxy" >> $PROXY_SCRIPT

        git config --global --unset http.proxy

    fi

}

PROXY_SCRIPT=$HOME/.set_proxy

if [ -f "$PROXY_SCRIPT" ]; then

    . "$PROXY_SCRIPT"

fi

PROXY_NEW_IP=`ifconfig | grep 'inet ' | grep -v '127\.0\.0\.1' | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' | head -1`

if [ "$PROXY_LAST_IP" != "$PROXY_NEW_IP" ]; then

    set_proxy

    for PROXY_SPEC in "${PROXY_LIST[@]}"; do

        (if nc -zG 1 $PROXY_SPEC >/dev/null 2>/dev/null; then

            set_proxy $PROXY_SPEC

        fi) &

    done

    wait

    . "$PROXY_SCRIPT"

fi

