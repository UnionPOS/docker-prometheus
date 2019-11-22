FROM unionpos/ubuntu:16.04

ENV VERSION 2.11.1
ENV DOWNLOAD_FILE "prometheus-${VERSION}.linux-amd64.tar.gz"
ENV DOWNLOAD_URL "https://github.com/prometheus/prometheus/releases/download/v${VERSION}/${DOWNLOAD_FILE}"
ENV DOWNLOAD_SHA 50b5f4dfd3f358518c1aaa3bd7df2e90780bdb5292b5c996137c2b1e81102390

ENV UID 4002
ENV GID 4002

# create user and group with our specified user and group ids
RUN groupadd -r -g $GID prometheus \
    && useradd -r -u $UID -g prometheus prometheus

# download, checksum, unpack
RUN set -ex \
    && buildDeps=' \
    wget \
    ' \
    && apt-get update -qq \
    && apt-get install -qq -y --no-install-recommends $buildDeps\
    && wget -O "$DOWNLOAD_FILE" "$DOWNLOAD_URL" \
    && apt-get purge -qq -y --auto-remove $buildDeps && rm -rf /var/lib/apt/lists/* \
    && echo "${DOWNLOAD_SHA} *${DOWNLOAD_FILE}" | sha256sum -c - \
    && mkdir /prom /etc/prometheus/ /usr/share/prometheus/ \
    && tar xfvz "$DOWNLOAD_FILE" --strip-components=1 -C /prom \
    && mv /prom/prometheus /bin/prometheus \
    && mv /prom/promtool /bin/promtool \
    && mv /prom/prometheus.yml /etc/prometheus/prometheus.yml \
    && mv /prom/console_libraries /usr/share/prometheus/console_libraries \
    && mv /prom/consoles /usr/share/prometheus/consoles \
    && ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/ \
    && mkdir -p /prometheus \
    && chown -R prometheus:prometheus /etc/prometheus /prometheus \
    && rm -rf /prom \
    && rm "$DOWNLOAD_FILE"

USER       prometheus

# EXPOSE     9090

VOLUME     [ "/prometheus" ]

WORKDIR    /prometheus

ENTRYPOINT [ "/bin/prometheus" ]

CMD        [ "--config.file=/etc/prometheus/prometheus.yml", \
    "--storage.tsdb.path=/prometheus", \
    "--web.console.libraries=/usr/share/prometheus/console_libraries", \
    "--web.console.templates=/usr/share/prometheus/consoles" ]
