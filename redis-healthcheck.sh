#!/bin/sh
printf 'PING\n' | nc SERVICE_ADDR 6379 | grep -q PONG \ && printf 'OK' || {
  printf 'NO PONG' 1>&2;
  exit 1;
}