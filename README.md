# Dockerized Integration Test POC

The goal of this POC is to illustrate how to include integration testing in
local development and continuous integration workflows using Docker.

The demo setup consists of a barebones Flask application that is backed by two
Elasticsearch indexes, along with some unit tests and integration tests.

----------

## Requirements

1. Docker
1. Docker Compose (preinstalled w/ Docker for Mac)

## Basics
### Starting the application

```bash
  docker-compose build
  docker-compose up
```

### Running integration tests

```bash
  docker-compose run toy-flask-test pytest tests/integration
```

A script has been included to build the image, start the application, run the
integration tests, and tear everything down:


```bash
  ./tests/run_integration_tests.sh
```

The CircleCI config also uses this script.

## Workflows
### Local Development

The local development workflow might look something like this:

```bash
  # Make some change
  vim app.py

  # Run unit tests and build image
  docker-compose build

  # Unit tests fail, fix unit tests
  vim tests/unit/app_test.py

  # Re-run unit tests and build image
  docker-compose build

  # Start the application
  docker-compose up

  # Run integration tests
  docker-compose run toy-flask-test pytest tests/integration

  # Integration tests fail, fix integration tests
  vim tests/integration/app_test.py

  # Rebuild
  docker-compose build

  # Restart application
  docker-compose up

  # Run integration tests
  docker-compose run toy-flask-test pytest tests/integration
```

----------

## Notes

If using a docker-based executor in CircleCI:
- Curling the containers from the executor won't work because the application
  containers are running on some remote host with indeterminable IP
  - To get around this for polling for service readiness, we are running the
    curl commands from the test image
- Volume mounts won't work for probably similar reasons
  ([reference](https://support.circleci.com/hc/en-us/articles/360007324514))
  - To get around this for seeding Elasticsearch with data, we are baking the
    data into the Elasticsearch image

