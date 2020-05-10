# Docker container for a Samba 4 active directory domain controller
![Docker Multiplatform Build](https://github.com/p3t/docker-samba-dc/workflows/Docker%20Image%20CI/badge.svg)

This is a alpine-linux base samba 4 AD DC image.

## Build the container

```
    git clone https://github.com/p3t/docker-samba-dc.git
    cd docker-samba-dc

    docker build -t p3tr/samba-dc .
```

## Initialize domain configuration
The samba-tool which is used to setup the domain tries to modify the ACL of the sys_vol, which leads to an error,
when the container is not run with `--privileged=true`.
The priviledged option is not required to run the DC after the setup (once the config has been created).

```
    docker volume create samba

    docker run --rm \
        --privileged=true \
        --mount source=samba,target=/samba \
        -eDOMAIN=your-domain.local \
        -eNO_COMPLEXITY=true \
        -eADMIN_PASSWORD=<your-pass> \
        -eDNS_FORWARD=192.168.2.1 \
        p3tr/samba-dc setup
```

## Make the controller accessible from the network
There are multiple options to make a container accessible from the network.
One option is to start the container in the host-network I decided to use a 
[macvlan](https://docs.docker.com/network/macvlan/). 

*Note*: You have to make sure, that the IP-addesses in the provided range are
not in-use (e.g. used by a DHCP server):

```
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
readonly HOST_AUXIP=$START_IP

readonly SUBIFNO=160
readonly PARENTIF="enp2s0"
readonly NETNAME="macvlan-${PARENTIF}"

# Note about 802.1q trunked bridge macvlans: 
# I assume that you need to have a VLAN capable router or layer-3 switch in order to get it working
# As I do not have such kind of hardware my containers couldn't connect to the outside world
# and they where not reachable from anywhere

echo "Creating docker network '${NETNAME}'..."

docker network create -d macvlan -o parent=${PARENTIF} \
  --subnet ${SUBNET} \
  --gateway ${GATEWAY} \
  --ip-range ${IPRANGE} \
  --aux-address "host=${HOST_AUXIP}" \
  ${NETNAME}

readonly VDEF_NAME="${PARENTIF}.${SUBIFNO}"

echo "Creating sub-dev '${VDEF_NAME}' for host -> macvlan-routing..."

sudo ip link add ${VDEF_NAME} link ${PARENTIF} type macvlan mode bridge
sudo ip addr add ${HOST_AUXIP}/32 dev ${VDEF_NAME}
sudo ip link set ${VDEF_NAME} up
sudo ip route add ${IPRANGE} dev ${VDEF_NAME}

echo "done"
```

## Run the primary domain controller

Example:
```
    docker run -d --rm \
        -v samba:/samba \
        --network macvlan-enp2s0 \
        --name sambaDC \
        --hostname sambaDC \
        --ip 192.168.2.161 \
        --mac-address aa:bb:cc:ee:44:55 \
        p3tr/samba-dc start
```

## Debug/test container

You can directly start an interactive shell and run the `entrypoint.sh` or parts of it manually on the command prompt:

```
        docker run -it \
        --privileged=true \
        --mount source=samba,target=/samba \
        -eDOMAIN=your-domain.local -eNO_COMPLEXITY=true -eADMIN_PASSWORD=<your-pass> \
        p3tr/samba-dc ash
```

## References/documentation

- https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
- https://wiki.samba.org/index.php/Joining_a_Samba_DC_to_an_Existing_Active_Directory
- https://www.samba.org/samba/docs/current/man-html/samba-tool.8.html
- https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- https://wiki.samba.org/index.php/Active_Directory_Naming_FAQ
- https://docs.docker.com/network/macvlan/
- https://hicu.be/docker-networking-macvlan-bridge-mode-configuration

# Credits
Thanks to https://github.com/Fmstrat/samba-domain I took this project as initial inspiration.
