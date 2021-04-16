#!/bin/bash

export LC_ALL=en_US.UTF-8
#export LC_ALL="$LOC"

[ -d /usr/share/X11/locale/en_US.UTF-8 ] && export LC_ALL=en_US.UTF-8


DOMAIN=$1

sudo dpkg --configure -a
echo "slapd slapd/password1 password admin"                                 >  /root/debconf-slapd.conf
echo "slapd slapd/internal/adminpw password admin"                          >> /root/debconf-slapd.conf
echo "slapd slapd/internal/generated_adminpw password admin"                >> /root/debconf-slapd.conf
echo "slapd slapd/password2 password admin"                                 >> /root/debconf-slapd.conf
echo "slapd slapd/unsafe_selfwrite_acl note"                                >> /root/debconf-slapd.conf
echo "slapd slapd/purge_database boolean false"                             >> /root/debconf-slapd.conf
echo "slapd slapd/domain string $DOMAIN"                                    >> /root/debconf-slapd.conf
echo "slapd slapd/ppolicy_schema_needs_update select abort installation"    >> /root/debconf-slapd.conf
echo "slapd slapd/invalid_config boolean true"                              >> /root/debconf-slapd.conf
echo "slapd slapd/move_old_database boolean false"                          >> /root/debconf-slapd.conf
echo "slapd slapd/backend select MDB"                                       >> /root/debconf-slapd.conf
echo "slapd shared/organization string VMware"                              >> /root/debconf-slapd.conf
echo "slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION"  >> /root/debconf-slapd.conf
echo "slapd slapd/no_configuration boolean false"                           >> /root/debconf-slapd.conf
echo "slapd slapd/dump_database select when needed"                         >> /root/debconf-slapd.conf
echo "slapd slapd/password_mismatch note"                                   >> /root/debconf-slapd.conf

export DEBIAN_FRONTEND=noninteractive
cat /root/debconf-slapd.conf | debconf-set-selections
apt install ldap-utils slapd -y

cp /home/ubuntu/tanzu-demo-hub/certificates/*.pem /etc/ssl/private
chmod 600 /etc/ssl/private/privkey.pem

echo "dn: cn=config"                                                         >  /root/add_ssl.ldif
echo "changetype: modify"                                                    >> /root/add_ssl.ldif
echo "replace: olcTLSCACertificateFile"                                      >> /root/add_ssl.ldif
echo "olcTLSCACertificateFile: /etc/ssl/private/fullchain.pem"               >> /root/add_ssl.ldif
echo "-"                                                                     >> /root/add_ssl.ldif
echo "replace: olcTLSCertificateFile"                                        >> /root/add_ssl.ldif
echo "olcTLSCertificateFile: /etc/ssl/private/cert.pem"                      >> /root/add_ssl.ldif
echo "-"                                                                     >> /root/add_ssl.ldif
echo "replace: olcTLSCertificateKeyFile"                                     >> /root/add_ssl.ldif
echo "olcTLSCertificateKeyFile: /etc/ssl/private/privkey.pem"                >> /root/add_ssl.ldif

setfacl -m "u:openldap:r" /etc/ssl/private/{fullchain,cert,privkey}.pem
chown -R openldap /etc/ssl/private

ldapmodify -Y EXTERNAL -H ldapi:/// -f /root/add_ssl.ldif 
systemctl restart slapd

#ldapwhoami -H ldap://jump-aztkg.aztkg.pcfsdu.com -x -ZZ

exit

