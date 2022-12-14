## Dealing with security with SELinux

SELinux deals with the following structure:

```
allow <domain> <type>:<class> { <permissions> };
```

Where class can be `file` or `socket`; domain is the process; and type is the resource.

### Enable SELinux

First, disable AppArmor if existing.

```
systemctl status apparmor
# is it running? if so...
sudo systemctl stop apparmor
sudo systemctl disable apparmor
```

Install SELinux:

```
sudo apt install policycoreutils selinux-basics selinux-utils -y
sudo selinux-activate
# reboot ?
```

Data will be relabelled after reboot (few minutes...).

After return back:

```
$ getenforce
   # Permissive (or Disabled)
cat /etc/selinux/config
   # more info
$ sestatus
```

#### Play a little bit with SELinux

Go to permissive testing mode:

```
$  sudo setenforce 0
   # Permissive 
$  getenforce
```

Check audit logs:

```
cat /var/log/audit/audit.log
```

If EVERYTHING is fine, then go to enforce mode (beware of risks!):

**AGAIN, THIS WILL BREAK UBUNTU 22.04 SYSTEM!!**: https://serverfault.com/questions/1097613/ubuntu-20-04-doesnt-boot-after-setting-selinux-enforcing

```
$  sudo setenforce 1
$  getenforce
   # Enforcing
```

Go back to permissive, if necessary:

```
$  sudo setenforce 0
   # Permissive 
$  getenforce
```

#### About SELinux processes

Observing processes:

```
$ ps -eZ | grep auditd
system_u:system_r:kernel_t:s0        63 ?        00:00:00 kauditd
system_u:system_r:auditd_t:s0       987 ?        00:00:00 auditd
```

Get rule:

```
$ sesearch --allow --source auditd_t --target auditd_log_t --class file --perm write
allow auditd_t auditd_log_t:file { append create getattr ioctl link lock open read rename setattr unlink write };
```

Getting extended tags from files:

```
$ getfattr -m security.selinux -d /var/log/audit/audit.log
getfattr: Removing leading '/' from absolute path names
# file: var/log/audit/audit.log
security.selinux="system_u:object_r:auditd_log_t:s0"


$ ls -lZ /var/log/audit/audit.log
-rw-r-----. 1 root adm system_u:object_r:auditd_log_t:s0 1147573 nov 15 17:46 /var/log/audit/audit.log
```

#### GUI

```
$ sudo apt install policycoreutils-gui
```

### Time to use SELinux for firefox-docker

We apply standard labeling `xdg_data_t` for data at `~/.local/firefox-docker`:

```
chcon -R -t xdg_data_t ~/.local/firefox-docker
ls -lZ ~/.local/firefox-docker/
```

We apply standard labeling `xdg_config_t` for data at `~/.config/firefox-docker`:

```
chcon -R -t xdg_config_t ~/.config/firefox-docker
ls -lZ ~/.config/firefox-docker/
```

Note that Ubuntu 22.04 will likely break (specially gnome-shell) if you enable SELinux,
so for testing, one should use RHEL/Fedora distributions.



#### Dealing with secure folders

Note that ssh is already `ssh_home_t`:

```
$ ls -laZ ~/ | grep .ssh
drwx------.   2 mynonsudouser mynonsudouser system_u:object_r:ssh_home_t:s0       4096 nov 14 23:50 .ssh
```

This command runs fine:

```
docker run -v /home/mynonsudouser/.ssh:/root/.ssh hello-world
```

Special rules can be be created for confinement of docker process regarding secure files, disallowing its usage.
For path-based security, one can try AppArmor instead of SELinux (better for Ubuntu 22.04 systems, that does not work with SELinux).

#### If you really want to try on Ubuntu 22.04

- first: run on `setenforce 0` mode
- discover issues with critical stuff (such as graphical interface like gnome-shell), etc
- audit2why and audit2allow are your friends!

```
grep gnome /var/log/audit/audit.log | audit2why | grep "#" | sort | uniq 
  # setsebool -P allow_execmem 1
  # setsebool -P allow_execstack 1
  # setsebool -P xserver_gnome_xdm 1
```

Other general stuff, required on my short tests:

```
$ cat /var/log/audit/audit.log | audit2why | grep "#" | sort | uniq
  # setsebool -P allow_mount_anyfile 1
  # setsebool -P allow_polyinstantiation 1
  # setsebool -P authlogin_nsswitch_use_ldap 1
  # setsebool -P global_ssp 1
```

Execute these commands above to keep system working after enforcing.

To generate rules based on audit2allow, do the following:

```
sudo audit2allow -a -M mylist
# view list of rules
cat mylist.te
# if mylist.pp was not generated, fix (null) errors in mylist.te, then proceed
checkmodule -M -m -o mylist.mod mylist.te
# add the rules for selinux
sudo semodule -i mylist.pp 
```

On Ubuntu 22.04, remember to disable apparmor and snapd (which is very bad for user experience).
Regarding docker, if you really want to try it, use CentOS or Fedora, since they have official support for SELinux.


### More information

Read: 

- https://www.linode.com/docs/guides/how-to-install-selinux-on-ubuntu-22-04/
- `https://wiki.gentoo.org/wiki/SELinux/Tutorials/How_SELinux_controls_file_and_directory_accesses`
- https://teamignition.us/selinux-practical-intro-to-audit2why-and-audit2allow.html
- https://sysdig.com/blog/selinux-seccomp-falco-technical-discussion/

