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

ENV PG_DEFAULT_CLUSTER_NAME main

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
# Set the desired major version of PostgreSQL to be installed.
#
ENV PG_MAJOR 9.3

#
# Set the desired PostgreSQL cluster name. (Default: 'main')
#
ENV PG_CLUSTER_NAME $PG_DEFAULT_CLUSTER_NAME

#
# Set the desired locale for a UTF-8 character encoding.
# (CollectionSpace requires that its PostgreSQL databases
# use a UTF-8 encoding.)
#
# The default locale below is for US English ('en_US'); set
# the locale's language and/or country/region here as needed:
#
ENV PG_CHAR_ENCODING en_US.UTF-8

#
# Generate locale data files for the specified character encoding,
# then set the value of the key locale-related environment variable.
#
RUN locale-gen $PG_CHAR_ENCODING
ENV LC_ALL $PG_CHAR_ENCODING

#
# Add the PostgreSQL PGP key to verify PostgreSQL's Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
#
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

#
# Add PostgreSQL's Personal Package Archive (PPA) repository. Doing
# so makes it possible to use the standard 'apt-get' installer to
# install recent stable releases of PostgreSQL, often newer than those
# provided by the repos that come standard with this Linux distro.
#
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list

#
# Update the Ubuntu and PostgreSQL repository indexes.
#
RUN apt-get update

#
# Add a policy rule script that prevents package installation of PostgreSQL
# from launching the PostgreSQL server.
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
# Installation of the PostgreSQL server from its Ubuntu package
# appears to initialize a database cluster at a default location,
# even if the PostgreSQL server isn't started.
#
# Move this newly-initialized cluster's directory to a non-default
# location, so that it won't be used. (Moving the cluster, rather
# than dropping it via pg_dropcluster, is also prudent to avoid
# the possibility of deleting a cluster that contains valued data.)
#
ENV PG_CLUSTER_TMP $(mktemp -d)
ENV PG_CLUSTER_PATH /var/lib/postgresql/$PG_MAJOR/$PG_DEFAULT_CLUSTER_NAME
RUN echo "Moving existing database cluster to $PG_CLUSTER_TMP ..."
RUN mv $PG_CLUSTER_PATH $PG_CLUSTER_TMP

#
# In addition to the cluster directory, its associated config
# directory is also moved to a non-default location here:
#
ENV PG_CONFIG_TMP $(mktemp -d)
ENV PG_CONFIG_PATH /etc/postgresql/$PG_MAJOR/$PG_DEFAULT_CLUSTER_NAME
RUN echo "Moving existing database cluster to $PG_CONFIG_TMP ..."
RUN mv $PG_CONFIG_PATH $PG_CONFIG_TMP

#
# Expose the standard PostgreSQL listening port from the container.
#
EXPOSE 5432

#
# Add a shell script to initialize the PostgreSQL database cluster,
# start the PostgreSQL server, and create a CollectionSpace
# database administrator user account.
#
ADD init-postgresql-cluster.sh /usr/local/bin/init-postgresql-cluster.sh
RUN chmod u+x /usr/local/bin/init-postgresql-cluster.sh

#
# Set the default command to run when starting the container. 
#
CMD ["/usr/local/bin/init-postgresql-cluster.sh"]
