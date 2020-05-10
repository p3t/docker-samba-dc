#!/bin/bash
#
# Creates a docker macvlan - subnet/gateway are the same as your lan settings. 
# Choose an ip-range not used by DHCP by providing the "start-ip" by setting SUBIFNO
#

# Gateway (usually the internet router, example 192.168.1.1)
readonly GATEWAY=${GATEWAY:-$(ip route show default | cut -d' ' -f3 -)}

# Sub-interface number also used for IP-range start
readonly SUBIFNO=${SUBIFNO:-160}

# The parent interface (the one which routes to the internet, e.g. eth0 or enp2s0)
readonly PARENTIF=${PARENTIF:-$(ip route show default | cut -d' ' -f5 -)}

# name of the macvlan
readonly NET_NAME="macvlan-${PARENTIF}"

# Subnet range asumming here a class C subnet with 254 addresses (255.255.255.0)
readonly SUBNET=${SUBNET:-"${GATEWAY}/24"}

# use the gateway's ip-address to calculate the start or the range which is free to use (not used by DHCP)
readonly GW="${GATEWAY}EOL"
readonly START_IP=${START_IP:-${GW/".$(echo ${GATEWAY}|cut -d'.' -f4)EOL"/".$SUBIFNO"}}

# Range of 4 addresses starting at start-ip (e.g. "192.168.2.160/30")
readonly IPRANGE="${START_IP}/30"

# The first address is reserved for host -> macvlan access
readonly HOST_AUXIP=${START_IP}

# name of the inteface on the host to access the macvlan via the HOST_AUXIP
readonly VDEF_NAME="${PARENTIF}.${SUBIFNO}"

createDockerMacvlan () {

    # Note about 802.1q trunked bridge macvlans: 
    # I assume that you need to have a VLAN capable router or layer-3 switch in order to get it working
    # As I do not have such kind of hardware my containers couldn't connect to the outside world
    # and they where not reachable from anywhere

    echo "Creating docker network '${NET_NAME}'..."
    echo "... gateway ........ : ${GATEWAY}"
    echo "... sub-net ........ : ${SUBNET}"
    echo "... parent interface : ${PARENTIF}"
    echo "... ip range ....... : ${IPRANGE}"
    echo "... reserved host ip : ${HOST_AUXIP}"

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

cleanNetwork () {
  echo "Cleaning up ${NET_NAME}"
  docker network rm ${NET_NAME}
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
    cleanNetwork
    ;;
  *)
    createDockerMacvlan
    createHostMacvlanRoute
    ;;
esac

echo "done"