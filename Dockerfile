#
# Example Dockerfile written by Sven Dowideit of Docker Inc.
# and included as part of the documentation at
# http://docs.docker.com/examples/postgresql_service/
#
# Slightly adapted for a minimal, up-and-running PostgreSQL
# Docker instance for a demonstration of CollectionSpace
# running on multiple Docker containers.
#

#
# ***
# IMPORTANT: the default configuration below sets up this
# PostgreSQL server for global access, in pg_hba.conf,
# and with a known hard-coded username and password for
# a database superuser.
#
# This Dockerfile MUST be revised to remove those security
# vulnerabilities, for anything other than transient, demo
# or evaluation use of this container. At the very least,
# the pg_hba.conf file should permit remote access only
# from the IP address of a particular CollectionSpace host,
# and the database superuser name and password should be changed.
# ***
#

FROM ubuntu:14.04
MAINTAINER SvenDowideit@docker.com
#
# Note: effects resulting from any deltas from the example
# posted by Sven Dowideit are solely the responsiblity of
# the CollectionSpace community, and not Sven or Docker Inc.
#

#
# TODO: Reference this value more widely below,
# replacing multiple instances of hard-coded values.
#
ENV PG_VERSION 9.3

#
# IMPORTANT: Hard-coded values (see security warning above)
# that will be published publicly in GitHub:
#
ENV DB_SUPERUSER_NAME u82255c6_5BBa
ENV DB_SUPERUSER_PASSWORD p52i39#Cs$%5R5b

#
# CollectionSpace requires a UTF-8 character encoding.
#
# The default locale is for US English; be sure to change
# the locale's language and/or country/region as needed:
#
ENV CHAR_ENCODING en_US.UTF-8

#
# Generate locale data files for the specified character encoding
#
RUN locale-gen $CHAR_ENCODING

#
# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
#
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

#
# Add PostgreSQL's repository. It contains the most recent stable release
# of PostgreSQL, ``9.3``.
#
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

#
# Update the Ubuntu and PostgreSQL repository indexes
#
RUN apt-get update

#
# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL 9.3
# There are some warnings (in red) that show up during the build. You can hide
# them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
#
RUN apt-get -y -q install python-software-properties software-properties-common
RUN apt-get -y -q install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

#
# Drop and re-create the cluster, to change the character encoding
# for its default set of databases from USASCII to the UTF-8-based
# encoding specified above.
#
# Note: The official Debian and Ubuntu images automatically perform
# an ``apt-get clean`` after each ``apt-get``
#
# TODO: Verify this step is still needed when running under Ubuntu 14.04
#
RUN pg_dropcluster $PG_VERSION main && pg_createcluster --locale $CHAR_ENCODING $PG_VERSION main

#
# Run the rest of the commands as the ``postgres`` user created by
# the ``postgres-9.3`` package when it was ``apt-get installed``
#
USER postgres

#
# Create a PostgreSQL role for the CollectionSpace administrative user.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
# allows the RUN command to span multiple lines.
#
RUN /etc/init.d/postgresql start && \
   psql --command "CREATE USER $DB_SUPERUSER_NAME WITH SUPERUSER PASSWORD '$DB_SUPERUSER_PASSWORD';" 

#
# Adjust the PostgreSQL host-based access configuration to enable
# remote connections to the database.
#
# IMPORTANT: As noted above, this configuration makes the database
# world-accessible (within whatever access limitations might
# externally be imposed by Docker and/or the Docker host).
#
# TODO: Replace this configuration with the recommended configuration
# for CollectionSpace PostgreSQL servers.
#
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.3/main/pg_hba.conf

#
# And add ``listen_addresses`` to ``/etc/postgresql/9.3/main/postgresql.conf``
#
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.3/main/postgresql.conf

#
# Expose the PostgreSQL port from the container
#
EXPOSE 5432

#
# Add VOLUMEs to allow persistance and backup of configuration, logs,
# and databases
#
VOLUME ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

#
# Set the default command to run when starting the container.
#
# TODO: Specify the data directory and configuration file paths
# via ENV values 
#
CMD ["/usr/lib/postgresql/9.3/bin/postgres", "-D", "/var/lib/postgresql/9.3/main", "-c", "config_file=/etc/postgresql/9.3/main/postgresql.conf"]
