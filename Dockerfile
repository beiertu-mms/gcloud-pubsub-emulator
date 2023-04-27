FROM golang:alpine as builder

RUN apk update && apk upgrade && apk add --no-cache curl git

ARG WAITFOR_VERSION=2.2.4
RUN curl -vsSLo /usr/bin/wait-for \
    "https://github.com/eficode/wait-for/releases/download/v${WAITFOR_VERSION}/wait-for"
RUN chmod +x /usr/bin/wait-for

RUN go install github.com/prep/pubsubc@latest

################################################################################

FROM google/cloud-sdk:428.0.0-alpine

COPY --from=builder /usr/bin/wait-for /usr/bin
COPY --from=builder /go/bin/pubsubc   /usr/bin
COPY                run.sh            /run.sh

RUN apk --update add --no-cache openjdk17-jre netcat-openbsd gcompat \
    && gcloud components install beta pubsub-emulator

ENV LD_PRELOAD=/lib/libgcompat.so.0

EXPOSE 8681

CMD /run.sh

