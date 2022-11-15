
## Advice: installing rootless docker 

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