#!/bin/bash

# get the xdg runtime dir
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

ME=$(whoami)
echo "Running Docker Image without GPU support: $ME/firefox"

# run without gpu
docker run --name firefox_ubuntu_nogpu --rm \
  --net host \
  --device /dev/input \
  --device /dev/snd \
  --device /dev/video0 \
  -e DISPLAY=$DISPLAY \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v /dev/shm:/dev/shm \
  -v /etc/machine-id:/etc/machine-id:ro \
  -v $XDG_RUNTIME_DIR/pulse:$XDG_RUNTIME_DIR/pulse:ro \
  -v $XDG_RUNTIME_DIR/bus:$XDG_RUNTIME_DIR/bus:ro \
  -v /var/lib/dbus/machine-id:/var/lib/dbus/machine-id:ro \
  -v /run/dbus:/run/dbus:ro \
  -v /run/udev/data:/run/udev/data:ro \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  -v ./FirefoxDownloads:/root/Downloads \
  -v ./FirefoxData:/root/.mozilla/firefox/ \
  $(whoami)/firefox

