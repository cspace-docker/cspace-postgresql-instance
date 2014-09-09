#!/usr/bin/env bash

# Perform one-time initialization of a PostgreSQL database cluster
# for use with CollectionSpace

# See http://stackoverflow.com/a/1379904
# and the earliest posted comment on
# http://unix.stackexchange.com/a/90995

# Uncomment for debugging.
set -x

# Halt execution when the first non-success exit code is encountered.
set -e

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
echo "Checking for existence of a PostgreSQL database cluster ..."
PG_CLUSTER_PATH="/var/lib/postgresql/$PG_MAJOR/$PG_CLUSTER_NAME"
if test "$(ls -A $PG_CLUSTER_PATH 2>/dev/null)";
  then
    echo "Existing PostgreSQL database cluster found at $PG_CLUSTER_PATH ..."
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
fi

#
# Start the PostgreSQL server.
#
echo "Starting the PostgreSQL server ..."
pg_ctlcluster $PG_MAJOR $PG_CLUSTER_NAME start \
   || (c=$?; echo "Could not start PostgreSQL server"; $(exit $c))

#
# Create a PostgreSQL role (user account) for the CollectionSpace
# database administrator user, if that role doesn't already exist.
#
# See http://stackoverflow.com/questions/8546759/how-to-check-if-a-postgres-user-exists
#
# TODO: Replace the SUPERUSER-enabled role below with only a subset of
# superuser privileges.
#
# TODO: Create a database with a name identical to this role.
#
echo "Checking for required username/password in environment variables ..."
[ -z "$DB_CSPACE_ADMIN_NAME" ] && echo "Script requires a DB_CSPACE_ADMIN_NAME environment variable" && exit 1;
[ -z "$DB_CSPACE_ADMIN_PASSWORD" ] && echo "Script requires a DB_CSPACE_ADMIN_PASSWORD environment variable" && exit 1;

echo "Creating CollectionSpace database admin user, if not already present ..."
sudo -u postgres -s psql --tuples-only --no-align --command "SELECT 1 FROM pg_roles WHERE rolname='$DB_CSPACE_ADMIN_NAME'" | grep -q 1 || \
  sudo -u postgres -s psql --command \
    "CREATE USER $DB_CSPACE_ADMIN_NAME WITH SUPERUSER PASSWORD '$DB_CSPACE_ADMIN_PASSWORD';"



