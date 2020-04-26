
#!/bin/bash

readonly SUBNET='192.168.2.0/24'
readonly GATEWAY='192.168.2.1'

# Range of 32 addresses: 192.168.2.192 - 192.168.2.223
readonly IPRANGE='192.168.2.192/27'
readonly AUX_ADDR='host=192.168.2.223'

# 802.1q trunked bridge: https://docs.docker.com/network/#8021q-trunked-bridge-example
readonly PARENT=enp2s0.1

docker network create -d macvlan -o parent=${PARENT} \
  --subnet ${SUBNET} \
  --gateway ${GATEWAY} \
  --ip-range ${IPRANGE} \
  macvlan-${PARENT}

#   --aux-address 'host=192.168.2.223' \
