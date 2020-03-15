#!/bin/sh

# shellcheck source=dist/bin/_log.sh
. ./_log.sh

# ldif.sh script for post-installation schema and structure setup
log "Starting with parameter: $1"

# First fill some variables
SLAPD_DOMAIN_PART=$(echo "${SLAPD_ROOTDN}" | awk -F"=|," -e '{print $2}')
export SLAPD_DOMAIN_PART
log "\$SLAPD_DOMAIN_PART: $SLAPD_DOMAIN_PART"

find_ldif_files() {
	all_files=$(find /setup -name "*.ldif" | sort)
	add_files=$(echo "${all_files}" | grep "add.ldif")
	mod_files=$(echo "${all_files}" | grep "mod.ldif")
	conf_add_files=$(echo "${add_files}" | grep "/setup/conf")
	conf_mod_files=$(echo "${mod_files}" | grep "/setup/conf")
	rootdn_add_files=$(echo "${add_files}" | grep "/setup/rootdn")
	rootdn_mod_files=$(echo "${mod_files}" | grep "/setup/rootdn")
}

replace_env_in_ldif() {
	f=${1}
	cp "$f" "$f.bak"
	log "Replacing envs in $f"
	envsubst <"$f.bak" >"$f"
}

replace_env_in_all_ldif() {
	find_ldif_files
	for f in $all_files; do
		replace_env_in_ldif "$f"
	done
}

conf_add() {
	file="$1"
	if [ -f "$file" ]; then
		log "$file"
		ldapadd -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f "$file"
	else
		log "$file is not a file. not processing"
	fi
}

conf_mod() {
	file="$1"
	if [ -f "$file" ]; then
		log "$file"
		ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f "$file"
	fi
}

rootdn_add() {
	file="$1"
	if [ -f "$file" ]; then
		log "$file"
		ldapadd -x -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}" -f "$file"
	fi
}

rootdn_mod() {
	file="$1"
	if [ -f "$file" ]; then
		log "$file"
		ldapmodify -x -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}" -f "$file"
	fi
}

if [ "$1" = "replace_env" ]; then
	log "Replacing variables in all ldif files"
	replace_env_in_all_ldif
elif [ "$1" = "conf" ]; then
	find_ldif_files
	log "Processing conf_add_files"
	for file in ${conf_add_files}; do
		conf_add "$file"
	done
	log "Processing conf_mod_files"
	for file in ${conf_mod_files}; do
		conf_mod "$file"
	done
elif [ "$1" = "ldif" ]; then
	find_ldif_files
	log "Processing rootdn_add_files"
	for file in ${rootdn_add_files}; do
		rootdn_add "$file"
	done
	log "Processing rootdn_mod_files"
	for file in ${rootdn_mod_files}; do
		rootdn_mod "$file"
	done
else

	log "No parameter passed to $0. You should pass either 'replace_env', 'conf' or 'ldif'."

fi
