#!/bin/sh
set -e

# Assume that the HTTP client is running on Docker bridge on default port
if [ -z ${CONSUL_ADDR+x} ]; then
	export CONSUL_ADDR=`ip ro | grep default | awk '{print $3}'`:8500
fi

# If hostname is not provided, use EC2 instance hostname
if [ -z ${NODE_NAME+x} ]; then
	export NODE_NAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname | sed -E 's/(ip(-[0-9]{1,3}){4})\..+/\1/')
fi

# If addres is not provided, use EC2 instance IP
if [ -z ${NODE_ADDR+x} ]; then
	export NODE_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
fi

# If addres is not provided, use EC2 instance IP
if [ -z ${SERVICE_ADDR+x} ]; then
	export SERVICE_ADDR=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
fi

# Generate service id if it's not defined
if [ -z ${SERVICE_ID+x} ]; then
	export SERVICE_ID="redis-$HOSTNAME"
fi

# Put values in the service config file
sed -i "s/NODE_NAME/${NODE_NAME}/g" "/etc/redis/redis-service.json"
sed -i "s/NODE_ADDR/${NODE_ADDR}/g" "/etc/redis/redis-service.json"
sed -i "s/SERVICE_ADDR/${SERVICE_ADDR}/g" "/etc/redis/redis-service.json"
sed -i "s/SERVICE_ID/${SERVICE_ID}/g" "/etc/redis/redis-service.json"

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	chown -R redis .
	exec su-exec redis "$0" "$@"
fi

if [ "$1" = 'redis-server' ]; then
	# Disable Redis protected mode [1] as it is unnecessary in context
	# of Docker. Ports are not automatically exposed when running inside
	# Docker, but rather explicitely by specifying -p / -P.
	# [1] https://github.com/antirez/redis/commit/edd4d555df57dc84265fdfb4ef59a4678832f6da
	doProtectedMode=1
	configFile=
	if [ -f "$2" ]; then
		configFile="$2"
		if grep -q '^protected-mode' "$configFile"; then
			# if a config file is supplied and explicitly specifies "protected-mode", let it win
			doProtectedMode=
		fi
	fi
	if [ "$doProtectedMode" ]; then
		shift # "redis-server"
		if [ "$configFile" ]; then
			shift
		fi
		set -- --protected-mode no "$@"
		if [ "$configFile" ]; then
			set -- "$configFile" "$@"
		fi
		set -- redis-server "$@" # redis-server [config file] --protected-mode no [other options]
		# if this is supplied again, the "latest" wins, so "--protected-mode no --protected-mode yes" will result in an enabled status
	fi
fi

SERVICE_CONFIG=$(cat /etc/redis/redis-service.json)
CONSUL_RESP=$(curl -X PUT -d "$SERVICE_CONFIG" "http://$CONSUL_ADDR/v1/catalog/register")

echo "Consul resp: $CONSUL_RESP"
# if [ "$CONSUL_RESP" -ne "true" ]; then
	# die "Redis server could not be started. Consul response: $CONSUL_RESP"
# fi

exec "$@"