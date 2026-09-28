#!/usr/bin/env bash
# Uso: ./sdr.sh <comando>
#   build    construye la imagen (la primera vez tarda mucho)
#   grc      abre GNU Radio Companion
#   find     busca la X310 en la red
#   probe    muestra el detalle de la X310 (FPGA, daughterboards)
#   shell    abre una terminal dentro del contenedor
set -e
cd "$(dirname "$0")"

ADDR="${USRP_ADDR:-192.168.10.2}"

# Crear el .env con el usuario de quien lo ejecuta
echo "UID=$(id -u)"  > .env
echo "GID=$(id -g)" >> .env

run() { docker compose run --rm sdr "$@"; }

case "$1" in
  build) docker compose build ;;
  grc)   xhost +local: >/dev/null; run gnuradio-companion ;;
  find)  run uhd_find_devices --args "addr=$ADDR" ;;
  probe) run uhd_usrp_probe --args "addr=$ADDR" ;;
  shell) xhost +local: >/dev/null; run bash ;;
  *)     sed -n '2,7p' "$0" ;;
esac
