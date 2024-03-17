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



# minimal sample /etc/dhcp/dhcpd.conf
#default-lease-time 600;
#max-lease-time 7200;
    
#subnet 192.168.1.0 netmask 255.255.255.0 {
# range 192.168.1.150 192.168.1.200;
# option routers 192.168.1.254;
# option domain-name-servers 192.168.1.1, 192.168.1.2;
# option domain-name "mydomain.example";
#}


function isc-server () {

    echo "Verification du fichier source du serveur :"
    read -p "$isc_sources est correct ?" confirmation2
    if [[ "$confirmation2" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        first=$(( $(echo "$NetID" | cut -d. -f4) + 1 ))
        last=$(( first + number - 2 ))
        subnet="$NetID netmask $netmask"
        first_ip="${NetID%.*}.$first"
        last_ip="${NetID%.*}.$last"

        if [[ $first_ip == "$last_ip" ]]; then echo "Invalid range IP"; isc-server; fi
        if [[ $first_ip == "$gateway" || $last_ip == "$gateway" ]]; then echo "You have included gateway IP in the range"; isc-server; fi


        echo "subnet $subnet {" >> "$isc_sources"
        echo "  range $first_ip $last_ip;" >> "$isc_sources"
        echo "  option routers $gateway;" >> "$isc_sources"
        echo "  option domain-name-servers $dns;" >> "$isc_sources"
        echo "  option domains \"$hostname\";" >> "$isc_sources"
        echo "}" >> "$isc_sources"

    else

        read -p "Where are the config files ?" isc_sources
        isc-server
        
    fi

}

function dnsmask () {
 echo "Verification du fichier source du serveur :"
    read -p "$dnsmask_sources est correct ?" confirmation2
    if [[ "$confirmation2" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        first=$(( $(echo "$NetID" | cut -d. -f4) + 1 ))
        last=$(( first + number - 2 ))
        subnet="$NetID netmask $netmask"
        first_ip="${NetID%.*}.$first"
        last_ip="${NetID%.*}.$last"

        if [[ $first_ip == "$last_ip" ]]; then echo "Invalid range IP"; isc-server; fi
        if [[ $first_ip == "$gateway" || $last_ip == "$gateway" ]]; then echo "You have included gateway IP in the range"; isc-server; fi


        echo "dhcp-range="$first_ip","$last_ip",60, 7d" >> $dnsmask_sources
        echo "dhcp-option=option:netmask,"$netmask"" >> $dnsmask_sources
        echo "dhcp-option=option:router,"$gateway"" >> $dnsmask_sources
        echo "dhcp-option=option:dns-server,"$dns"" >> $dnsmask_sources
        echo "dhcp-option=option:domain-name,"$hostname"" >> $dnsmask_sources

    else

        read -p "Where are the config files ?" dnsmask_sources
        dnsmask
        
    fi

}





 
function dhcp_create() {
    read -p "Which dhcp server you use ?" dhcp_server
    if [[ "${dhcp_server}" == "isc" || "${dhcp_server}" == "dhcpd" ]]; then
        echo "your are using dhcpd server, isc-dhcp-server"
        isc-server
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

