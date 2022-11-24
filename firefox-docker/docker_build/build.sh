#!/bin/bash

PKG=$(apt list --installed | grep nvidia-driver | cut -d '/' -f1)
docker build --build-arg NVIDIA_PKG="$PKG" --build-arg HOST_TZ=$(cat /etc/timezone) -t $(whoami)/firefox .
