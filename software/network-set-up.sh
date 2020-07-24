#! /bin/sh
sudo ip addr add 192.168.0.5/32 dev eno1
sudo ip route add default via 192.168.0.5
sudo ip link set eno1 up
