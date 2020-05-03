#!/bin/bash
#
# Creates a docker macvlan - subnet/gateway are the same as your lan settings. 
# Choose an ip-range not used by DHCP
#
readonly SUBNET='192.168.2.0/24'
readonly GATEWAY='192.168.2.1'

# Range of 4 addresses starting at 192.168.2.160
readonly START_IP=192.168.2.160
readonly IPRANGE="${START_IP}/30"
readonly HOST_AUXIP=${START_IP}

readonly SUBIFNO=160
readonly PARENTIF="enp2s0"
readonly NET_NAME="macvlan-${PARENTIF}"

readonly VDEF_NAME="${PARENTIF}.${SUBIFNO}"

createDockerMacvlan () {

    # Note about 802.1q trunked bridge macvlans: 
    # I assume that you need to have a VLAN capable router or layer-3 switch in order to get it working
    # As I do not have such kind of hardware my containers couldn't connect to the outside world
    # and they where not reachable from anywhere

    echo "Creating docker network '${NET_NAME}'..."

    docker network create -d macvlan -o parent=${PARENTIF} \
      --subnet ${SUBNET} \
      --gateway ${GATEWAY} \
      --ip-range ${IPRANGE} \
      --aux-address "host=${HOST_AUXIP}" \
      ${NET_NAME}
}

createHostMacvlanRoute () {
    echo "Creating sub-dev '${VDEF_NAME}' for host -> macvlan-routing..."
    sudo ip link add ${VDEF_NAME} link ${PARENTIF} type macvlan mode bridge
    sudo ip addr add ${HOST_AUXIP}/32 dev ${VDEF_NAME}
    sudo ip link set ${VDEF_NAME} up
    sudo ip route add ${IPRANGE} dev ${VDEF_NAME}
}

cleanRoute () {
  echo "Cleaning up ${VDEF_NAME}..."
  sudo ip link delete ${VDEF_NAME}
  sudo ip route del ${IPRANGE}
}

case "$1" in
  route)
    createHostMacvlanRoute
    ;;
  macvlan)
    createDockerMacvlan
    ;;
  clean)
    cleanRoute
    ;;
  *)
    createDockerMacvlan
    createHostMacvlanRoute
    ;;
esac

echo "done"