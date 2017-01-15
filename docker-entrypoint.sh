#! /bin/bash
# Reference:
# * https://wiki.debian.org/AuthenticatingLinuxWithActiveDirectory
# * https://wiki.samba.org/index.php/Troubleshooting_Samba_Domain_Members
# * http://www.oreilly.com/openbook/samba/book/ch04_08.html

set -e

GUEST_USERNAME=${GUEST_USERNAME:-ftp}
GUEST_PASSWORD=${GUEST_PASSWORD:-V3ry1nS3cur3P4ss0rd}

TZ=${TZ:-Etc/UTC}
# Update loopback entry
TZ=${TZ:-Etc/UTC}
AD_USERNAME=${AD_USERNAME:-administrator}
AD_PASSWORD=${AD_PASSWORD:-password}
HOSTNAME=${HOSTNAME:-$(hostname)}
IP_ADDRESS=${IP_ADDRESS:-}
DOMAIN_NAME=${DOMAIN_NAME:-domain.loc}
ADMIN_SERVER=${ADMIN_SERVER:-${DOMAIN_NAME,,}}
KDC_SERVER=${KDC_SERVER:-${ADMIN_SERVER,,}}
PASSWORD_SERVER=${PASSWORD_SERVER:-${ADMIN_SERVER,,}}

ENCRYPTION_TYPES=${ENCRYPTION_TYPES:-rc4-hmac des3-hmac-sha1 des-cbc-crc arcfour-hmac aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 des-cbc-md5}

SERVER_STRING=${SERVER_STRING:-Samba Server Version %v}
SECURITY=${SECURITY:-ads}
REALM=${REALM:-${DOMAIN_NAME^^}}
PASSWORD_SERVER=${PASSWORD_SERVER:-${DOMAIN_NAME,,}}
WORKGROUP=${WORKGROUP:-${DOMAIN_NAME^^}}
WINBIND_SEPARATOR=${WINBIND_SEPARATOR:-"\\"}
WINBIND_UID=${WINBIND_UID:-16777216-33554431}
WINBIND_GID=${WINBIND_GID:-16777216-33554431}
WINBIND_ENUM_USERS=${WINBIND_ENUM_USERS:-yes}
WINBIND_ENUM_GROUPS=${WINBIND_ENUM_GROUPS:-yes}
TEMPLATE_HOMEDIR=${TEMPLATE_HOMEDIR:-/home/%D/%U}
TEMPLATE_SHELL=${TEMPLATE_SHELL:-/bin/bash}
CLIENT_USE_SPNEGO=${CLIENT_USE_SPNEGO:-yes}
CLIENT_NTLMV2_AUTH=${CLIENT_NTLMV2_AUTH:-yes}
ENCRYPT_PASSWORDS=${ENCRYPT_PASSWORDS:-yes}
SERVER_SIGNING=${SERVER_SIGNING:-mandatory}
WINDBIND_USE_DEFAULT_DOMAIN=${WINBIND_USE_DEFAULT_DOMAIN:-yes}
RESTRICT_ANONYMOUS=${RESTRICT_ANONYMOUS:-2}
DOMAIN_MASTER=${DOMAIN_MASTER:-no}
LOCAL_MASTER=${LOCAL_MASTER:-no}
PREFERRED_MASTER=${PREFERRED_MASTER:-no}
OS_LEVEL=${OS_LEVEL:-0}
WINS_SUPPORT=${WINS_SUPPORT:-no}
WINS_SERVER=${WINS_SERVER:-127.0.0.1}
DNS_PROXY=${DNS_PROXY:-no}
LOG_LEVEL=${LOG_LEVEL:-1}
DEBUG_TIMESTAMP=${DEBUG_TIMESTAMP:-yes}
LOG_FILE=${LOG_FILE:-/var/log/samba/log.%m}
MAX_LOG_SIZE=${MAX_LOG_SIZE:-1000}
SYSLOG_ONLY=${SYSLOG_ONLY:-no}
SYSLOG=${SYSLOG:-0}
PANIC_ACTION=${PANIC_ACTION:-/usr/share/samba/panic-action %d}
HOSTS_ALLOW=${HOSTS_ALLOW:-*}
SOCKET_OPTIONS=${SOCKET_OPTIONS:-TCP_NODELAY SO_KEEPALIVE IPTOS_LOWDELAY}
READ_RAW=${READ_RAW:-yes}
WRITE_RAW=${WRITE_RAW:-yes}
OPLOCKS=${OPLOCKS:-no}
LEVEL2_OPLOCKS=${LEVEL2_OPLOCKS:-no}
KERNEL_OPLOCKS=${KERNEL_OPLOCKS:-yes}
MAX_XMIT=${MAX_XMIT:-65535}
DEAD_TIME=${DEAD_TIME:-15}

SAMBA_CONF=/etc/samba/smb.conf

# Setting Timezone 
echo $TZ | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata


# Initialize Kerberos authentication
if [[ ! -f /etc/krb5.conf.original ]]; then
	mv /etc/krb5.conf /etc/krb5.conf.original
fi
echo "
[logging]
    default = FILE:/var/krb5/kdc.log 
    kdc = FILE:/var/krb5/kdc.log 
    admin_server = FILE:/var/log/kadmind.log

[libdefaults]
	default_realm = ${DOMAIN_NAME^^}
    ticket_lifetime = 24h
    clock-skew = 300
    forwardable = true
#   default_tkt_enctypes = ${ENCRYPTION_TYPES}
#   default_tgs_enctypes = ${ENCRYPTION_TYPES}
#   dns_lookup_realm = false
#   dns_lookup_kdc = true

    ${DOMAIN_NAME^^} = {
        kdc = ${KDC_SERVER,,}:88
        admin_server = ${ADMIN_SERVER,,}:464
        default_domain = ${DOMAIN_NAME,,}       
}

    ${DOMAIN_NAME,,} = {
        kdc = ${KDC_SERVER,,}:88
        admin_server = ${ADMIN_SERVER,,}:464
        default_domain = ${DOMAIN_NAME,,}       
}

[domain_realm]
    .${DOMAIN_NAME,,} = ${DOMAIN_NAME^^}
    ${DOMAIN_NAME,,} = ${DOMAIN_NAME^^}

[kdc]
  profile = /etc/krb5kdc/kdc.conf

[appdefaults]
  pam = {
    debug = false
    ticket_lifetime = 36000
    renew_lifetime = 36000
    forwardable = true
    krb4_convert = false
}
" > /etc/krb5.conf

if [[ ! -f /etc/samba/smb.conf.original ]]; then
    mv /etc/samba/smb.conf /etc/samba/smb.conf.original
    touch $SAMBA_CONF
fi

echo --------------------------------------------------
echo "Setting up guest user credential: \"$GUEST_USERNAME\""
echo --------------------------------------------------
if [[ ! `grep $GUEST_USERNAME /etc/passwd` ]]; then
    useradd $GUEST_USERNAME
fi
echo $GUEST_PASSWORD | tee - | smbpasswd -a -s $GUEST_USERNAME

crudini --set $SAMBA_CONF global "guest account" "$GUEST_USERNAME"

crudini --set $SAMBA_CONF global "server string" "$SERVER_STRING"
crudini --set $SAMBA_CONF global "vfs objects" "acl_xattr"
crudini --set $SAMBA_CONF global "map acl inherit" "yes"
crudini --set $SAMBA_CONF global "store dos attributes" "yes"

crudini --set $SAMBA_CONF global "security" "$SECURITY"
crudini --set $SAMBA_CONF global "realm" "$REALM"
#crudini --set $SAMBA_CONF global "password server" "$PASSWORD_SERVER"
crudini --set $SAMBA_CONF global "workgroup" "$WORKGROUP"
#crudini --set $SAMBA_CONF global "winbind separator" "$WINBIND_SEPARATOR"
crudini --set $SAMBA_CONF global "winbind uid" "$WINBIND_UID"
crudini --set $SAMBA_CONF global "winbind gid" "$WINBIND_GID"
crudini --set $SAMBA_CONF global "winbind use default domain" "$WINDBIND_USE_DEFAULT_DOMAIN"
crudini --set $SAMBA_CONF global "winbind enum users" "$WINBIND_ENUM_USERS"
crudini --set $SAMBA_CONF global "winbind enum groups" "$WINBIND_ENUM_GROUPS"
crudini --set $SAMBA_CONF global "template homedir" "$TEMPLATE_HOMEDIR"
crudini --set $SAMBA_CONF global "template shell" "$TEMPLATE_SHELL"
crudini --set $SAMBA_CONF global "client use spnego" "$CLIENT_USE_SPNEGO"
crudini --set $SAMBA_CONF global "client ntlmv2 auth" "$CLIENT_NTLMV2_AUTH"
crudini --set $SAMBA_CONF global "encrypt passwords" "$ENCRYPT_PASSWORDS"
crudini --set $SAMBA_CONF global "server signing" "$SERVER_SIGNING"
crudini --set $SAMBA_CONF global "restrict anonymous" "$RESTRICT_ANONYMOUS"
crudini --set $SAMBA_CONF global "domain master" "$DOMAIN_MASTER"
crudini --set $SAMBA_CONF global "local master" "$LOCAL_MASTER"
crudini --set $SAMBA_CONF global "preferred master" "$PREFERRED_MASTER"
crudini --set $SAMBA_CONF global "os level" "$OS_LEVEL"
crudini --set $SAMBA_CONF global "wins support" "$WINS_SUPPORT"
crudini --set $SAMBA_CONF global "wins server" "$WINS_SERVER"
crudini --set $SAMBA_CONF global "dns proxy" "$DNS_PROXY"
crudini --set $SAMBA_CONF global "log level" "$LOG_LEVEL"
crudini --set $SAMBA_CONF global "debug timestamp" "$DEBUG_TIMESTAMP"
crudini --set $SAMBA_CONF global "log file" "$LOG_FILE"
crudini --set $SAMBA_CONF global "max log size" "$MAX_LOG_SIZE"
crudini --set $SAMBA_CONF global "syslog only" "$SYSLOG_ONLY"
crudini --set $SAMBA_CONF global "syslog" "$SYSLOG"
crudini --set $SAMBA_CONF global "panic action" "$PANIC_ACTION"
crudini --set $SAMBA_CONF global "hosts allow" "$HOSTS_ALLOW"
crudini --set $SAMBA_CONF global "socket options" "$SOCKET_OPTIONS"
crudini --set $SAMBA_CONF global "read raw" "$READ_RAW"
crudini --set $SAMBA_CONF global "write raw" "$WRITE_RAW"
crudini --set $SAMBA_CONF global "oplocks" "$OPLOCKS"
crudini --set $SAMBA_CONF global "level2 oplocks" "$LEVEL2_OPLOCKS"
crudini --set $SAMBA_CONF global "kernel oplocks" "$KERNEL_OPLOCKS"
crudini --set $SAMBA_CONF global "max xmit" "$MAX_XMIT"
crudini --set $SAMBA_CONF global "dead time" "$DEAD_TIME"


# Disable printing error log messages when CUPS is not installed.
crudini --set $SAMBA_CONF global "printcap name" "/etc/printcap"
crudini --set $SAMBA_CONF global "panic action" "no"

# Works both in samba 3.2 and 3.6.
#crudini --set $SAMBA_CONF global "idmap backend" "tdb"
#crudini --set $SAMBA_CONF global "idmap uid" "$WINBIND_UID"
#crudini --set $SAMBA_CONF global "idmap gid" "$WINBIND_GID"

# no .tld
crudini --set $SAMBA_CONF global "idmap config ${WORKGROUP^^}:backend" "rid"
crudini --set $SAMBA_CONF global "idmap config ${WORKGROUP^^}:range" "$WINBIND_UID"

# Inherit groups in groups
crudini --set $SAMBA_CONF global "winbind nested groups" "yes"
crudini --set $SAMBA_CONF global "winbind refresh tickets" "yes"
crudini --set $SAMBA_CONF global "winbind offline logon" "true"

# No shell access
crudini --set $SAMBA_CONF global "template shell" "/bin/false"
crudini --set $SAMBA_CONF global "client use spnego" "yes"
crudini --set $SAMBA_CONF global "client ntlmv2 auth" "yes"
crudini --set $SAMBA_CONF global "encrypt passwords" "yes"
crudini --set $SAMBA_CONF global "restrict anonymous" "2"


crudini --set $SAMBA_CONF home "comment" "Home Directories"
crudini --set $SAMBA_CONF home "path" "/home/"
crudini --set $SAMBA_CONF home "public" "yes"
crudini --set $SAMBA_CONF home "guest ok" "no"
crudini --set $SAMBA_CONF home "read only" "no"
crudini --set $SAMBA_CONF home "writeable" "yes"
crudini --set $SAMBA_CONF home "create mask" "0777"
crudini --set $SAMBA_CONF home "directory mask" "0777"
crudini --set $SAMBA_CONF home "browseable" "no"
crudini --set $SAMBA_CONF home "printable" "no"
crudini --set $SAMBA_CONF home "oplocks" "yes"


# Update nsswitch.conf with Winbind
sed -i "s#^\(passwd\:\s*compat\)\$#\1 winbind#" /etc/nsswitch.conf
sed -i "s#^\(group\:\s*compat\)\$#\1 winbind#" /etc/nsswitch.conf
sed -i "s#^\(shadow\:\s*compat\)\$#\1 winbind#" /etc/nsswitch.conf

/etc/init.d/winbind stop
/etc/init.d/samba restart
/etc/init.d/winbind start

sleep 5

testparm -s

echo --------------------------------------------------
echo 'Generating Kerberos ticket'
echo --------------------------------------------------
echo $AD_PASSWORD | kinit $AD_USERNAME@$REALM
klist

echo --------------------------------------------------
echo 'Regestering to Active Directory'
echo --------------------------------------------------
net ads join -U $AD_USERNAME%$AD_PASSWORD
/etc/init.d/winbind stop
/etc/init.d/samba restart
/etc/init.d/winbind start
wbinfo --ping-dc
pam-auth-update

echo --------------------------------------------------
echo 'Stopping Samba to enable handling by supervisord'
echo --------------------------------------------------
/etc/init.d/winbind stop
/etc/init.d/samba stop

echo --------------------------------------------------
echo 'Restarting Samba using supervisord'
echo --------------------------------------------------
/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf