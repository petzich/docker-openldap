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

	include_files="dyngroup.ldif cosine.ldif inetorgperson.ldif openldap.ldif corba.ldif pmi.ldif ppolicy.ldif misc.ldif nis.ldif"

	### This is used for sed breaklines
	sed_break=$'\\\n'

	### Define the files to include
	include_lines=""
	for i in $include_files; do
		include_lines="${include_lines}${sed_break}include: file:///etc/openldap/schema/${i}"
	done

	config_rootpw_hash=$(slappasswd -s "${SLAPD_ROOTPW}")
	echo "$SLAPD_ROOTPW" >/slapd_config_rootpw
	chmod 400 /slapd_config_rootpw

	# Copy the sample file to edit
	generated_file="/etc/openldap/slapd.ldif.generated"
	cp /etc/openldap/slapd.ldif $generated_file
	sed -i "s/^olcSuffix.*$/olcSuffix: ${SLAPD_ROOTDN}/g" $generated_file
	sed -i "s/^olcRootDN.*$/olcRootDN: cn=manager,${SLAPD_ROOTDN}/g" $generated_file
	# In the following sed statement, special characters are used to deal with slashes in hashed passwords
	sed -i "s|^olcRootPW.*$|olcRootPW: ${config_rootpw_hash}|g" $generated_file
	# PID and ARG file is not required for docker container
	sed -i "/^olcPidFile.*$/d" $generated_file
	sed -i "/^olcArgsFile.*$/d" $generated_file
	# Remove empty lines and comment lines
	sed -i "/^\s*$/d" $generated_file
	sed -i "/^#.*$/d" $generated_file
	# For proper parsing, insert an empty line before lines beginning with "dn: "
	sed -i "/^dn\:/i${sed_break}" $generated_file
	# Add the include_lines to the file
	sed -i "/^include\:/a ${include_lines}" $generated_file
	# An empty line before each include statement
	sed -i "/^include\:/i${sed_break}" $generated_file

	echo "Generating configuration"
	/usr/sbin/slapadd -n 0 -F /etc/openldap/slapd.d -l /etc/openldap/slapd.ldif.generated

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
