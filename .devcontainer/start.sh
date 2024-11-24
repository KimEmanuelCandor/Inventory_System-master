#! /bin/bash

# Starts the Apache server
# This is necessary to access the site from the browser
sudo apache2ctl start

.devcontainer/wait-for-it.sh 127.0.0.1:3306 --timeout=120 -- echo "MySQL is up!"
sleep 10
mysql -h 127.0.0.1 -u root --password=root -e "SET @@global.sql_mode='NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';"
