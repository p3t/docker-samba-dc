#!/bin/bash
set -e

echo "Building image..."
docker build -t p3tr/samba-dc:test .

# Cleanup from previous runs
docker stop samba-primary samba-replica 2>/dev/null || true
docker rm samba-primary samba-replica 2>/dev/null || true
docker network rm samba-net 2>/dev/null || true
docker volume rm samba-primary samba-replica 2>/dev/null || true

# Setup network
docker network create --subnet 10.99.0.0/16 samba-net

# Setup volumes
docker volume create samba-primary
docker volume create samba-replica

echo "Setting up Primary DC..."
docker run --rm --privileged=true -v samba-primary:/samba --network samba-net \
    --ip 10.99.0.10 \
    -e HOST_IP=10.99.0.10 \
    -e DOMAIN=TESTDOM.LOCAL -e NO_COMPLEXITY=true -e ADMIN_PASSWORD=TestPassw0rd! \
    p3tr/samba-dc:test setup

echo "Starting Primary DC..."
docker run -d --name samba-primary -v samba-primary:/samba --network samba-net \
    --ip 10.99.0.10 \
    --hostname dc1 \
    p3tr/samba-dc:test start

echo "Getting IP of Primary DC..."
PRIMARY_IP="10.99.0.10"
echo "Primary IP: $PRIMARY_IP"

echo "Waiting for Primary DC to start completely..."
for i in {1..30}; do
    if docker exec samba-primary smbclient -L localhost -N >/dev/null 2>&1; then
        echo "Primary DC is up and running!"
        sleep 10
        break
    fi
    sleep 2
done
docker logs samba-primary


echo "Setting up Replica DC..."
docker run --rm --privileged=true -v samba-replica:/samba --network samba-net \
    --ip 10.99.0.11 \
    -e DOMAIN=TESTDOM.LOCAL -e NO_COMPLEXITY=true -e ADMIN_PASSWORD=TestPassw0rd! \
    --dns=$PRIMARY_IP \
    p3tr/samba-dc:test join

echo "Starting Replica DC..."
docker run -d --name samba-replica -v samba-replica:/samba --network samba-net \
    --ip 10.99.0.11 \
    --hostname dc2 \
    --dns=$PRIMARY_IP \
    p3tr/samba-dc:test start

echo "Waiting for Replica DC to start..."
sleep 15
docker logs samba-replica

echo "Checking replication status..."
# drs showrepl outputs successful replications
docker exec samba-replica samba-tool drs showrepl > repl_status.txt
cat repl_status.txt

if grep -q "failed" repl_status.txt; then
    echo "Replication failed!"
    exit 1
fi

echo "Running built-in tests..."
docker exec -e ADMIN_PASSWORD=TestPassw0rd! samba-primary /test.sh
docker exec -e ADMIN_PASSWORD=TestPassw0rd! samba-replica /test.sh

echo "Replication is running and tests passed!"

echo "Cleaning up..."
docker stop samba-primary samba-replica
docker rm samba-primary samba-replica
docker volume rm samba-primary samba-replica
docker network rm samba-net
echo "Success!"
