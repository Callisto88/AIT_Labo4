# Base image is the Official HAProxy
FROM haproxy:1.5

MAINTAINER Cyril de Bourgues <cyril.debourgues@heig-vd.ch>

# Install some tools
RUN apt-get update && apt-get -y install wget curl vim rsyslog xz-utils

RUN curl -sSLo /tmp/s6.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v1.17.2.0/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6.tar.gz -C / \
  && rm -f /tmp/s6.tar.gz

# Install serf (for decentralized cluster membership: https://www.serf.io/)
RUN mkdir /opt/bin \
    && curl -sSLo /tmp/serf.gz https://releases.hashicorp.com/serf/0.7.0/serf_0.7.0_linux_amd64.zip \
    && gunzip -c /tmp/serf.gz > /opt/bin/serf \
    && chmod 755 /opt/bin/serf \
    && rm -f /tmp/serf.gz

# Install NodeJS
RUN curl -sSLo /tmp/node.tar.xz https://nodejs.org/dist/v4.4.4/node-v4.4.4-linux-x64.tar.xz \
  && tar -C /usr/local --strip-components 1 -xf /tmp/node.tar.xz \
  && rm -f /tmp/node.tar.xz

# Install the handlebars-cmd node module and its dependencies
RUN npm install -g handlebars-cmd

# Copy the S6 service and make the run script executable
COPY services/ha /etc/services.d/ha
RUN chmod +x /etc/services.d/ha/run

COPY services/serf /etc/services.d/serf
RUN chmod +x /etc/services.d/serf/run

# Copy events handler scripts
# Define our target directory
ARG DIRECTORY=/serf-handlers

# Make sure destination directory exists, create if not
RUN [ -d "$DIRECTORY" ] || mkdir -p $DIRECTORY

# Copy our handlers scripts into that directory
COPY scripts/ $DIRECTORY

# Make them executable
RUN chmod +x $DIRECTORY/member-*

# Copy the haproxy and syslog config
COPY config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY config/rsyslogd.cfg /etc/rsyslog.d/49-haproxy.conf

# Define our target directory
ARG DIRECTORY=/config

# Make sure destination directory exists, create if not
RUN [ -d "$DIRECTORY" ] || mkdir -p $DIRECTORY

# Copy our handlers scripts into that directory
COPY config/haproxy.cfg.hb $DIRECTORY

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Define our target directory
ARG DIRECTORY=/nodes

# Make sure destination directory exists, create if not
RUN [ -d "$DIRECTORY" ] || mkdir -p $DIRECTORY

# Expose the ports for Serf
EXPOSE 7946 7373

# Expose the HA proxy ports
EXPOSE 80 1936

# Define an environment variable
ENV ROLE balancer

# This will start S6 as our main process in our container
ENTRYPOINT ["/init"]
