#!/bin/bash

# FROM: https://github.com/andrewmackrodt/dockerfiles/blob/de686ccddda2d7fd18bbd7ad6ae67762a1a8c3bb/firefox-x11/README.md
# detect gpu devices to pass through
GPU_DEVICES=$( \
    echo "$( \
        find /dev -maxdepth 1 -regextype posix-extended -iregex '.+/nvidia([0-9]|ctl)' \
            | grep --color=never '.' \
          || echo '/dev/dri'\
      )" \
      | sed -E "s/^/--device /" \
  )

# get the xdg runtime dir
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

echo "GPU: $GPU_DEVICES"
echo "REMEMBER TO CHECK IF DRIVER MATCHES WITH YOUR HOST DRIVER!"
echo "CHECK IF WEBGL IS WORKING: http://get.webgl.org"
#
# other GPU tests
#
# https://www.matthew-x83.com/online/gpu-test.php
# https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/By_example/Detect_WebGL


ME=$(whoami)
echo "Running Docker Image with GPU support: $ME/firefox"

docker run --name firefox_ubuntu_gpu --rm \
  --net host \
  --device /dev/input \
  --device /dev/snd \
  --device /dev/video0 \
  $GPU_DEVICES \
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
  -v $HOME/.local/firefox-docker/FirefoxDownloads:/root/Downloads \
  -v $HOME/.local/firefox-docker/FirefoxData:/root/.mozilla/firefox/ \
  $(whoami)/firefox 
