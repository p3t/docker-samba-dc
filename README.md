# Docker container for a Samba 4 active directory domain controller

This is a alpine-linux base samba 4 AD DC image.
[![Docker Automated](https://img.shields.io/docker/cloud/automated/p3tr/samba-dc.svg)](https://hub.docker.com/repository/docker/p3tr/samba-dc)
[![Docker Build](https://img.shields.io/docker/cloud/build/p3tr/samba-dc.svg)](https://hub.docker.com/repository/docker/p3tr/samba-dc)

## Build the container

```
    git clone https://github.com/p3t/docker-samba-dc.git
    cd docker-samba-dc

    docker build -t p3t/samba-dc .
```

## Setup a new AD domain controller
The samba-tool which is used to setup the domain tries to modify the ACL of the sys_vol, which leads to an error,
when the container is not run with `--privileged=true`.
The priviledged option is not required to run the DC after the setup (once the config has been created).

```
    docker volume create samba

    docker run \
        --privileged=true \
        --mount source=samba,target=/samba \
        -eDOMAIN=your-domain.local -eNO_COMPLEXITY=true -eADMIN_PASSWORD=<your-pass> \
        p3t/samba-dc setup
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
