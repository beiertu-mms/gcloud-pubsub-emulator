FROM golang:alpine AS builder

ARG WAITFOR_VERSION=2.2.4

COPY ./pubsubc /pubsubc

RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl git \
    && curl -vsSLo /usr/bin/wait-for \
    "https://github.com/eficode/wait-for/releases/download/v${WAITFOR_VERSION}/wait-for" \
    && chmod +x /usr/bin/wait-for \
    && go build -C /pubsubc -v

################################################################################

FROM google/cloud-sdk:536.0.1-alpine

COPY --from=builder /usr/bin/wait-for /usr/bin
COPY --from=builder /pubsubc/pubsubc   /usr/bin
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

