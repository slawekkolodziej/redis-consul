#!/bin/sh
set -e

export CONSUL_ADDRESS=`ip ro | grep default | awk '{print $3}'`:8500

if [ "$BIND_TO_EC2" ]
then
	export REDIS_ADDRESS=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
fi

exec /usr/local/bin/containerbuddy redis-server