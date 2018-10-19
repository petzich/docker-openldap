#!/bin/sh

# entrypoint.sh for petzi/openldap

echo "Starting entrypoint.sh"
echo "Command passed to entrypoint.sh:"
echo "    $*"
echo "Command without arguments:"
echo "    $1"

if [ ! -d /etc/openldap/slapd.d ]; then
	echo "SLAPD_ROOTDN = $SLAPD_ROOTDN"
	if [ -z "$SLAPD_ROOTDN" ]; then
		echo "Error: SLAPD_ROOTDN not set. " >&2
		exit 1
	fi
	if [ -z "$SLAPD_ROOTPW" ]; then
		echo "Error: SLAPD_ROOTPW not set. " >&2
		exit 1
	fi

	echo "Creating slapd.d"
	mkdir /etc/openldap/slapd.d
	chmod 750 /etc/openldap/slapd.d

	echo "Creating slapi socket"
	mkdir /var/run/openldap
	touch /var/run/openldap/slapi
	chown ldap:ldap /var/run/openldap/slapi

	echo "Creating openldap data directory"
	mkdir /var/lib/openldap/openldap-data
	chown ldap:ldap /var/lib/openldap/openldap-data

	include_files="core.ldif dyngroup.ldif cosine.ldif inetorgperson.ldif openldap.ldif corba.ldif pmi.ldif ppolicy.ldif misc.ldif nis.ldif"
	config_rootpw_hash=$(slappasswd -s "${SLAPD_ROOTPW}")
	export config_rootpw_hash

	# Assemble the slapd.ldif file
	generated_file="/etc/openldap/slapd.ldif.generated"
	cp /setup/slapd.ldif/pre-include.ldif "$generated_file.orig"
	for i in $include_files; do
		echo "include: file:///etc/openldap/schema/$i" >> "$generated_file.orig"
		echo "" >> "$generated_file.orig"
	done
	cat /setup/slapd.ldif/post-include.ldif >> "$generated_file.orig"
	envsubst <"$generated_file.orig" >"$generated_file"

	echo "Generating configuration"
	/usr/sbin/slapadd -n 0 -F /etc/openldap/slapd.d -l "$generated_file"

	# As the standard configuration generates a "no-one allowed" rule
	# on (olcDatabase=config,cn=config) we need to hard-overwrite
	# this value to allow the local root user SASL-access to cn=config.
	config_db_file="/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif"
	sed -i 's/^olcAccess:.*$/olcAccess: to dn.subtree="cn=config" by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by users read by * none/g' $config_db_file

	chown -R ldap:ldap /etc/openldap/slapd.d/
	echo "Starting setup.sh conf"
	exec /usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -h ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi &
	sleep 1
	./setup.sh conf
	killall slapd
	sleep 1

	chown -R ldap:ldap /etc/openldap/slapd.d/
	echo "Starting setup.sh ldif"
	exec /usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d &
	sleep 1
	./setup.sh ldif
	killall slapd
	sleep 1

fi

echo "Starting slapd."
exec "$@"
