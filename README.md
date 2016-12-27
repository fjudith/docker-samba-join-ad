# Introduction

Samba : the standard Windows interoperability suite of programs for Linux and Unix.
This container aims to run a Samba server registered as a member of a given Active Directory domain.

# Quick start
Run the Samba image.

> Replace <host ip address> by the local ip of the machine executing docker runtime.

```shell
docker run -it --rm --add-host "docker-smb.localdomain.loc docker-smb":<host ip address> \
--hostname docker-smb \
-e DOMAIN_NAME=localdomain.loc \
-e ADMIN_SERVER=dc1.localdomain.loc \
-e WORKGROUP=localdomain \
-e AD_USERNAME=Administrator \
-e AD_PASSWORD=V3rY1ns3cur3P4ssw0rd \
-p 137:137/udp \
-p 138:138/udp \
-p 139:139/tcp \
-p 445:445/tcp \
fjudith/samba-join-ad
```
