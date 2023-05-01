#!/usr/bin/env bash

if [[ -z "${EMULATOR_PORT}" ]]; then
  echo "[run.sh] EMULATOR_PORT environment variable is not set. Default to 8681."
  EMULATOR_PORT=8681
fi

if [[ -z "${EMULATOR_READY_PORT}" ]]; then
  echo "[run.sh] EMULATOR_READY_PORT environment variable is not set. Default to 8682."
  EMULATOR_READY_PORT=8682
fi

# Start the PubSub client in the background. It will poll for an open PubSub
# emulator port and create its topics and subscriptions when it's up.
#
# After it's done, port 8682 will be open to facilitate the wait-for and
# wait-for-it scripts.
(
  echo "[run.sh] Wait for emulator to start on port $EMULATOR_PORT"
  /usr/bin/wait-for localhost:"$EMULATOR_PORT" \
    -- env PUBSUB_EMULATOR_HOST=localhost:"$EMULATOR_PORT" \
    /usr/bin/pubsubc -debug

  echo "[run.sh] Open readiness port $EMULATOR_READY_PORT"
  nc -lkp "$EMULATOR_READY_PORT" >/dev/null
) &

# Start the PubSub emulator in the foreground.
gcloud beta emulators pubsub start --host-port=0.0.0.0:"$EMULATOR_PORT" "$@"
