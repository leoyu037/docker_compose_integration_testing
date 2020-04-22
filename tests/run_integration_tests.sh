#!/bin/bash
set -e

export GIT_ROOT="`git rev-parse --show-toplevel`"
export COMPOSE_PROJECT_NAME=demo

function teardown {
  echo "Tearing down containers"
  cd "$GIT_ROOT"
  docker-compose kill
  docker-compose down || true
}

function wait_for_url {
  local URL="$1"
  local RETRIES=10

  echo "Waiting for $1 to be ready..."
  # We run these curl commands from within a container because
  # the containers are not guaranteed to be on the same host in
  # circleci
  while [[ "`docker-compose run toy-flask-test curl -s -o /dev/null "$1" -w "%{http_code}"`" != "200" ]]; do
    RETRIES=$[$RETRIES-1]
    echo "Retries remaining: $RETRIES"
    sleep 3

    if [[ $RETRIES == 0 ]]; then
      echo "Out of retries, aborting"
      docker-compose run toy-flask-test curl "$1"
      exit 1
    fi
  done
  echo "200 [OK]!"
}

# Always teardown on script exit
trap teardown EXIT

echo "Building containers"
cd "$GIT_ROOT"
docker-compose build

echo "Starting containers"
docker-compose up -d
wait_for_url "toy-flask-es:9200/_cluster/health?wait_for_status=green"
wait_for_url "toy-flask:80/"

echo "Running tests"
export TEST_CONTAINER_NAME=integration-test
docker-compose run --name $TEST_CONTAINER_NAME toy-flask-test \
  pytest tests/integration --junitxml=/test_reports/integration/test_report.xml

echo "Extracting test report"
# In CircleCI, local volume mounts don't work when using a docker-based
# executor, so we extract the test report before cleaning up containers
docker container cp "$TEST_CONTAINER_NAME:/test_reports" .
