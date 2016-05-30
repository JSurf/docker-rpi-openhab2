# openhab image 
FROM jsurf/rpi-java:latest

RUN [ "cross-build-start" ]

ARG DOWNLOAD_URL="https://openhab.ci.cloudbees.com/job/openHAB-Distribution/lastSuccessfulBuild/artifact/distributions/openhab-online/target/openhab-online-2.0.0-SNAPSHOT.zip"
ENV APPDIR="/openhab" OPENHAB_HTTP_PORT='8080' OPENHAB_HTTPS_PORT='8443' EXTRA_JAVA_OPTS=''

# Install Basepackages
RUN \
    apt-get update && \
    apt-get install --no-install-recommends -y \
      software-properties-common \
      sudo \
      unzip \
      wget \
    && rm -rf /var/lib/apt/lists/*

# Add openhab user
RUN adduser --disabled-password --gecos '' --home ${APPDIR} openhab &&\
    adduser openhab sudo &&\
    adduser openhab dialout &&\
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers.d/openhab

WORKDIR ${APPDIR}

RUN \
    wget -nv -O /tmp/openhab.zip ${DOWNLOAD_URL} &&\
    unzip -q /tmp/openhab.zip -d ${APPDIR} &&\
    rm /tmp/openhab.zip

RUN mkdir -p ${APPDIR}/userdata/logs && touch ${APPDIR}/userdata/logs/openhab.log

# Copy directories for host volumes
RUN cp -a /openhab/userdata /openhab/userdata.dist && \
    cp -a /openhab/conf /openhab/conf.dist
COPY files/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

RUN chown -R openhab:openhab ${APPDIR}

RUN [ "cross-build-end" ]

USER openhab
# Expose volume with configuration and userdata dir
VOLUME ${APPDIR}/conf ${APPDIR}/userdata ${APPDIR}/addons
EXPOSE 8080 8443 5555
CMD ["server"]