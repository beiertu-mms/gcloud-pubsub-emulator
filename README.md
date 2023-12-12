<h1 align="center">
  <img alt="cch" src=".github/banner.png">
</h1>

<p align="center">
  <a href="https://github.com/beiertu-mms/gcloud-pubsub-emulator/blob/master/LICENSE">
    <img alt="license" src="https://img.shields.io/github/license/beiertu-mms/gcloud-pubsub-emulator" />
  </a>
  <a href="https://github.com/beiertu-mms/gcloud-pubsub-emulator/releases">
    <img alt="version" src="https://img.shields.io/github/v/release/beiertu-mms/gcloud-pubsub-emulator" />
  </a>
</p>

This repository contains the Docker configuration for [Google's PubSub emulator](https://cloud.google.com/pubsub/docs/emulator).
It's mainly the dockerization and documentation of [prep/pubsubc](https://github.com/prep/pubsubc).

This is a fork of [marcelcorso/gcloud-pubsub-emulator](https://github.com/marcelcorso/gcloud-pubsub-emulator),
with updated versions of [gcloud](https://cloud.google.com/sdk/gcloud), [OpenJDK](https://openjdk.org) and [eficode/wait-for](https://github.com/eficode/wait-for).

## Supported tags

- `latest`: latest build of the image with the [last commit on master branch][master-branch]
- `\d+.\d+.\d+`: the build for a [given gcloud version][google-release-note]

[master-branch]: https://github.com/beiertu-mms/gcloud-pubsub-emulator/tree/master
[google-release-note]: https://cloud.google.com/release-notes

This image is available with gcloud version >= `428.0.0`.

## Usage

To run this image:

```shell
docker run -d \
  -p 8681:8681 \
  -e PUBSUB_PROJECT1=test-project,test-topic:test-subscription \
  tungbeier/gcloud-pubsub-emulator:latest
```

Or, with [docker-compose](https://docs.docker.com/compose/), first create a `docker-compose.yaml`

```yaml

---
services:
  pubsub-emulator:
    image: tungbeier/gcloud-pubsub-emulator:latest
    container_name: pubsub-emulator
    expose:
      - "8682"
    ports:
      - "8681:8681"
    environment:
      - PUBSUB_PROJECT1=test-project,test-topic:test-subscription

  # verify, that the emulator is running
  wait-for:
    image: eficode/wait-for:latest
    container_name: wait-for
    command: ["pubsub-emulator:8682", "--", "echo", "pubsub emulator is running"]
    depends_on:
      - pubsub-emulator
```

then run

```shell
docker-compose up -d
```

After the container has started, the `PUBSUB_EMULATOR_HOST` environment variable needs to be set before running any application against the emulator, either with

```shell
export PUBSUB_EMULATOR_HOST=localhost:8681
./my-pubsub-app
```

or run the application with the environment variable

```shell
env PUBSUB_EMULATOR_HOST=localhost:8681 ./my-pubsub-app
```

### Change emulator ports

If desired, the emulator port (default: 8681) and ready port (default: 8682) can be changed via setting
the environment variables `EMULATOR_PORT` and `EMULATOR_READY_PORT` respectively when starting the container.

### Create topic and subscription
This image also provides the ability to create topics and subscriptions in projects on startup
by specifying the `PUBSUB_PROJECT` environment variable with a sequential number appended to it,
starting with _1_. The format of the environment variable is relatively simple:

```txt
PUBSUB_PROJECT1=PROJECT_1,TOPIC_1,TOPIC_2:SUBSCRIPTION_1:SUBSCRIPTION_2,TOPIC_3:SUBSCRIPTION_3
PUBSUB_PROJECT2=PROJECT_2,TOPIC_4
```

A comma-separated list where the first item is the _project ID_ and the rest are topics.
The topics themselves are colon-separated where the first item is the _topic ID_ and the rest are _subscription IDs_.

A topic doesn't necessarily need to specify subscriptions. Created subscriptions are _pull_ subscriptions.

> [!IMPORTANT]
> At least the first `PUBSUB_PROJECT1` with a project ID and one topic needs to be given.

For example, if you have _project ID_ `company-dev`, with topic `invoices` that has a subscription `invoice-calculator`,
another topic `chats` with subscriptions `slack-out` and `irc-out` and a third topic `notifications` without any subscriptions,
you'd define it this way:

```txt
PUBSUB_PROJECT1=company-dev,invoices:invoice-calculator,chats:slack-out:irc-out,notifications
```

So the full command would look like:

```shell
docker run -d \
  -p 8681:8681 \
  -e PUBSUB_PROJECT1=company-dev,invoices:invoice-calculator,chats:slack-out:irc-out,notifications \
  tungbeier/gcloud-pubsub-emulator:latest
```

If you want to define more projects, you'd simply add a `PUBSUB_PROJECT2`, `PUBSUB_PROJECT3`, etc.

### Check for readiness

When this image starts up, the emulator port 8681 (default) will be made available.
After it creates all the specified projects with their topics and subscriptions, the port 8682 will also be opened.

So if you're using this Docker image in a docker-compose setup or something similar,
you might have leveraged scripts like [wait-for](https://github.com/eficode/wait-for) or [wait-for-it](https://github.com/vishnubob/wait-for-it)
to detect when the PubSub service with all required projects, topics and subscriptions are available, before starting a container that depends on them.

