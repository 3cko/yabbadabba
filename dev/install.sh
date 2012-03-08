#!/bin/bash

locale="en_US.UTF-8"
timeZone="America/Los_Angeles"
dbPasswd="fubar"

os_select()
{
    if [ "$(cat /etc/lsb-release |grep natty)" == "DISTRIB_CODENAME=natty" ]; then
        echo -n "Installing NginX, PHP and MariaDB for Ubuntu 11.04, Natty Narwhal..."
    else
        echo -n "Your (ve) Server OS is not supported with this install!"
        echo -n "Exiting."
        exit
    fi
}

set_locale()
{
    echo -n "Setting system locale to: $locale..."
    {
        locale-gen $locale
        unset LANG
        /usr/sbin/update-locale LANG=$locale
    } > /dev/null 2>&1
    export LANG=$locale
    sleep 1
    echo "done."
}

set_timezone()
{
    echo -n "Setting timezone to: $timeZone..."
    echo $timeZone > /etc/timezone
    dpkg-reconfigure -f noninteractive tzdata > /dev/null 2>&1
    sleep 2
    echo "done."
}

create_logs()
{
    echo -n "Creating log paths..."
    mkdir ./logs
    touch ./logs/repos.log ./logs/apt-install.log
    sleep 3
    echo "done."
}

add_repos()
{
    echo -n "Adding Repositories..."
    apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 1BB943DB >> ./logs/repos.log 2>&1
    echo "deb http://mirrors.xmission.com/mariadb/repo/5.2/ubuntu maverick main
deb-src http://mirrors.xmission.com/mariadb/repo/5.2/ubuntu maverick main" > /etc/apt/sources.list.d/mariadb.list
    add-apt-repository ppa:nginx/stable >> ./logs/repos.log 2>&1
    sleep 3
    echo "done."
}

repo_update()
{
    echo -n "Updating Repositories..."
    aptitude update >> ./logs/repos.log
    sleep 3
    echo "done."
}

install_base()
{
    echo -n "Installing base packages..."
    aptitude -y safe-upgrade >> ./logs/install.log 2>&1
    aptitude -y full-upgrade >> ./logs/install.log 2>&1
    aptitude -y install curl build-essential python-software-properties git-core htop >> ./logs/install.log 2>&1
    sleep 3
    echo "done."
}

install_nginx()
{
    echo -n "Installing NginX package..."
    aptitude -y nginx nginx-doc >> ./logs/install.log 2>&1
    sleep 3
    echo "done."
}

install_mariadb()
{
    echo -n "Installing MariaDB packages..."
    echo "mysql-server mysql-server/root_password select $dbPasswd" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again select $dbPasswd" | debconf-set-selections
    aptitude -y install mariadb-server mariadb-client >> ./logs/install.log 2>&1
    echo "done."
}

install_php()
{
    echo -n "Installing PHP packages..."
    aptitude -y install php5-cli php5-common php5-suhosin php5-gd php5-mysql php5-curl >> ./logs/install.log 2>&1
    aptitide -y install php5-fpm php5-cgi php-apc php5-dev libpcre3-dev >> ./logs/install.log 2>&1
    echo "done."
}

restart_services()
{
    echo "Restarting all services..."
    service nginx stop
    service nginx start
    service php5-fpm stop
    service php5-fpm start
    service mysqld stop
    service mysqld start
    echo "All services have been restarted."
    exit
}

os_select

set_locale

set_timezone

create_logs

add_repos

repo_update

install_base

install_nginx

install_mariadb

install_php

restart_services
