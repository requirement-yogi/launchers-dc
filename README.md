# Docker launchers for Confluence and Jira - Data Center - Public

This repository builds Docker images that can be launched for every supported version of Confluence and Jira.

## How to use

```
./create-image.sh confluence 9.4.0
vi /etc/hosts # Add the local domain name of this Confluence to your localhost[1]
cd confluence-9.4.0
docker compose up --detach
```

Note: We detect when you are on an Apple M1 and above, to build the "aarch64" version of the Docker image
by default. But for a surprising reason, Confluence 10 doesn't seem to run with that image. So please
run it in amd64 version (might be slower, might require Rosetta 2):

```
./create-image.sh confluence 10.0.0-m73 --apple-but-use-amd64
```

[1] We use separate domain names, because cookies overlap each others when you access all Confluence with 'localhost',
even if they use a different port.

## Where are the logs? What is the password to the database? What is even the URL of Confluence!?

Everything is written in `confluence-9.4.0/docker-compose.yml` (depending on your app and version).

## Install your plugin

Copy the .jar file to the quickreload folder: `cp myapp.jar confluence-9.4.0/quickreload/`

## Troubleshooting

1. Symptom:
```
ERROR: failed to solve: failed to read dockerfile: open Dockerfile: no such file or directory
```
The first time, building the image often fails. Launch it a second time.

2. Symptom: `docker: 'compose' is not a docker command.`

Try either `docker-compose up` (deprecated) or `docker compose up` (Docker v2). If only the former works, then
it's a good idea to upgrade your Docker.