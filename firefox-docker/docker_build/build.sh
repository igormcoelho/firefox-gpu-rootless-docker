#!/bin/bash
docker build -t $(whoami)/firefox --build-arg PUID=$(id -u) --build-arg PGID=$(id -g) .
