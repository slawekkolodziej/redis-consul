#!/bin/sh
set -e

export CONSUL_ADDRESS=`ip ro | grep default | awk '{print $3}'`:8500
exec /usr/local/bin/containerbuddy redis-server