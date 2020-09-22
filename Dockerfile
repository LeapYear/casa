# syntax = docker/dockerfile:experimental

# Build with experimental buildkit
# See: https://github.com/moby/buildkit/blob/master/frontend/dockerfile/docs/experimental.md
# $ DOCKER_BUILDKIT=1 docker build . --progress=plain -t leapyear/casa
FROM debian:buster-slim as casa-build
RUN --mount=type=cache,target=/var/lib/apt apt-get update \
    && apt-get install -y curl git g++ gcc libc6-dev libffi-dev libgmp-dev make xz-utils zlib1g-dev git gnupg netbase
ARG STACK_VERSION=2.3.3
RUN curl -sSLO "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-x86_64.tar.gz" \
    && mkdir ./stack \
    && tar xvf "stack-${STACK_VERSION}-linux-x86_64.tar.gz" --strip-components 1 -C ./stack \
    && mv ./stack/stack /usr/local/bin/stack \
    && rm -r ./stack
RUN git clone https://github.com/fpco/casa.git /casa
WORKDIR /casa
RUN --mount=type=cache,target=/root/.stack /usr/local/bin/stack install --flag casa-server:sqlite --flag casa-server:-postgresql casa-server

FROM debian:buster-slim as casa
COPY --from=casa-build /root/.local/bin/casa-server /bin/casa-server
ENV DBCONN="/var/tmp/casa.sqlite"
ENV PORT=80
ENV AUTHORIZED_PORT=443
EXPOSE $PORT $AUTHORIZED_PORT
CMD ["casa-server"]
