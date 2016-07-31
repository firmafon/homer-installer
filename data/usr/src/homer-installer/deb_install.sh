#!/bin/bash
#
# --------------------------------------------------------------------------------
# HOMER/SipCapture automated installation script for Debian/CentOs/OpenSUSE (BETA)
# --------------------------------------------------------------------------------
# This script is only intended as a quickstart to test and get familiar with HOMER.
# It is not suitable for high-traffic nodes, complex capture scenarios, clusters.
# The HOW-TO should be ALWAYS followed for a fully controlled, manual installation!
# --------------------------------------------------------------------------------
#
#  Copyright notice:
#
#  (c) 2011-2016 Lorenzo Mangani <lorenzo.mangani@gmail.com>
#  (c) 2011-2016 Alexandr Dubovikov <alexandr.dubovikov@gmail.com>
#
#  All rights reserved
#
#  This script is part of the HOMER project (http://sipcapture.org)
#  The HOMER project is free software; you can redistribute it and/or 
#  modify it under the terms of the GNU Affero General Public License as 
#  published by the Free Software Foundation; either version 3 of 
#  the License, or (at your option) any later version.
#
#  You should have received a copy of the GNU Affero General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
#  This script is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Affero General Public License for more details.
#
#  This copyright notice MUST APPEAR in all copies of the script!
#

#####################################################################
#                                                                   #
#  WARNING: THIS SCRIPT IS NOW UPDATED TO SUPPORT HOMER 5.x         #
#           PLEASE USE WITH CAUTION AND HELP US BY REPORTING BUGS!  #
#                                                                   #
#####################################################################

# HOMER Options, defaults
DB_USER=homer_user
DB_PASS=homer_password
DB_HOST="127.0.0.1"
LISTEN_PORT=9060
LOCAL_IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p')

# HOMER MySQL Options, defaults
sqluser=root
sqlpassword=

#### NO CHANGES BELOW THIS LINE! 

VERSION=5.0.0
HOSTNAME=$(hostname)

logfile=/tmp/homer_installer.log

# LOG INSTALLER OUTPUT TO $logfile
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
rm ${logfile}.pipe

#clear; 
echo "**************************************************************"
echo "                                                              "
echo "      ,;;;;;,       HOMER SIP CAPTURE (http://sipcapture.org) "
echo "     ;;;;;;;;;.     Single-Node Auto-Installer (beta $VERSION)"
echo "   ;;;;;;;;;;;;;                                              "
echo "  ;;;;  ;;;  ;;;;   <--------------- INVITE ---------------   "
echo "  ;;;;  ;;;  ;;;;    --------------- 200 OK --------------->  "
echo "  ;;;;  ...  ;;;;                                             " 
echo "  ;;;;       ;;;;   WARNING: This installer is intended for   "
echo "  ;;;;  ;;;  ;;;;   dedicated/vanilla OS setups without any   "
echo "  ,;;;  ;;;  ;;;;   customization and with default settings   "
echo "   ;;;;;;;;;;;;;                                              "
echo "    :;;;;;;;;;;     THIS SCRIPT IS PROVIDED AS-IS, USE AT     "
echo "     ^;;;;;;;^      YOUR *OWN* RISK, REVIEW LICENSE & DOCS    "
echo "                                                              "
echo "**************************************************************"
echo;


# Check if we're good on permissions
if  [ "$(id -u)" != "0" ]; then
  echo "ERROR: You must be a root user. Exiting..." 2>&1
  echo  2>&1
  exit 1
fi

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

echo "OS: Dectecting System...."
# Identify Linux Flavour
if [ -f /etc/debian_version ] ; then
    DIST="DEBIAN"
    echo "OS: DEBIAN detected"
else
    echo "ERROR:"
    echo "Sorry, this Installer supports Debian flavoures systems only!"
    echo "Please follow instructions in the HOW-TO for manual installation & setup"
    echo "available at http://sipcapture.org"
    echo
    exit 1
fi

# Setup Kamailio/Sipcapture from Packages
echo
echo "**************************************************************"
echo " INSTALLING OS PACKAGES AND DEPENDENCIES FOR HOMER SIPCAPTURE"
echo "**************************************************************"
echo
echo "This might take a while depending on system/network speed. Please stand by...."
echo

case $DIST in
    'DEBIAN')
     WEBROOT="/var/www/html/"
     WEBSERV="apache2"
     MYSQL="mysql"
    # General
    export DEBIAN_FRONTEND=noninteractive
    export LANG=en_US.utf8
    export LC_ALL="en_US.UTF-8"
    locale-gen "en_US.UTF-8" && dpkg-reconfigure locales
    # apt-get update -qq
    # apt-get install --no-install-recommends --no-install-suggests -yqq ca-certificates apache2 libapache2-mod-php5 php5 php5-cli php5-gd php-pear php5-dev php5-mysql php5-json php-services-json git wget pwgen
    #enable apache mod_php and mod_rewrite
    a2enmod php5
    a2enmod rewrite 
          # Generate Certificates if not present
          if [ ! -f "/etc/ssl/localcerts/apache.key" ]; then
            mkdir -p /etc/ssl/localcerts
            openssl req -new -x509 -days 365 -nodes -out /etc/ssl/localcerts/apache.pem -keyout /etc/ssl/localcerts/apache.key
            chmod 600 /etc/ssl/localcerts/apache*
          fi
          # activate ssl
          a2enmod ssl


    # MySQL
    # apt-get install -y perl libdbi-perl libclass-dbi-mysql-perl --no-install-recommends
    # apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5
    # echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-5.7" > /etc/apt/sources.list.d/mysql.list
    # apt-get update && apt-get install -y mysql-server-5.7 libmysqlclient18
    # Kamailio + sipcapture module
    # apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xfb40d3e6508ea4c8
    # echo "deb http://deb.kamailio.org/kamailio44 jessie main" >> /etc/apt/sources.list
    # echo "deb-src http://deb.kamailio.org/kamailio44 jessie main" >> /etc/apt/sources.list
    # apt-get update && apt-get install -f -yqq kamailio rsyslog kamailio-outbound-modules kamailio-geoip-modules kamailio-sctp-modules kamailio-tls-modules kamailio-websocket-modules kamailio-utils-modules kamailio-mysql-modules kamailio-extra-modules geoip-database geoip-database-extra


    cd /usr/src/
    if [ ! -d "/usr/src/homer-api" ]; then
       echo "GIT: Cloning Homer components..."
        git clone --depth 1 https://github.com/sipcapture/homer-api.git homer-api
      git clone --depth 1 https://github.com/sipcapture/homer-ui.git homer-ui
      git clone --depth 1 https://github.com/QXIP/homer-docker.git homer-docker
      chmod +x /usr/src/homer-api/scripts/*
      cp /usr/src/homer-api/scripts/* /opt/
    else
      echo "GIT: Updating Homer components..."
        cd homer-api; git pull; cd ..
        cd homer-ui; git pull; cd ..
        cd homer-docker; git pull; cd ..
    fi
    
      cp -R /usr/src/homer-ui/* $WEBROOT/
      cp -R /usr/src/homer-api/api $WEBROOT/
      chown -R www-data:www-data $WEBROOT/store/
      chmod -R 0775 $WEBROOT/store/dashboard
    
      SQL_LOCATION=/usr/src/homer-api/sql

      cp /usr/src/homer-docker/data/configuration.php $WEBROOT/api/configuration.php
      cp /usr/src/homer-docker/data/preferences.php $WEBROOT/api/preferences.php
      cp /usr/src/homer-docker/data/vhost.conf /etc/apache2/sites-enabled/000-default.conf
    
      cp /usr/src/homer-docker/data/kamailio.cfg /etc/kamailio/kamailio.cfg
      chmod 775 /etc/kamailio/kamailio.cfg
    
      (crontab -l ; echo "30 3 * * * /opt/homer_rotate >> /var/log/cron.log 2>&1") | sort - | uniq - | crontab -
  


    # Handy-dandy MySQL run function
    function MYSQL_RUN () {

      echo 'Starting mysqld'
      /etc/init.d/mysql start
      #echo 'Waiting for mysqld to come online'
      while [ ! -x /var/run/mysqld/mysqld.sock ]; do
          sleep 1
      done

    }

    # MySQL data loading function
    function MYSQL_INITIAL_DATA_LOAD () {

      if [ "$DEBIAN_FRONTEND" != "noninteractive" ] 
      then
        echo "Please provide your MySQL $sqluser password to proceed (empty for no password)"
        stty -echo
        read sqlpassword

        echo "Using default username..."
        sqlhomeruser="homer"
        DB_USER="$sqlhomeruser"
        echo "Using random password... "
        sqlhomerpassword=$(cat /dev/urandom|tr -dc "a-zA-Z0-9"|fold -w 9|head -n 1)
        DB_PASS="$sqlhomerpassword"
      fi

      DATADIR=/var/lib/mysql

      echo "Beginning initial data load...."

      #chown -R mysql:mysql "$DATADIR"
      #mysql_install_db --user=mysql --datadir="$DATADIR"

      MYSQL_RUN
      pwdstr="" && [[ "$sqlpassword" != "" ]] && pwdstr="-p $sqlpassword"
      mysql -u "$sqluser" $pwdstr -e "GRANT ALL ON *.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; FLUSH PRIVILEGES;";

      echo "Creating Databases..."
      mysql -u "$DB_USER" -p"$DB_PASS" < $SQL_LOCATION/homer_databases.sql
      #mysql -u "$DB_USER" -p"$DB_PASS" < $SQL_LOCATION/homer_user.sql
      
      echo "Creating Tables..."
      mysql -u "$DB_USER" -p"$DB_PASS" homer_data < $SQL_LOCATION/schema_data.sql
      mysql -u "$DB_USER" -p"$DB_PASS" homer_configuration < $SQL_LOCATION/schema_configuration.sql
      mysql -u "$DB_USER" -p"$DB_PASS" homer_statistic < $SQL_LOCATION/schema_statistic.sql
      
      # echo "Creating local DB Node..."
      mysql -u "$DB_USER" -p"$DB_PASS" homer_configuration -e "INSERT INTO node VALUES(1,'mysql','homer_data','3306','"$DB_USER"','"$DB_PASS"','sip_capture','node1', 1);"
      

      echo "Homer initial data load complete" > $DATADIR/.homer_initialized

    }

    # Initialize Database
    MYSQL_INITIAL_DATA_LOAD

    # HOMER API CONFIG
    echo "Patching Homer configuration..."
    PATH_HOMER_CONFIG=$WEBROOT/api/configuration.php
    chmod 775 $PATH_HOMER_CONFIG

    # Patch rotation script auth
    if [ "$DEBIAN_FRONTEND" != "noninteractive" ] 
    then
      perl -p -i -e "s/homer_user/$DB_USER/" /opt/rotation.ini
      perl -p -i -e "s/homer_password/$DB_PASS/" /opt/rotation.ini
    fi

    # Replace values in template
    perl -p -i -e "s/\{\{ DB_PASS \}\}/$DB_PASS/" $PATH_HOMER_CONFIG
    perl -p -i -e "s/\{\{ DB_HOST \}\}/$DB_HOST/" $PATH_HOMER_CONFIG
    perl -p -i -e "s/\{\{ DB_USER \}\}/$DB_USER/" $PATH_HOMER_CONFIG

    # Set Permissions for webapp
    mkdir $WEBROOT/api/tmp
    chmod -R 0777 $WEBROOT/api/tmp/
    chmod -R 0775 $WEBROOT/store/dashboard*

    # Reconfigure SQL rotation
    export PATH_ROTATION_SCRIPT=/opt/homer_rotate
    chmod 775 $PATH_ROTATION_SCRIPT

    # Init rotation
    /opt/homer_rotate > /dev/null 2>&1

    # KAMAILIO
    export PATH_KAMAILIO_CFG=/etc/kamailio/kamailio.cfg
    cp /usr/src/homer-docker/data/kamailio.cfg $PATH_KAMAILIO_CFG

    awk '/max_while_loops=100/{print $0 RS "mpath=\"//usr/lib/x86_64-linux-gnu/kamailio/modules/\"";next}1' $PATH_KAMAILIO_CFG >> $PATH_KAMAILIO_CFG.tmp | 2&>1 >/dev/null
    mv $PATH_KAMAILIO_CFG.tmp $PATH_KAMAILIO_CFG

    # Replace values in template
    perl -p -i -e "s/\{\{ LISTEN_PORT \}\}/$LISTEN_PORT/" $PATH_KAMAILIO_CFG
    perl -p -i -e "s/\{\{ DB_PASS \}\}/$DB_PASS/" $PATH_KAMAILIO_CFG
    perl -p -i -e "s/\{\{ DB_HOST \}\}/$DB_HOST/" $PATH_KAMAILIO_CFG
    perl -p -i -e "s/\{\{ DB_USER \}\}/$DB_USER/" $PATH_KAMAILIO_CFG

    sed -i -e "s/#RUN_KAMAILIO/RUN_KAMAILIO/g" /etc/default/kamailio
    sed -i -e "s/#CFGFILE/CFGFILE/g" /etc/default/kamailio
    sed -i -e "s/#USER/USER/g" /etc/default/kamailio
    sed -i -e "s/#GROUP/GROUP/g" /etc/default/kamailio

    # Test the syntax.
    # kamailio -c $PATH_KAMAILIO_CFG

    # Start Apache
    # apachectl -DFOREGROUND
    update-rc.d apache2 enable
    /etc/init.d/apache2 restart

    # It's Homer time!
    update-rc.d kamailio enable
    /etc/init.d/kamailio restart

    ;;

esac


# Install Complete
#clear
echo "*************************************************************"
echo "      ,;;;;,                                                 "
echo "     ;;;;;;;;.     Congratulations! HOMER has been installed!"
echo "   ;;;;;;;;;;;;                                              "
echo "  ;;;;  ;;  ;;;;   <--------------- INVITE ---------------   "
echo "  ;;;;  ;;  ;;;;    --------------- 200 OK --------------->  "
echo "  ;;;;  ..  ;;;;                                             " 
echo "  ;;;;      ;;;;   Your system should be now ready to rock!"
echo "  ;;;;  ;;  ;;;;   Please verify/complete the configuration  "
echo "  ,;;;  ;;  ;;;;   files generated by the installer below.   "
echo "   ;;;;;;;;;;;;                                              "
echo "    :;;;;;;;;;     THIS SCRIPT IS PROVIDED AS-IS, USE AT     "
echo "     ;;;;;;;;      YOUR *OWN* RISK, REVIEW LICENSE & DOCS    "
echo "                                                             "
echo "*************************************************************"
echo
echo "     * Verify configuration for HOMER-API:"
echo "         '$WEBROOT/api/configuration.php'"
echo "         '$WEBROOT/a[o/preferences.php'"
echo
echo "     * Verify capture settings for Homer/Kamailio:"
echo "         '$REAL_PATH/etc/kamailio/kamailio.cfg'"
echo
echo "     * Start/stop Homer SIP Capture:"
echo "         '$REAL_PATH/sbin/kamctl start|stop'"
echo
echo "     * Access HOMER UI:"
echo "         http://$LOCAL_IP or http://$LOCAL_IP"
echo "         [default login: admin/test1234]"
echo
echo "     * Send HEP/EEP Encapsulated Packets:"
echo "         hep://$LOCAL_IP:$LISTEN_PORT"
echo
echo "**************************************************************"
echo
echo " IMPORTANT: Do not forget to send Homer node some traffic! ;) "
echo " For our capture agents, visit http://github.com/sipcapture "
echo " For more help and information visit: http://sipcapture.org "
echo
echo "**************************************************************"
echo " Installer Log saved to: $logfile "
echo 
exit 0