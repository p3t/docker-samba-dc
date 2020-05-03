#!/bin/bash

docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64

docker buildx create --name mybuilder

docker buildx inspect --bootstrap

docker buildx use mybuilder

echo "==============================================================================="
echo "Example arm-build: "
echo "    docker buildx build --platform linux/arm/v7 -t p3t/samba-dc:arm-v7 --load ."
echo "==============================================================================="
