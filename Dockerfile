#
# Based on an example Dockerfile written by Sven Dowideit
# of Docker Inc. and included as part of the documentation at
# http://docs.docker.com/examples/postgresql_service/
#
# Adapted for a minimal, up-and-running PostgreSQL
# Docker instance for a demonstration of CollectionSpace
# running on multiple Docker containers.
#

#
# ***************************************************************
# IMPORTANT: the default configuration below, and in an
# an auxiliary shell script called by this Dockerfile, sets
# up this PostgreSQL server for global access, and with a
# known hard-coded username and password for a database
# administrator user.
#
# This Dockerfile MUST be revised to remove those security
# vulnerabilities, for anything other than transient, demo
# or evaluation use of this container. For instance, the
# pg_hba.conf file should permit remote access only from
# the IP address of a particular CollectionSpace host, and
# the database administrator name and password should be changed.
# ***************************************************************
#

FROM ubuntu:14.04

# Set the desired major version of PostgreSQL to be installed.
ENV PG_MAJOR 9.3

# Set the desired PostgreSQL cluster name
ENV PG_CLUSTER_NAME main

#
# Set the username and password for a dedicated database user
# for administering CollectionSpace.
#
# IMPORTANT: The following are arbitrary, default placeholder
# values (see security warning above) that you should assume
# will be published to the entire world.
#
ENV DB_CSPACE_ADMIN_NAME u82255c6_5BBa
ENV DB_CSPACE_ADMIN_PASSWORD p52i39#Cs$%5R5b

#
# Add the PostgreSQL PGP key to verify PostgreSQL's Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
#
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

#
# Add PostgreSQL's Personal Package Archive (PPA) repository. Doing
# so makes it possible to use the standard 'apt-get' installer to
# install recent stable releases of PostgreSQL, newer than those
# available via the official repos associated with this Linux distro.
#
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

#
# Update the Ubuntu and PostgreSQL repository indexes.
#
RUN apt-get update

#
# Add a policy rule script that prevents package installation of PostgreSQL
# from initializing a database cluster and launching the PostgreSQL server.
#
ADD policy-rc.d /usr/sbin/policy-rc.d
RUN chmod u+x /usr/sbin/policy-rc.d

#
# Install dependencies, followed by PostgreSQL's client and server packages,
# and PostgreSQL contributions.
#
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install \
 python-software-properties \
 software-properties-common
RUN DEBIAN_FRONTEND=noninteractive apt-get -y -q install \
  postgresql-$PG_MAJOR \
  postgresql-client-$PG_MAJOR \
  postgresql-contrib-$PG_MAJOR

#
# Expose the standard PostgreSQL listening port from the container.
#
EXPOSE 5432

#
# Add a shell script to initialize the PostgreSQL database cluster,
# start the PostgreSQL server, and create a CollectionSpace
# database administrator user account.
#
ADD init_postgresql_cluster.sh /usr/local/bin/init_postgresql_cluster.sh
RUN chmod u+x /usr/local/bin/init_postgresql_cluster.sh

#
# Set the default command to run when starting the container. 
#
CMD ["/usr/local/bin/init-postgresql-cluster.sh"]
