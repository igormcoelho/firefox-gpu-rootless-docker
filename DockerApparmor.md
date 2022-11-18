## Advice: using apparmor to constraint docker

Having docker rootless is nice, but it's even better if we can constrain its access the most.
For this, we need to install appamor.

The software apparmor is known for its simplicity of dealing with full path files (compared to SELinux), 
but still, it may break existing processes and give some trouble...
if you feel this is too hard (things not working anymore), just disable apparmor.

Let's go!

```
sudo apt install policycoreutils
sudo apt install apparmor-easyprof apparmor-notify apparmor-utils
sudo apt install auditd
```

Check that apparmor is enabled:

```
$ aa-enabled 
Yes
#
$ aa-status 
apparmor module is loaded.
You do not have enough privilege to read the profile set.
```

And to disable it, if necessary:

```
$ sudo aa-teardown
```


### Using a pre-written profile

You can simply use the profile I've created at file [apparmor-profile/home.mynonsudouser.bin.docker](./apparmor-profile/home.mynonsudouser.bin.docker)

```
cp apparmor-profile/home.mynonsudouser.bin.docker  home.RENAMETHISUSER.bin.docker
# take a look inside this file and rename the 'mynonsudouser' user to your user
# ...
#
sudo cp home.RENAMETHISUSER.bin.docker /etc/apparmor.d/
sudo apparmor_parser -r /etc/apparmor.d/home.RENAMETHISUSER.bin.docker 
```

Now, just make the file go to `enforce` mode:

```
sudo aa-enforce /home/RENAMETHISUSER/bin/docker
```

### Improving the rules with `aa-logprof`

If you have random/unexpected crashes, maybe you need to add more permissions... a quick fix is to move file back to `complain` mode:

```
sudo aa-complain /home/RENAMETHISUSER/bin/docker
```

Then, after a few more tests, you can try to add new permissions to it, using `aa-logprof`:

```
sudo aa-logprof
```

**WARNING**: for non-english users (like me), the `aa-logprof` app may break (see [issue 281](https://gitlab.com/apparmor/apparmor/-/issues/281)... thanks for cboltz and setharnold for the super quick fix).


Then, go back to enforce mode again:

```
sudo aa-enforce /home/RENAMETHISUSER/bin/docker
```

#### Understanding the permissions

Unfortunately, the process of managing a complex process like docker takes a lot of efforts and knowledge from apparmor.
And still, to the best of my knowledge, it is not possible to provide full security against unwanted access of local private files using apparmor (maybe selinux can do this, not apparmor).

The reason is that apparmor uses full paths, and since any volume could bind the folders and files to other names, these would not be covered by any rules, thus, easily accessible.
What we do here is a simple mechanism for avoiding **unintentional** exposure of secret user files inside docker...
note that a bad user could simply directly access the files, if access is granted to the host system anyway.
So, we solve this (unintentional and erroneous volume mounts) by blacklisting specific folders inside overlayfs (so we need to control both `docker` and `containerd` processes on apparmor, which is complex and not very efficient).

The important line is:

```
deny /.local/share/docker/fuse-overlayfs/*/diff/@{HOME}/Documents rw,
```

We provide AN EXAMPLE, carefully handmade using `aa-logprof`, but will likely break for different versions of docker, so this is kept for learning purposes only!
Take a look at the full profile [apparmor-profile/home.mynonsudouser.bin.docker](./apparmor-profile/home.mynonsudouser.bin.docker):

```
# Last Modified: Thu Nov 17 20:45:28 2022
include <tunables/global>

# vim:syntax=apparmor
# AppArmor policy for docker
# ###AUTHOR###
# ###COPYRIGHT###
# ###COMMENT###
# No template variables specified


/home/mynonsudouser/bin/containerd flags=(attach_disconnected, audit) {
  include <abstractions/base>
  include <abstractions/consoles>
  include <abstractions/opencl-pocl>

  capability,
  network,
  dbus,
  mount,
  remount,
  umount,
  signal,
  ptrace,
  pivot_root,
  unix,

  deny /.local/share/docker/fuse-overlayfs/*/diff/@{HOME}/Documents rw,

  /etc/** r,
  /etc/*/ld.so.cache r,
  /etc/*/modprobe.d/ r,
  /etc/*/modprobe.d/* r,
  @{HOME}/bin/containerd-shim-runc-v2 mrix,
  @{HOME}/bin/dockerd mrix,
  @{HOME}/bin/runc mrix,
  /proc/*/cgroup r,
  /proc/cmdline r,
  /proc/devices r,
  /run/dbus/system_bus_socket rw,
  /run/systemd/private rw,
  /sys/fs/cgroup/cgroup.controllers r,
  /sys/fs/cgroup/user.slice/cgroup.type r,
  /sys/fs/cgroup/user.slice/*/cgroup.type r,
  /sys/fs/cgroup/user.slice/*/*/cgroup.type r,
  /sys/kernel/mm/transparent_hugepage/hpage_pmd_size r,
  /usr/bin/bash mrix,
  /usr/bin/busctl mrix,
  /usr/bin/dircolors mrix,
  /usr/bin/groups mrix,
  /usr/bin/kmod mrix,
  /usr/bin/ls mrix,
  /usr/bin/touch mrix,
  owner /dev/pts/ptmx rw,
  owner /home/ r,
  owner /home/*/.local/share/docker/** r,
  owner /home/*/.local/share/docker/containerd/** k,
  owner /home/*/.local/share/docker/containerd/daemon/** rw,
  owner /home/*/.local/share/docker/containerd/daemon/*/ r,
  owner /home/*/.local/share/docker/fuse-overlayfs/** w,
  owner /home/*/.local/share/docker/fuse-overlayfs/**/ w,
  owner /home/*/bin/containerd r,
  owner /proc/*/cmdline r,
  owner /proc/*/comm r,
  owner /proc/*/fd/ r,
  owner /proc/*/loginuid r,
  owner /proc/*/mountinfo r,
  owner /proc/*/oom_score_adj r,
  owner /proc/*/oom_score_adj w,
  owner /proc/*/sessionid r,
  owner /proc/*/setgroups r,
  owner /proc/*/stat r,
  owner /proc/*/uid_map r,
  owner /proc/sys/net/ipv4/ip_unprivileged_port_start w,
  owner /root/.bash_history rw,
  owner /root/.bashrc r,
  owner /run/*/user/*/*/ w,
  owner /run/*/user/*/*/pty.sock rw,
  owner /run/*/user/*/docker/** rw,
  owner /run/*/user/*/docker/containerd/* rw,
  owner /run/*/user/*/docker/containerd/** w,
  owner /run/*/user/*/docker/containerd/**/ rw,
  owner /run/*/user/*/docker/containerd/containerd.toml r,
  owner /run/containerd/ w,
  owner /run/containerd/s/ w,
  owner /run/containerd/s/* rw,
  owner /run/user/*/bus rw,
  owner /sys/fs/cgroup/user.slice/*/*/cgroup.subtree_control w,
  owner /sys/fs/cgroup/user.slice/*/*/user.slice/** rw,

}

/home/mynonsudouser/bin/docker flags=(attach_disconnected, complain) {
  # 'abstractions/base' provides @{HOME} macro
  include <abstractions/base>

  deny @{HOME}/.bashrc rw,
  deny @{HOME}/.ssh/* rw,
  deny @{HOME}/.config/ rw,
  deny @{HOME}/Documents/ rw,
  deny @{HOME}/Pictures/ rw,
  deny @{HOME}/Private/ rw,
  deny @{HOME}/Videos/ rw,

  /etc/passwd r,
  /sys/kernel/mm/transparent_hugepage/hpage_pmd_size r,
  /usr/libexec/docker/cli-plugins/ r,
  owner /home/*/.docker/config.json r,
  owner /run/*/user/*/docker.sock rw,
  owner /home/*/.local/firefox-docker/** r,

}

```

Basically, it allows read accesses to some basic resources, such as `/etc/passwd`, as requested by docker on my `aa-logprof` rounds (without these, docker would break).
This line grants access to Firefox folder `owner /home/*/.local/firefox-docker/** r,`  

I don't know why it's only `r` access was generated by `aa-logprof`, instead of `rw`... 
but in fact, it's currently writing to it, since its mounted as another internal directory on container (which is **completely unprotected**).

The flag `attach_disconnected` seems quite crazy situation too (on `run/stuff...`), but it's really necessary: https://gitlab.com/apparmor/apparmor/-/issues/125

#### Note on security for sensitive files

Note that rules of AppArmor only apply to **FULL PATHS**...
it means that, to forbid something, you will need to specify the path inside all possible containers! 
Symbolic links can point to same thing in different paths, so these will also become unprotected (what usually happens to volumes inside containers).

If only a single `firefox-docker` is used by the user, then it's simple to constrain it,
but with multiple usages of `docker` for the same user, then it becomes challenging to block them all.

Some sensitive data, such as `.ssh/` folder can try to be protected, like this (good solution for simple programs, not docker):

```
  # default is 'deny', but we are paranoid people...
  deny @{HOME}/.config/ rw,
  deny @{HOME}/.ssh/ rw,
  deny @{HOME}/.bashrc rw,
```

But still, if one mounts it with another name, then it's completely unprotected inside the container:

```
# example 1 (file my_id_rsa is unprotected inside container)
docker run -v /home/mynonsudouser/.ssh/id_rsa:/root/my_id_rsa -it ubuntu /bin/bash
#
# example 2 (folder nossh is unprotected inside container)
docker run --mount type=bind,source=/home/mynonsudouser/.ssh,target=/root/nossh -it ubuntu /bin/bash
```

In these cases, to protect specific files, it may be much simpler to use SELinux instead of AppArmor.

### More information

One may understand more here: [Ubuntu - How to create an AppArmor Profile](https://ubuntu.com/tutorials/beginning-apparmor-profile-development#1-overview)

One may also inspect some logs on `/var/log/audit/audit.log`, to understand why something was Denied instead of Accepted. 

Good luck!
