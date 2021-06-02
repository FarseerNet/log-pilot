#!/usr/bin/env bash
#
# build docker image
#

build()
{
    echo -e "building image: log-pilot:latest\n"

    docker build -t farseernet/log-pilot:$1_es7.x -f Dockerfile.$1 . 
}

case $1 in
fluentd)
    build fluentd
    ;;
*)
    build filebeat
    ;;
esac
