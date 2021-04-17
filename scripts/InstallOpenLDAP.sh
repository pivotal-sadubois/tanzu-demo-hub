#!/bin/bash

export LC_ALL=en_US.UTF-8
#export LC_ALL="$LOC"

[ -d /usr/share/X11/locale/en_US.UTF-8 ] && export LC_ALL=en_US.UTF-8


DOMAIN=$1
LDAP_DOMAIN=$(echo $DOMAIN | awk -F'.' '{ for (i = 1; i <= 3; i++) { printf(",dc=%s",$i) }}END { printf "\n"}' | sed 's/^,//g')
JUMP_HOST_IP=$(getent hosts jump.$DOMAIN | awk '{ print $1 }')
echo "LDAP_DOMAIN:$LDAP_DOMAIN"
echo "JUMP_HOST_IP:$JUMP_HOST_IP"

echo gaga1
dpkg --configure -a
echo gaga2
echo "slapd slapd/password1 password admin"                                 >  /root/debconf-slapd.conf
echo "slapd slapd/internal/adminpw password tanzudemohub"                   >> /root/debconf-slapd.conf
echo "slapd slapd/internal/generated_adminpw password admin"                >> /root/debconf-slapd.conf
echo "slapd slapd/password2 password tanzudemohub"                          >> /root/debconf-slapd.conf
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
echo gaga3

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


echo gaga4
# --- INSTALL phpldapadmin ---
apt autoremove -y
echo gaga5
apt install phpldapadmin -y 
echo gaga6

echo "?php"                                                                        >  /etc/phpldapadmin/config.php
echo "\$config->custom->appearance['timezone'] = 'Europe/Zurich';"                  >> /etc/phpldapadmin/config.php
echo "\$config->custom->appearance['friendly_attrs'] = array("                      >> /etc/phpldapadmin/config.php
echo "        'facsimileTelephoneNumber' => 'Fax',"                                >> /etc/phpldapadmin/config.php
echo "        'gid'                      => 'Group',"                              >> /etc/phpldapadmin/config.php
echo "        'mail'                     => 'Email',"                              >> /etc/phpldapadmin/config.php
echo "        'telephoneNumber'          => 'Telephone',"                          >> /etc/phpldapadmin/config.php
echo "        'uid'                      => 'User Name',"                          >> /etc/phpldapadmin/config.php
echo "        'userPassword'             => 'Password'"                            >> /etc/phpldapadmin/config.php
echo ");"                                                                          >> /etc/phpldapadmin/config.php
echo ""                                                                            >> /etc/phpldapadmin/config.php
echo "\$servers = new Datastore();"                                                 >> /etc/phpldapadmin/config.php
echo "\$servers->newServer('ldap_pla');"                                            >> /etc/phpldapadmin/config.php
echo "\$servers->setValue('server','name','Tanzu-Demo-Hub LDAP Server');"           >> /etc/phpldapadmin/config.php
echo "\$servers->setValue('server','host','$JUMP_HOST_IP');"                       >> /etc/phpldapadmin/config.php
echo "\$servers->setValue('server','base',array('$LDAP_DOMAIN'));"     >> /etc/phpldapadmin/config.php
echo "\$servers->setValue('login','auth_type','session');"                          >> /etc/phpldapadmin/config.php
echo "\$config->custom->appearance['hide_template_warning'] = true;"                >> /etc/phpldapadmin/config.php
echo "?>"                                                                          >> /etc/phpldapadmin/config.php


exit

