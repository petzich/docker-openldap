#!/bin/sh

# entrypoint.sh for petzi/openldap

# shellcheck source=dist/bin/_log.sh
. ./_log.sh

log "Starting"

check_env() {
	if [ -z "$SLAPD_ROOTDN" ]; then
		log_fatal "SLAPD_ROOTDN not set. " >&2
		exit 1
	fi
	if [ -z "$SLAPD_ROOTPW" ]; then
		log_fatal "SLAPD_ROOTPW not set. " >&2
		exit 1
	fi
}

create_dirs() {
	log "Creating slapd.d"
	mkdir /etc/openldap/slapd.d
	log "Creating slapi socket"
	mkdir /var/run/openldap
	touch /var/run/openldap/slapi
	log "Creating openldap data directory"
	mkdir /var/lib/openldap/openldap-data
}

set_permission() {
	log "Setting permissions on files and directories"
	chmod 750 /etc/openldap/slapd.d
	chown ldap:ldap /var/run/openldap/slapi
	chown ldap:ldap /var/lib/openldap/openldap-data
}

generate_slapd_ldif() {
	generated_file="/setup/slapd.dist/slapd.generated.ldif"
	include_files="core.ldif dyngroup.ldif cosine.ldif inetorgperson.ldif openldap.ldif corba.ldif pmi.ldif ppolicy.ldif misc.ldif nis.ldif"
	log "Generating $generated_file"
	config_rootpw_hash=$(slappasswd -s "${SLAPD_ROOTPW}")
	export config_rootpw_hash
	cp /setup/slapd.dist/pre-include.ldif "$generated_file"
	for i in $include_files; do
		echo "include: file:///etc/openldap/schema/$i" >>"$generated_file"
		echo "" >>"$generated_file"
	done
	cat /setup/slapd.dist/post-include.ldif >>"$generated_file"
	./ldif.sh replace_env
}

apply_slapd_ldif() {
	log "Applying $generated_file"
	/usr/sbin/slapadd -n 0 -F /etc/openldap/slapd.d -l "$generated_file"
}

apply_conf() {
	# As the standard configuration generates a "no-one allowed" rule
	# on (olcDatabase=config,cn=config) we need to hard-overwrite
	# this value to allow the local root user SASL-access to cn=config.
	# And after that fix the checksum of the file.
	config_db_file="/etc/openldap/slapd.d/cn=config/olcDatabase={0}config.ldif"
	old_olc_access=$(grep "^olcAccess:" "$config_db_file")
	sed -i 's/^olcAccess:.*$/olcAccess: to dn.subtree="cn=config" by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" manage by users read by * none/g' $config_db_file

	chown -R ldap:ldap /etc/openldap/slapd.d/
	exec /usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -h ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi &
	sleep 1
	./ldif.sh conf
	killall slapd
	sleep 1

	# Reset old olcAccess on config file
	log "Writing back original olcAccess rule: $old_olc_access"
	sed -i "s/^olcAccess.*$/$old_olc_access/g" $config_db_file
}

apply_rootdn() {
	chown -R ldap:ldap /etc/openldap/slapd.d/
	exec /usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d &
	sleep 1
	./ldif.sh ldif
	killall slapd
	sleep 1
}

phase_init() {
	log "Starting phase [init]"
	check_env
	create_dirs
	set_permission
	generate_slapd_ldif
	apply_slapd_ldif
	apply_conf
	apply_rootdn
	log "Leaving phase [init]"
}

phase_always() {
	log "Starting phase [always]"
	set_permission
	log "Leaving phase [always]"
}

if [ ! -d /etc/openldap/slapd.d ]; then
	phase_init
fi

phase_always

log "Starting slapd."
log "Command: $*"
exec "$@"
