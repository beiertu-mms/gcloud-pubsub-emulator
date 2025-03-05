FROM golang:alpine as builder

ARG WAITFOR_VERSION=2.2.4
RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl git \
    && curl -vsSLo /usr/bin/wait-for \
    "https://github.com/eficode/wait-for/releases/download/v${WAITFOR_VERSION}/wait-for" \
    && chmod +x /usr/bin/wait-for \
    && go install github.com/beiertu-mms/pubsubc@latest

################################################################################

FROM google/cloud-sdk:513.0.0-alpine

COPY --from=builder /usr/bin/wait-for /usr/bin
COPY --from=builder /go/bin/pubsubc   /usr/bin
COPY                run.sh            /run.sh

ARG PUBSUB_USER=pubsub

RUN apk --update add --no-cache openjdk17-jre netcat-openbsd \
    && gcloud components install beta pubsub-emulator \
    && adduser -D ${PUBSUB_USER} \
    && chown -v ${PUBSUB_USER} /run.sh

ENV EMULATOR_PORT=8681
ENV EMULATOR_READY_PORT=8682

EXPOSE ${EMULATOR_PORT}
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD wget "http://localhost:${EMULATOR_READY_PORT}" || exit 1

USER ${PUBSUB_USER}

CMD ["/run.sh"]

