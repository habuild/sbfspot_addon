# https://developers.home-assistant.io/docs/add-ons/configuration#add-on-dockerfile
ARG BUILD_FROM
FROM $BUILD_FROM AS builder

# Execute during the build of the image
ARG TEMPIO_VERSION BUILD_ARCH
RUN \
    curl -sSLf -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"

ENV LANG C.UTF-8
ENV MQTT_ENABLE 1

# Copy root filesystem
COPY rootfs /
# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# install requirements
RUN apk update && apk upgrade && apk add --no-cache git g++ make mysql-dev bluez-dev boost-dev curl-dev tzdata mosquitto-clients openrc mariadb-dev

# openrc changes
RUN \
    # Tell openrc its running inside a container, till now that has meant LXC
        sed -i 's/#rc_sys=""/rc_sys="lxc"/g' /etc/rc.conf &&\
    # Tell openrc loopback and net are already there, since docker handles the networking
        echo 'rc_provide="loopback net"' >> /etc/rc.conf &&\
    # no need for loggers
        sed -i 's/^#\(rc_logger="YES"\)$/\1/' /etc/rc.conf &&\
    # can't get ttys unless you run the container in privileged mode
        sed -i '/tty/d' /etc/inittab &&\
    # can't set hostname since docker sets it
        sed -i 's/hostname $opts/# hostname $opts/g' /etc/init.d/hostname &&\
    # can't mount tmpfs since not privileged
        sed -i 's/mount -t tmpfs/# mount -t tmpfs/g' /lib/rc/sh/init.sh &&\
    # can't do cgroups
        sed -i 's/cgroup_add_service /# cgroup_add_service /g' /lib/rc/sh/openrc-run.sh

RUN rc-status
RUN mkdir -p /run/openrc && touch /run/openrc/softlevel

# download and build SBFspot
RUN \
    cd /tmp \
    && git clone https://github.com/sbfspot/SBFspot.git . \
    && cd SBFspot \
    && sed -i s/mariadbclient/mariadb/ makefile \
    && make mariadb \
    && cd .. \
    && cd SBFspotUploadDaemon \
    &&sed -i s/mariadbclient/mariadb/ makefile \
    && make mariadb
    
# runtinme container   
FROM $BUILD_FROM

ARG TEMPIO_VERSION BUILD_ARCH
RUN \
    curl -sSLf -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${BUILD_ARCH}"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk update && apk upgrade && apk add --no-cache boost-date_time bluez-libs libstdc++ tzdata mariadb-common mariadb-connector-c ncurses-libs libcurl mosquitto-clients openrc
COPY rootfs /

#openrc was here
COPY --from=builder /run/openrc /run/openrc
RUN touch /run/openrc/softlevel

# Copy data for add-on

RUN mkdir -p /etc/sbfspot

COPY --from=builder /tmp/SBFspot/mariadb/bin/SBFspot /tmp/SBFspot/mariadb/bin/SBFspot
COPY --from=builder /tmp/SBFspotUploadDaemon/mariadb/bin/SBFspotUploadDaemon /tmp/SBFspotUploadDaemon/mariadb/bin/SBFspotUploadDaemon
COPY --from=builder /tmp/SBFspot/date_time_zonespec.csv /tmp/SBFspot/date_time_zonespec.csv
COPY --from=builder /tmp/SBFspot/TagList* /tmp/SBFspot/


RUN cp /tmp/SBFspot/mariadb/bin/SBFspot /etc/sbfspot
RUN cp /tmp/SBFspotUploadDaemon/mariadb/bin/SBFspotUploadDaemon /etc/sbfspot
RUN cp /tmp/SBFspot/date_time_zonespec.csv /etc/sbfspot
RUN cp /tmp/SBFspot/TagList* /etc/sbfspot

RUN chmod a+x /etc/sbfspot/generateConfig.sh /etc/sbfspot/openrc-restart-crashed.sh /etc/sbfspot/SBFspot /etc/sbfspot/SBFspotUploadDaemon /etc/init.d/SBFspotUploadDaemon.service /etc/sbfspot/SBFspot.default.cfg /etc/sbfspot/SBFspotUpload.default.cfg


# --- install cron ---
# set shell
RUN echo 'SHELL=/bin/bash' > /etc/crontabs/root
# daily data SBFspot
RUN echo '*/5 6-22 * * *    /etc/sbfspot/SBFspot -v -ad1 -am0 -ae0 -mqtt > /dev/stdout' >> /etc/crontabs/root
# monthly data SBFspot
RUN echo '55 05 * * *       /etc/sbfspot/SBFspot -v -sp0 -ad0 -am1 -ae1 -finq > /dev/stdout' >> /etc/crontabs/root
# openrc restart crashed services
RUN echo '*/15 * * * *       /etc/sbfspot/openrc-restart-crashed.sh -- SBFspotUploadDaemon.service > /dev/stdout' >> /etc/crontabs/root
# openrc status logging
RUN echo '*/5 * * * *       rc-status -s > /dev/stdout' >> /etc/crontabs/root

# install service
RUN rc-update add SBFspotUploadDaemon.service default

# Labels
LABEL \
    io.hass.name="SBFspot" \
    io.hass.description="Home Assitant addon for Bluetooth SBFspot, is an open source project to get actual and archive data out of an SMA® inverter over Bluetooth or Ethernet (Speedwire®)" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Hasqt <https://community.home-assistant.io/u/hasqt>" \
    org.label-schema.description="Home Assitant addon for Bluetooth SBFspot, is an open source project to get actual and archive data out of an SMA® inverter over Bluetooth or Ethernet (Speedwire®)" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="SBFspot" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/habuild/sbfspot_addon/tree/main/sbfspot" \
    org.label-schema.usage="https://github.com/habuild/sbfspot_addon/tree/main/sbfspot/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://github.com/habuild/sbfspot_addon" \
    org.label-schema.vendor="Hasqt"


#CMD [ "/run.sh" ] not needed with rootfs/etc/init.d/{slug}run
