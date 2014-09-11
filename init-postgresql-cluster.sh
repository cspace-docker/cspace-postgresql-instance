#!/usr/bin/env bash

#
# Startup script for the PostgreSQL Server
# Docker container for CollectionSpace
#

#
# This script has two functions:
#
# 1. If a PostgreSQL database cluster for
# CollectionSpace is not present, perform
# a one-time initialization of that cluster.
#
# 2. Start the PostgreSQL server.
#

# See http://stackoverflow.com/a/1379904
# and the earliest posted comment on
# http://unix.stackexchange.com/a/90995

# Uncomment for debugging.
set -x

# Halt execution when the first non-success exit code is encountered.
set -e

start_postgresql_server()
{
  #
  # Start the PostgreSQL server.
  #
  echo "Starting the PostgreSQL server ..."
  pg_ctlcluster $PG_MAJOR $PG_CLUSTER_NAME start \
     || (c=$?; echo "Could not start PostgreSQL server"; $(exit $c))
}

#
# Verify that this script is being run as 'root'
#
echo "Verifying that script is being run as root ..."
if [ "$EUID" -ne 0 ];
  then
     echo "This script must be run as the 'root' user (e.g. via 'sudo')"
     exit 1;
fi

#
# Verify that necessary environment variables have been set.
#
echo "Checking for required PostgreSQL version in environment variable ..."
[ -z "$PG_MAJOR" ] && echo "Script requires a PG_MAJOR environment variable with non-blank value" && exit 1;

echo "Checking for required PostgreSQL clustername in environment variable ..."
[ -z "PG_CLUSTER_NAME" ] && echo "Script requires a PG_CLUSTER_NAME environment variable with non-blank value" && exit 1;

#
# Initialize the PostgreSQL database cluster, if and only if
# it hasn't already been initialized in the specified location;
# i.e. if there isn't already a (non-empty) database cluster
# directory present in that location.
#
# Then start the PostgreSQL server.
#
echo "Checking for existence of a PostgreSQL database cluster ..."
PG_CLUSTER_PATH="/var/lib/postgresql/$PG_MAJOR/$PG_CLUSTER_NAME"
if test "$(ls -A $PG_CLUSTER_PATH 2>/dev/null)";
  then
    
    echo "Existing PostgreSQL database cluster found at $PG_CLUSTER_PATH ..."
    start_postgresql_server
    
  else
    
    echo "Initializing the PostgreSQL database cluster at $PG_CLUSTER_PATH ..."
    command -v pg_createcluster || (c=$?; echo "Could not find 'pg_createcluster' command"; $(exit $c))
    pg_createcluster $PG_MAJOR $PG_CLUSTER_NAME || (c=$?; echo "Could not initialize PostgreSQL database cluster"; $(exit $c))
 
    #
    # Adjust the PostgreSQL host-based access configuration to enable
    # remote connections to the database.
    #
    # IMPORTANT: This configuration makes the database
    # world-accessible (within whatever access limitations might
    # externally be imposed by Docker and/or the Docker host).
    #
    # TODO: Replace this permissive configuration with a more
    # secure, recommended configuration for CollectionSpace 
    # PostgreSQL servers.
    #
    # TODO: This is a primitive way of setting configuration.
    # Consider using Augeas, 'sed', etc.
    #
    PG_CONFIG_PATH="/etc/postgresql/$PG_MAJOR/$PG_CLUSTER_NAME"
    echo "host all  all    0.0.0.0/0  md5" >> $PG_CONFIG_PATH/pg_hba.conf
    
    #
    # Adjust PostgreSQL's configuration to allow for incoming
    # connections from all addresses
    #
    # TODO: Replace this permissive configuration with a more
    # secure, recommended configuration for CollectionSpace 
    # PostgreSQL servers.
    #
    # TODO: This is a primitive way of setting configuration.
    # Consider using Augeas, 'sed', etc.
    #
    echo "listen_addresses='*'" >> $PG_CONFIG_PATH/postgresql.conf
    
    #
    # Start the PostgreSQL server.
    #
    start_postgresql_server
    
    #
    # Create a PostgreSQL role (user account) for the CollectionSpace
    # database administrator user.
    #
    # TODO: Replace the SUPERUSER-enabled role below with only a subset of
    # superuser privileges.
    #
    # TODO: Create a database with a name identical to this role.
    #
    echo "Checking for required username/password in environment variables ..."
    [ -z "$DB_CSPACE_ADMIN_NAME" ] && echo "Script requires a DB_CSPACE_ADMIN_NAME environment variable" && exit 1;
    [ -z "$DB_CSPACE_ADMIN_PASSWORD" ] && echo "Script requires a DB_CSPACE_ADMIN_PASSWORD environment variable" && exit 1;
    
    #
    # TODO (optional): Verify that the role to be created doesn't yet exist.
    # Placeholder code to do this - not working - appears below.
    #
    # See http://stackoverflow.com/questions/8546759/how-to-check-if-a-postgres-user-exists
    #
    # CSADMIN_TMPFILE=/tmp/csadmin-exists
    # sudo -u postgres -s psql --tuples-only --no-align \
    #   --command "SELECT 1 FROM pg_roles WHERE rolname='$DB_CSPACE_ADMIN_NAME'" > $CSADMIN_TMPFILE
    # if [ -z $(cat $CSADMIN_TMPFILE) ];
    #   then
    # fi
 
    echo "Creating CollectionSpace database admin user, if not already present ..."
    sudo -u postgres -s psql --command \
       "CREATE USER $DB_CSPACE_ADMIN_NAME WITH SUPERUSER PASSWORD '$DB_CSPACE_ADMIN_PASSWORD';"   
    
fi

# Keep this shell script running even after the PostgreSQL
# server has been started, to ensure that the Docker
# container doesn't quit on script exit.
#
# See http://stackoverflow.com/questions/9052847/implementing-infinite-wait-in-shell-scripting
#

#
# Make a named pipe.
#
mkfifo /tmp/mypipe
#
# Loop until an exit signal is received.
#
while read SIGNAL; do
    case "$SIGNAL" in
        # Handles all exit signals, including SIGTERM
        *EXIT*) break;;
        *) echo "signal $SIGNAL is unsupported" >/dev/stderr;;
    esac
done < /tmp/mypipe


