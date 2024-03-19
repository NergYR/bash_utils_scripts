#!/usr/bin/env bash


maria_source="/etc/mysql/my.cnf"

echo "----------------------------"
echo "Lamp Installation script"
echo "Endorium Copyright"
echo "----------------------------"

read -p "Wich SGDB you are using ? " sgdb
read -p "You prefer to install Nginx or Apache ? " web

echo "--------------------------------------"
echo "Recap : "
echo "SGDB Server :   "$sgdb
echo "Web Server  :   "$web


function install-apache () {
    apt-get update && apt-get upgrade -y
    apt install apache2 php libapache2-mod-php php-mysql -y
    apt install wget php php-cgi php-mysqli php-pear php-mbstring libapache2-mod-php php-common php-phpseclib php-mysql -y
}


function install-nginx () {
    apt-get update && apt-get upgrade -y
    apt install nginx php php-mysql -y
    apt install php-curl php-gd php-intl php-json php-mbstring php-xml php-zip -y
    apt install wget php php-cgi php-mysqli php-pear php-mbstring libapache2-mod-php php-common php-phpseclib php-mysql -y

}



function install-maria () {
    apt install mariadb-server -y
    echo "---------------------------------------------"
    echo "Welcome in the Confiruation Panel for mariadb"
    ehco "---------------------------------------------"
    read -p "port utiliser [3306]" port_maria
    read -p -s "password for root [password]" password

    echo "---------------------------------------------"
    echo "Recap :"
    echo "port number :" $port_maria
    echo "password :" $password
    echo "---------------------------------------------"
    echo "Verification du fichier source du serveur :"
    read -p "$maria_sources est correct ?" confirmation2
    if [[ "$confirmation2" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]; then
        old_line="port            = 3306"
        new_line="port            = 3306"$port_maria
        sed -i "s/$old_line/$new_line/" "$maria_source"
        mysqladmin -u root -p password \'$password\'
    else
        read -p "Where are the config files ?" maria_sources
        install-maria

    fi
}
function install-mysql () {
    apt install mysql-server -y
}





function install () {
    if [[ "${sgdb}" == "mariadb" && "${web}" == "apache" ]]; then
        echo "your are using maria db"
        install-apache
        install-maria 

    elif [[ "${sgdb}" == "mysql" && "${web}" == "apache" ]]; then
        install-apache
        install-mysql

    elif [[ "${sgdb}" == "mysql" && "${web}" == "nginx" ]]; then
        install-nginx
        install-mysql
    
    elif [[ "${sgdb}" == "mariadb" && "${web}" == "nginx" ]]; then
        install-nginx
        install-maria
    else
        echo "Wrong sgdb or web-server"
    fi
}





read -r -p "All informations are True [y/n] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])$ ]]
then
    
    install

else
    echo "Try Again"
    exit 2
fi

