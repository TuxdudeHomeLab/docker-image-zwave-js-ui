# syntax=docker/dockerfile:1

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG} AS builder

COPY scripts/start-zwave-js-ui.sh /root/

ARG ZWAVE_JS_UI_VERSION
ARG ZWAVE_JS_UI_SHA256_CHECKSUM

# hadolint ignore=SC1091,SC3044
RUN \
    set -E -e -o pipefail \
    && export HOMELAB_VERBOSE=y \
    # Install build dependencies. \
    && homelab install util-linux build-essential python3 \
    # Download and install the release. \
    && homelab install-tar-dist \
        https://github.com/zwave-js/zwave-js-ui/archive/refs/tags/${ZWAVE_JS_UI_VERSION:?}.tar.gz \
        ${ZWAVE_JS_UI_SHA256_CHECKSUM:?} \
        zwave-js-ui \
        zwave-js-ui-${ZWAVE_JS_UI_VERSION#v} \
        root \
        root \
    && pushd /opt/zwave-js-ui \
    && source "${NVM_DIR:?}/nvm.sh" \
    && npm ci --no-audit --no-fund --no-update-notifier \
    && npm_config_build_from_source=true npm rebuild @serialport/bindings-cpp \
    && npm run build \
    && npm prune --omit=dev \
    && find . -mindepth 1 -maxdepth 1 \
        ! -name "node_modules" \
        ! -name "snippets" \
        ! -name ".git" \
        ! -name "package.json" \
        ! -name "server" \
        ! -name "dist" \
        -exec rm -rf {} + \
    && popd \
    # Copy the start-zwave-js-ui.sh script. \
    && cp /root/start-zwave-js-ui.sh /opt/zwave-js-ui/

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG USER_NAME
ARG GROUP_NAME
ARG USER_ID
ARG GROUP_ID
ARG ZWAVE_JS_UI_VERSION
ARG PACKAGES_TO_INSTALL

# hadolint ignore=SC3009
RUN --mount=type=bind,target=/build,from=builder,source=/opt \
    set -E -e -o pipefail \
    && export HOMELAB_VERBOSE=y \
    # Install dependencies. \
    && homelab install ${PACKAGES_TO_INSTALL:?} \
    # Create the user and the group. \
    && homelab add-user \
        ${USER_NAME:?} \
        ${USER_ID:?} \
        ${GROUP_NAME:?} \
        ${GROUP_ID:?} \
        --no-create-home-dir \
    && cp -rf /build/zwave-js-ui-${ZWAVE_JS_UI_VERSION#v} /opt \
    && ln -sf /opt/zwave-js-ui-${ZWAVE_JS_UI_VERSION#v} /opt/zwave-js-ui \
    && ln -sf /opt/zwave-js-ui/start-zwave-js-ui.sh /opt/bin/start-zwave-js-ui \
    && mkdir -p /data/zwave-js-ui/{config,logs,store,backups} \
    && chown -R ${USER_NAME}:${GROUP_NAME:?} /opt/zwave-js-ui-${ZWAVE_JS_UI_VERSION#v} /data/zwave-js-ui

EXPOSE 8091

ENV NODE_ENV=production
ENV ZWAVEJS_EXTERNAL_CONFIG=/data/zwave-js-ui/config
ENV ZWAVEJS_LOGS_DIR=/data/zwave-js-ui/logs
ENV STORE_DIR=/data/zwave-js-ui/store
ENV BACKUPS_DIR=/data/zwave-js-ui/backups

ENV USER=${USER_NAME}
USER ${USER_NAME}:${GROUP_NAME}
WORKDIR /home/${USER_NAME}

CMD ["start-zwave-js-ui"]
STOPSIGNAL SIGTERM
