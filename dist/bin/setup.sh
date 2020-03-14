#!/bin/sh

# shellcheck source=dist/bin/_log.sh
. ./_log.sh

# setup.sh script for post-installation schema and structure setup
log "Starting with parameter: $1"

# First fill some variables
SLAPD_DOMAIN_PART=$(echo "${SLAPD_ROOTDN}" | awk -F"=|," -e '{print $2}')
export SLAPD_DOMAIN_PART
log "\$SLAPD_DOMAIN_PART: $SLAPD_DOMAIN_PART"

find_files() {
	all_files=$(find /setup -name "*.ldif" | sort)
	add_files=$(echo "${all_files}" | grep "add.ldif")
	mod_files=$(echo "${all_files}" | grep "mod.ldif")
	conf_files=$(echo "${all_files}" | grep "/setup/conf")
	ldif_files=$(echo "${all_files}" | grep "/setup/ldif")
	conf_add_files=$(echo "${add_files}" | grep "/setup/conf")
	conf_mod_files=$(echo "${mod_files}" | grep "/setup/conf")
	ldif_add_files=$(echo "${add_files}" | grep "/setup/ldif")
	ldif_mod_files=$(echo "${mod_files}" | grep "/setup/ldif")
}

replace_env_in_file() {
	f=${1}
	cp "$f" "$f.bak"
	log "Replacing envs in $f"
	envsubst <"$f.bak" >"$f"
}

replace_conf() {
	find_files
	for f in $conf_files; do
		replace_env_in_file "$f"
	done
}

replace_ldif() {
	find_files
	for f in $ldif_files; do
		replace_env_in_file "$f"
	done
}

log "Applying ldif files to directory"

if [ "$1" = "conf" ]; then
	replace_conf
	# Process conf add files
	for file in ${conf_add_files}; do
		if [ -f "$file" ]; then
			log "$file"
			ldapadd -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f "$file"
		else
			log "$file is not a file. not processing"
		fi
	done

	# Process conf mod files
	for file in ${conf_mod_files}; do
		if [ -f "$file" ]; then
			log "$file"
			ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f "$file"
		fi
	done

elif [ "$1" = "ldif" ]; then
	replace_ldif
	# Process ldif add files
	for file in ${ldif_add_files}; do
		if [ -f "$file" ]; then
			log "$file"
			ldapadd -x -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}" -f "$file"
		fi
	done

	# Process ldif mod files
	for file in ${ldif_mod_files}; do
		if [ -f "$file" ]; then
			log "$file"
			ldapmodify -x -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}" -f "$file"
		fi
	done

else

	log "No parameter passed to $0. You should pass either 'conf' or 'ldif'."

fi
