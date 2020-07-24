#! /bin/sh
sudo ip addr delete 192.168.0.5/32 dev eno1
sudo ip link set eno1 down
