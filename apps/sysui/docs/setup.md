Setup
=====

## Authenticate

Go to your profile settings on Gerrit, select `HTTP Password > Obtain Password`,
and follow the instructions.


## Install Jiri

Jiri is built with Go, which needs to be available on your system.

```
curl -s https://raw.githubusercontent.com/fuchsia-mirror/jiri/master/scripts/bootstrap_jiri | bash -s /path/to/workspace/root
export PATH=/path/to/workspace/root/.jiri_root/scripts:$PATH
```


## Fetch the repo

```
cd /path/to/workspace/root
jiri import fuchsia https://fuchsia.googlesource.com/manifest
jiri update
cd apps/sysui
```


## Update your environment

```
source tools/environment.sh
```


## Fetch the dependencies

```
make sync=
```
