#!/bin/bash

set -m
set -e

VOLUME_HOME="/data/mysql"
CONF_FILE="/etc/my.cnf"
LOG="/var/log/mysqld.log"

# Set permission of config file
chmod 644 ${CONF_FILE}

StartMySQL ()
{
    /usr/bin/mysqld_safe ${EXTRA_OPTS} > /dev/null 2>&1 &
    # Time out in 1 minute
    LOOP_LIMIT=60
    for (( i=0 ; ; i++ )); do
        if [ ${i} -eq ${LOOP_LIMIT} ]; then
            echo "Time out. Error log is shown as below:"
            tail -n 100 ${LOG}
            exit 1
        fi
        echo "=> Waiting for confirmation of MySQL service startup, trying ${i}/${LOOP_LIMIT} ..."
        sleep 1
        mysql -uroot -e "status" > /dev/null 2>&1 && break
    done
}

CreateMySQLUser()
{
    if [ "$MYSQL_PASS" = "**Random**" ]; then
        unset MYSQL_PASS
    fi

    PASS=${MYSQL_PASS:-$(pwgen -s 12 1)}
    _word=$( [ ${MYSQL_PASS} ] && echo "preset" || echo "random" )
    echo "=> Creating MySQL user ${MYSQL_USER} with ${_word} password"

    mysql -uroot -e "CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '$PASS'"
    mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION"
    echo "=> Done!"
    echo "========================================================================"
    echo "You can now connect to this MySQL Server using:"
    echo ""
    echo "    mysql -u$MYSQL_USER -p$PASS -h<host> -P<port>"
    echo ""
    echo "Please remember to change the above password as soon as possible!"
    echo "MySQL user 'root' has no password but only allows local connections"
    echo "========================================================================"
}

OnCreateDB()
{
    if [ "$ON_CREATE_DB" = "**False**" ]; then
        unset ON_CREATE_DB
    else
        echo "Creating MySQL database ${ON_CREATE_DB}"
        mysql -uroot -e "CREATE DATABASE IF NOT EXISTS ${ON_CREATE_DB};"
        echo "Database created!"
    fi
}

ImportSql()
{
    for FILE in ${STARTUP_SQL}; do
        echo "=> Importing SQL file ${FILE}"
        if [ "$ON_CREATE_DB" ]; then
            mysql -uroot "$ON_CREATE_DB" < "${FILE}"
        else
            mysql -uroot < "${FILE}"
        fi
    done
}

# Main

# Initialize empty data volume and create MySQL user
if [[ ! -d $VOLUME_HOME/mysql ]]; then
    echo "=> An empty or uninitialized MySQL volume is detected in $VOLUME_HOME"
    echo "=> Installing MySQL ..."
    mysql_install_db || exit 1
    chown mysql:mysql $VOLUME_HOME/* -R
    touch $VOLUME_HOME/.EMPTY_DB
    echo "=> Done!"
else
    echo "=> Using an existing volume of MySQL"
fi


echo "=> Starting MySQL ..."
StartMySQL
tail -F $LOG &

# Create admin user and pre create database
if [ -f $VOLUME_HOME/.EMPTY_DB ]; then
    echo "=> Creating admin user ..."
    CreateMySQLUser
    OnCreateDB
    rm $VOLUME_HOME/.EMPTY_DB
fi


# Import Startup SQL
if [ -n "${STARTUP_SQL}" ]; then
    if [ ! -f /sql_imported ]; then
        echo "=> Initializing DB with ${STARTUP_SQL}"
        ImportSql
        touch /sql_imported
    fi
fi


fg
