# Docker launchers for Confluence and Jira - Data Center - Public

This repository builds Docker images that can be launched for every supported version of Confluence and Jira.

## How to use

```
./create-image.sh confluence 9.4.0
cd confluence-9.4.0
docker compose up --detach
```

## Where are the logs? What is the password to the database?

Everything is written in `confluence-9.4.0/docker-compose.yml` (depending on your app and version).

## Install your plugin

Copy the .jar file to the quickreload folder: `cp myapp.jar confluence-9.4.0/quickreload/`

## Troubleshoting

1. Symptom:
```
ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```
The first time, building the image often fails. Launch it a second time.

2. Symptom: `docker: 'compose' is not a docker command.`

Try either `docker-compose up` (deprecated) or `docker compose up` (Docker v2). If only the former works, then
it's a good idea to upgrade your Docker.