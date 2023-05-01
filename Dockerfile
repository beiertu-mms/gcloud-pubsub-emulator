FROM golang:alpine as builder

ARG WAITFOR_VERSION=2.2.4
RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl='8.0.1-r0' git='2.38.5-r0' \
    && curl -vsSLo /usr/bin/wait-for \
    "https://github.com/eficode/wait-for/releases/download/v${WAITFOR_VERSION}/wait-for" \
    && chmod +x /usr/bin/wait-for \
    && go install github.com/prep/pubsubc@latest

################################################################################

FROM google/cloud-sdk:428.0.0-alpine

COPY --from=builder /usr/bin/wait-for /usr/bin
COPY --from=builder /go/bin/pubsubc   /usr/bin
COPY                run.sh            /run.sh

ARG PUBSUB_USER=pubsub

RUN apk --update add --no-cache openjdk17-jre='17.0.7_p7-r0' netcat-openbsd='1.130-r4' gcompat='1.1.0-r0' \
    && gcloud components install beta pubsub-emulator \
    && adduser -D ${PUBSUB_USER} \
    && chown -v ${PUBSUB_USER} /run.sh

ENV LD_PRELOAD=/lib/libgcompat.so.0

EXPOSE 8681
USER ${PUBSUB_USER}

CMD ["/run.sh"]

