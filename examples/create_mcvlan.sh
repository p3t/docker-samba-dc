
#!/bin/bash

readonly SUBNET='192.168.2.0/24'
readonly GATEWAY='192.168.2.1'
readonly HOST_IP=$(ip route get 1 | head -1 | cut -d' ' -f7)

# Range of 4 addresses starting at 192.168.2.160
readonly START_IP=${1:-192.168.2.160}
readonly IPRANGE="${START_IP}/30"
readonly HOST_AUXIP=${3:-$START_IP}

# 802.1q trunked bridge: https://docs.docker.com/network/#8021q-trunked-bridge-example
readonly SUBIFNO=${2:-160}
readonly PARENTIF="enp2s0"
readonly NETNAME="macvlan-${PARENTIF}"

set -x 

docker network create -d macvlan -o parent=${PARENTIF} \
  --subnet ${SUBNET} \
  --gateway ${GATEWAY} \
  --ip-range ${IPRANGE} \
  --aux-address "host=${HOST_AUXIP}" \
  ${NETNAME}

readonly VDEF_NAME="${PARENTIF}.${SUBIFNO}"


sudo ip link add ${VDEF_NAME} link ${PARENTIF} type macvlan mode bridge
sudo ip addr add ${HOST_AUXIP}/32 dev ${VDEF_NAME}
sudo ip link set ${VDEF_NAME} up
sudo ip route add ${IPRANGE} dev ${VDEF_NAME}