# Yet another Redis image

Based on Redis 3.2-alpine, it auto-joins consul cluster. It works magically on AWS ECS pulling all required data from AWS metadata.

However, you can define these ENV variables and it should join any cluster you want:
- `CONSUL_ADDR`
- `NODE_ADDR`
- `NODE_NAME`
- `SERVICE_ADDR`
- `SERVICE_ID` - by default it takes form of `SERVICE_NAME-HOSTNAME` (Where `HOSTNAME` is container's host name)