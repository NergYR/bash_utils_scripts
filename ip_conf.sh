#!/usr/bin/env bash

echo "--------------------"
echo "Welcome to IP Conf"
echo "Endorium Copyright"
echo "--------------------"


# Choice of IP Conf

network_prov="/etc/network/interfaces"
netplan_sources="/etc/netplan/...yml"
DHCP="True"


read -p "Enter your network service [/etc/network/interfaces or netplan]" network_prov
read -p "Do you want to use DHCP? [True]" DHCP


echo "--------------------------------------"
echo "Recap : "
echo "Network Provider :   "$network_prov
echo "Linux Distro  :      "$(uname -o)
echo "actual IP Address:   "$(hostname -I)
echo "Use DHCP : "         "$DHCP"
echo "--------------------------------------"


function netplan_conf () {
    echo "$1" # arguments are accessible through $1, $2,...
}

function interface_conf () {
    echo "$1" # arguments are accessible through $1, $2,...
}





read -p "Continue with this infos ?" confirmation
    if [[ "$confirmation" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        if [[ "${network_prov}" == "netplan" ]]; then
            netplan_conf
        elif [[ "${network_prov}" == "/etc/network/interfaces" ]]; then
            interace_conf
        fi
    else
        exit 2
    fi

