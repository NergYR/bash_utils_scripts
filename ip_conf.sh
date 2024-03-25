#!/usr/bin/env bash

echo "--------------------"
echo "Welcome to DHCP Conf"
echo "Endorium Copyright"
echo "--------------------"

# Choice of hosts

read -p "NetID : " NetID
read -p "Host Name : " hostname
read -p "Number of Hosts : " number
read -p "Netmask : " netmask
read -p "Gateway : " gateway
read -p "DNS : " dns

echo "--------------------------------------"
echo "Recap : "
echo "NetID :           ${NetID}"
echo "Hostname :        ${hostname}"
echo "Netmask :         ${netmask}"
echo "Number of host :  ${number}"
echo "Gateway :         ${gateway}"
echo "DNS :             ${dns}"
echo "--------------------------------------"

isc_sources="/etc/dhcp/dhcpd.conf"
dnsmask_sources="/etc/dnsmasq.conf"

# Function to convert an IP address to an integer
ip2int() {
    local a b c d
    IFS='.' read -r a b c d <<< "$1"
    echo "$(( (a << 24) + (b << 16) + (c << 8) + d ))"
}

# Function to convert an integer to an IP address
int2ip() {
    local IFS=.
    echo "$(( (i >> 24) & 255 ))"."$(( (i >> 16) & 255 ))"."$(( (i >> 8) & 255 ))"."$(( i & 255 ))"
}

# Function to convert an integer to a 32-bit binary string
int2bin() {
    local num=$1
    local bin=

    for ((i = 31; i >= 0; i--)); do
        ((num & (1 << i))) && bin+="1" || bin+="0"
    done

    echo "$bin"
}

# Function to calculate the network range based on the netmask
calculate_network_range() {
    local network=$1
    local mask=$2

    local network_int=$(ip2int $network)
    local mask_int=$(ip2int $mask)

    local broadcast_int=$(( network_int | mask_int ))
    local first_ip_int=$(( broadcast_int + 1 ))

    # Calculate the number of bits set in the mask
    local mask_bin=$(int2bin $mask_int)
    local bits=0
    for ((i = 0; i < 32; i++)); do
        if [[ "${mask_bin:$i:1}" == "1" ]]; then
            ((bits++))
        fi
    done

    # Calculate the last IP in the range
    local last_ip_int=$((broadcast_int - (1 << (32 - bits))))

    local first_ip=$(int2ip $first_ip_int)
    local last_ip=$(int2ip $last_ip_int)

    # Check if the range can accommodate the requested number of hosts
    local available_hosts=$(((last_ip_int - first_ip_int) - 2))
    if ((number > available_hosts)); then
        echo "Error: Not enough IP addresses in the range to accommodate $number hosts."
        echo "Please enter a smaller number of hosts or a larger netmask."
        exit 1
    fi

    echo "$first_ip-$last_ip"
}

isc_server() {

    echo "Verification du fichier source du serveur :"
    read -p "$isc_sources est correct ?" confirmation2
    if [[ "$confirmation2" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        # Calculate network range
        network_range=$(calculate_network_range $NetID $netmask)
        first_ip=$(echo $network_range | cut -d'-' -f1)
        last_ip=$(echo $network_range | cut -d'-' -f2)

        if [[ $first_ip == "$gateway" || $last_ip == "$gateway" ]]; then
            echo "Error: Gateway IP address is included in the range."
            echo "Please enter a different gateway IP address."
            exit 1
        fi

        echo "subnet $NetID netmask $netmask {" >> "$isc_sources"
        echo "  range $first_ip $last_ip;" >> "$isc_sources"
        echo "  option routers $gateway;" >> "$isc_sources"
        echo "  option domain-name-servers $dns;" >> "$isc_sources"
        echo "  option domain-name \"$hostname\";" >> "$isc_sources"
        echo "}" >> "$isc_sources"

    else

        read -p "Where are the config files ?" isc_sources
        isc_server

    fi

}

dnsmask() {
 echo "Verification du fichier source du serveur :"
    read -p "$dnsmask_sources est correct ?" confirmation2
    if [[ "$confirmation2" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        # Calculate network range
        network_range=$(calculate_network_range $NetID $netmask)
        first_ip=$(echo $network_range | cut -d'-' -f1)
        last_ip=$(echo $network_range | cut -d'-' -f2)

        if [[ $first_ip == "$gateway" || $last_ip == "$gateway" ]]; then
            echo "Error: Gateway IP address is included in the range."
            echo "Please enter a different gateway IP address."
            exit 1
        fi

        echo "dhcp-range="$first_ip","$last_ip",60, 7d" >> "$dnsmask_sources"
        echo "dhcp-option=option:netmask,""$netmask"" >> "$dnsmask_sources"
        echo "dhcp-option=option:router,""$gateway"" >> "$dnsmask_sources"
        echo "dhcp-option=option:dns-server,""$dns"" >> "$dnsmask_sources"
        echo "dhcp-option=option:domain-name,""$hostname"" >> "$dnsmask_sources"

    else

        read -p "Where are the config files ?" dnsmask_sources
        dnsmask

    fi

}

function dhcp_create() {
    read -p "Which dhcp server you use ?" dhcp_server
    if [[ "${dhcp_server}" == "isc" || "${dhcp_server}" == "dhcpd" ]]; then
        echo "your are using dhcpd server, isc-dhcp-server"
        isc_server
    elif [[ "${dhcp_server}" == "dnsmask" ]]; then
        echo "your are using dnsmask server"
        dnsmask
    else
        echo "Wrong dhcp server"
        dhcp_create
    fi
}

read -r -p "All informations are True [y/n] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]
then

    dhcp_create

else
    echo "Try Again"
    exit 2
fi
