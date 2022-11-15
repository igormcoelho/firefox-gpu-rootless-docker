# firefox-gpu-rootless-docker
Rootless docker execution of Firefox browser with GPU/WebGL browser (working NVIDIA example on Ubuntu 22.04, but need to specify correct driver)


## Why this project?

Web browsers are fundamental nowadays, so as it is important that their users (and their files) to be kept secure from any malicious process.
A way to provide greater isolation (and some greater sense of security) is to run the browser in a microservice/container.

This tutorial demonstrates how to run firefox (v. 106) inside a docker container, tested on a Linux Ubuntu 22.04.

## How to use it

We have three main steps:

1. install rootless docker
1. build firefox image and run on docker
1. install locally for a user

And one extra step for adding security with apparmor.

### First: install docker and make it rootless

Installing docker can be done from many ways, so feel free to ignore the next steps, if you already have docker.
We assume docker is meant to be rootless, but it will also work with root enabled (only keep root in docker if you **REALLY NEED**, otherwise make it rootless).

If you want to install rootless docker, you can quickly follow our instructions (see at [DockerRootless.md](./DockerRootless.md)) or follow official docker guidelines at [https://docs.docker.com](https://docs.docker.com/engine/security/rootless/).

Now, we assume you have `$ docker ps` working without sudo for a regular user.

### Second: build and run your rootless firefox

1. Clone this repo! 
1. Go to `firefox-docker` folder and type `make` (or just `cd docker_build && ./build.sh`)
1. It will create an image for `youruser/firefox` (based on Ubuntu 20.04, not 22.04... but that's fine for now!)
    - Remember to update [dockerfile](firefox-docker/docker_build/dockerfile) with your specific nvidia GPU driver, or just remove the nvidia driver installation part (it is currently targetting `nvidia-driver-520`, but will certainly change in the future, pay attention to that!)
    - Audio will be provided by pulseaudio, which is also automatically installed in the image
1. Launch firefox, using the GPU or the non-GPU versions at folder `firefox-docker`:
    - `./firefox-docker.sh`      (without gpu)
    - `./firefox-gpu-docker.sh`  (with gpu)

Take some time to understand `firefox-docker.sh`:

```
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
#
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
```

It mounts local `FirefoxData` as `/root/.mozilla/firefox/` (remember that rootless docker `root` user is, in fact, your powerless host user).
Also, folder `FirefoxDownloads` will store downloads. 
Audio and Camera stuff is related to devices `input`, `snd` and `video0`. 
Feel free to try to remove stuff and see if it works fine... the less priviledges, the better.

#### How to access Downloads folder?

We now assume installation at `~/.local/firefox-docker/` and config at `~/.config/firefox-docker/`.
Then, firefox downloads will be located at `~/.local/firefox-docker/FirefoxDownloads`. 
You can also bookmark it on Nautilus or create a symbolic link from the real Downloads folder.

Note that container is running on `root`, but since docker is rootless, it will automatically match root files with current user id.


### Third: Install locally for the user

An easy way to install this locally:

1. put script `firefox-docker.sh` (or `firefox-gpu-docker.sh`) inside user folder `~/bin`
1. put `firefox-docker` folder inside user folder `~/.local`

Remember to fix these two lines on `firefox-docker.sh` and choose firefox `Downloads` and data folders:

```
  -v $HOME/.local/firefox-docker/FirefoxDownloads:/root/Downloads \
  -v $HOME/.config/firefox-docker/FirefoxData:/root/.mozilla/firefox/ \
```

#### Advice to create an icon and favorite (on Ubuntu 22.04)

1. Copy the `firefox-docker.desktop` and icon on `desktop/` folder to `$HOME/.local/share/applications/`
1. Fix `$HOME` path in `desktop/firefox-docker.desktop`, if necessary
1. Fix the name in your language inside `.desktop` file (or just put some "Docker" prefix, to make sure it's the right icon)
1. Add to favorite:

```
# NO SUDO HERE!
$ cd desktop/
$ cp firefox-docker.desktop ~/.local/share/applications/
$ cp firefox256.png ~/.local/share/applications/
$ cp firefox-docker/firefox-docker.sh ~/bin
$ gsettings get org.gnome.shell favorite-apps
       # => ['org.gnome.Nautilus.desktop']
$ gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'firefox-docker.desktop'
```

### Extra: using apparmor or selinux to limit the power of rootless docker

Having docker rootless is nice, but it's even better if we can constrain its access the most.
For this, we need to install appamor (see our **highly experimental** instructions at [DockerApparmor.md](./DockerApparmor.md)),
or selinux (see our **highly experimental** instructions at [DockerSELinux.md](./DockerSELinux.md)).

Currently, SELinux does not likely work on Ubuntu 22.04, as it is typically used on RHEL/Fedora distributions,
so for Ubuntu 22.04 one should try apparmor.


## License

MIT License (2022)

### Disclaimer

As usual: **use this at your own risk! no warranty**. Feel free to adapt and redistribute.

If it doesn't work, file an issue... it's experimental (didn't test in many computers/systems yet). 
Good luck!
