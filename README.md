# Docker container for a Samba 4 active directory domain controller

This is a alpine-linux base samba 4 AD DC image.
[![Docker Automated](https://img.shields.io/docker/cloud/automated/p3tr/samba-dc.svg)](https://hub.docker.com/r/p3tr/samba-dc)
[![Docker Build](https://img.shields.io/docker/cloud/build/p3tr/samba-dc.svg)](https://hub.docker.com/r/p3tr/samba-dc)

## Build the container

```
    git clone https://github.com/p3t/docker-samba-dc.git
    cd docker-samba-dc

    docker build -t p3t/samba-dc .
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
        -eDOMAIN=your-domain.local -eNO_COMPLEXITY=true -eADMIN_PASSWORD=<your-pass> \
        p3t/samba-dc setup
```

## Make the controller accessible from the network
There are multiple options to make a container accessible from the network.
One option is to start the container in the host-network I decided to use a 
[macvlan](https://docs.docker.com/network/#8021q-trunked-bridge-example), where
docker creates a sub-interface of my physical network controller and assigns the container 
a public ip. *Note*: You have to make sure, that the IP-addesses in the provided range are
not in-use (e.g. used by a DHCP server):

```
#!/bin/bash

# This is the subnet-mask and the gateway of the network where your "host" is running in
readonly SUBNET='192.168.2.0/24'
readonly GATEWAY='192.168.2.1'

# Reserved range of IP-addresses which can be used by docker
# Range of 32 addresses: 192.168.2.192 - 192.168.2.223
readonly IPRANGE='192.168.2.192/27'

# Optional: Add static IP-Address assignments to containers
readonly AUX_ADDR='host=192.168.2.223'

# 802.1q trunked bridge: 
readonly PARENT=enp2s0.1

docker network create -d macvlan -o parent=${PARENT} \
  --subnet ${SUBNET} \
  --gateway ${GATEWAY} \
  --ip-range ${IPRANGE} \
  macvlan_${PARENT}
```

## Run the primary domain controller

Example:
```
    docker run --rm \
        -v samba:/samba \
        --network macvlan_enp2s0.1 \
        p3t/samba-dc start
```

## Debug/test container

You can directly start an interactive shell and run the `entrypoint.sh` or parts of it manually on the command prompt:

```
        docker run -it \
        --privileged=true \
        --mount source=samba,target=/samba \
        -eDOMAIN=your-domain.local -eNO_COMPLEXITY=true -eADMIN_PASSWORD=<your-pass> \
        p3t/samba-dc ash
```

## References/documentation

- https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller
- https://wiki.samba.org/index.php/Joining_a_Samba_DC_to_an_Existing_Active_Directory
- https://www.samba.org/samba/docs/current/man-html/samba-tool.8.html
- https://www.samba.org/samba/docs/current/man-html/smb.conf.5.html
- https://wiki.samba.org/index.php/Active_Directory_Naming_FAQ
- https://docs.docker.com/network/macvlan/

# Credits
Thanks to https://github.com/Fmstrat/samba-domain I took this project as initial inspiration.
