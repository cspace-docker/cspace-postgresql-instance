#!/usr/bin/env bash

# Perform one-time initialization of a PostgreSQL database cluster
# for use with CollectionSpace

# See http://stackoverflow.com/a/1379904
# and the earliest posted comment on http://unix.stackexchange.com/a/90995

set -e

#
# Verify that script is being run as 'root'
#

# TODO: Add necessary code here

#
# Initialize the PostgreSQL database cluster, if and only if
# it hasn't already been initialized.
#

# TODO: Add cluster initialization command here

#
# Start the PostgreSQL server
#
sudo -u postgres /etc/init.d/postgresql start || c=$?; echo "Failed to start PostgreSQL server"; $(exit $c)

#
# Create a PostgreSQL role for the CollectionSpace administrative user.
#
# See http://stackoverflow.com/questions/8546759/how-to-check-if-a-postgres-user-exists
#
psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='$DB_SUPERUSER_NAME'" | grep -q 1 ||
# Or use 'createuser' here ...
sudo -u postgres psql --command "CREATE USER $DB_SUPERUSER_NAME WITH SUPERUSER PASSWORD '$DB_SUPERUSER_PASSWORD';"

#
# Adjust the PostgreSQL host-based access configuration to enable
# remote connections to the database.
#
# IMPORTANT: This configuration makes the database
# world-accessible (within whatever access limitations might
# externally be imposed by Docker and/or the Docker host).
#
# TODO: Replace this permissive configuration with the recommended
# configuration for CollectionSpace PostgreSQL servers.
#
echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

#
# Listen for incoming connections from all addresses
#
# TODO: Replace this permissive configuration with the recommended
# configuration for CollectionSpace PostgreSQL servers.
#
echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

