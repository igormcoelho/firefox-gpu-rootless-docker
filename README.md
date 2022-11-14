# firefox-gpu-rootless-docker
Rootless docker execution of Firefox browser with GPU/WebGL browser (working NVIDIA example on Ubuntu 22.04, but need to specify correct driver)


## Why this project?

Web browsers are fundamental nowadays, so as it is important that their users (and their files) to be kept secure from any malicious process.
A way to provide greater isolation (and some greater sense of security) is to run the browser in a microservice/container.

This tutorial demonstrates how to run firefox (v. 106) inside a docker container, tested on a Linux Ubuntu 22.04.

## How to use it

### First: install docker and make it rootless

Installing docker can be done from many ways, so feel free to ignore the next steps, if you already have docker.
We assume docker is meant to be rootless, but it will also work with root enabled (only keep root in docker if you **REALLY NEED**, otherwise make it rootless).

First, go to your SUDO user called `mysudouser` (assuming id 1000), and then we assume a worst case where you run your rootless docker firefox from another user called `mynonsudouser` (assuming id 1001), that does not support sudo.

```
# tested on Linux Ubuntu 22.04
#
# install commands newuidmap and newgidmap
sudo apt install uidmap  
# check identity 
id -u      # 1000
whoami # mysudouser
grep ^$(whoami): /etc/subuid
# mysudouser:100000:65536
#  =>  user must have 65536 sub UIDs
grep ^$(whoami): /etc/subgid
#  => group must have 65536 sub UIDs 
#
# more deps
sudo apt install dbus-user-session fuse-overlayfs
#
# ================================================================
#             Docker part (skip if you already have docker)
# see: https://docs.docker.com/engine/install/ubuntu/
# ================================================================
#
sudo apt remove docker docker.io containerd runc
# 
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg lsb-release
#
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#
cat /etc/apt/sources.list.d/docker.list
#
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

At this point, we make sure docker is rootless (if you have rootful docker, follow these steps to make it rootless):

```
#
# test OK
sudo docker run hello-world
# test FAIL (not rootless yet)
docker run hello-world
#
# ====================================
#        disable rootful docker
# ====================================
#
sudo systemctl disable --now docker.service docker.socket
#
curl -fsSL https://get.docker.com/rootless | sh
# get the export notes to put on your .bashrc
#
# export PATH=/home/mysudouser/bin:$PATH
# Some applications may require the following environment variable too:
# export DOCKER_HOST=unix:///run/user/1000/docker.sock
#
# enable docker
systemctl --user start docker
# begin automatically
systemctl --user enable docker
sudo loginctl enable-linger $(whoami)
# Should work OK rootless
docker run hello-world
```

If you have another sudo-less users, just repeat this part on the other users:

```
# ================================
# Go to real dev user (sudoless)
#   => login to other user
# ================================
curl -fsSL https://get.docker.com/rootless | sh
# add to .bashrc on nonsudo user
export PATH=/home/mynonsudouser/bin:$PATH
source ~/.bashrc
# Should work OK (download again the image)
docker run hello-world
```

#### If you also want docker-compose

```
# SUDO
sudo apt install python3-pip

# NO SUDO!
pip3 install docker-compose

# ADD TO .bashrc
# export PATH=/home/mynonrootuser/.local/bin:$PATH
```

### Finally: build and run your rootless firefox

1. Clone this repo! 
1. Go to `firefox-docker` folder and type `make` (or just `cd docker_build && ./build.sh`)
1. It will create an image for `youruser/firefox` (based on Ubuntu 20.04, not 22.04... but that's fine for now!)
    - Remember to update [dockerfile](firefox-docker/docker_build/dockerfile) with your specific nvidia GPU driver, or just remove the nvidia driver installation part (it is currently targetting `nvidia-driver-520`, but will certainly change in the future, pay attention to that!)
    - Audio will be provided by pulseaudio, which is also automatically installed in the image
1. Launch firefox, using the GPU or the non-GPU versions
    - 

#### How to access Downloads folder?

Now, firefox downloads will be located at `~/.config/firefox-docker/FirefoxDownloads`. You can bookmark it on Nautilus or create a symbolic link from the real Downloads folder.

Note that container is running on `root`, but since docker is rootless, it will automatically match root files with current user id.


## Install locally for the user

An easy way to install this locally:

1. put script `firefox-docker.sh` (or `firefox-gpu-docker.sh`) inside user folder `~/bin`
1. put `firefox-docker` folder inside user configs folder `~/.config`

Remember to fix these two lines on `firefox-docker.sh` and choose firefox `Downloads` and data folders:

```
  -v $HOME/.config/firefox-docker/FirefoxDownloads:/root/Downloads \
  -v $HOME/.config/firefox-docker/FirefoxData:/root/.mozilla/firefox/ \
```

### Advice to create an icon and favorite (on Ubuntu 22.04)

1. Copy the `firefox-docker.desktop` and icon on `desktop/` folder to `$HOME/.local/share/applications/`
1. Fix `$HOME` path in `desktop/firefox-docker.desktop`, if necessary
1. Fix the name in your language inside `.desktop` file (or just put some "Docker" prefix, to make sure it's the right icon)
1. Add to favorite:

```
$ cd desktop/
$ cp firefox-docker.desktop .local/share/applications/
$ cp firefox256.png .local/share/applications/
$ gsettings get org.gnome.shell favorite-apps
       # => ['org.gnome.Nautilus.desktop']
$ gsettings set org.gnome.shell favorite-apps "$(gsettings get org.gnome.shell favorite-apps | sed s/.$//), 'firefox-docker.desktop'
```


## License

MIT License (2022)

### Disclaimer

As usual: **use this at your own risk! no warranty**. Feel free to adapt and redistribute.

If it doesn't work, file an issue... it's experimental (didn't test in many computers/systems yet). 
Good luck!
