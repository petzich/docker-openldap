#!/bin/sh

# shellcheck source=dist/bin/_log.sh
. ./_log.sh

# ldif.sh script for post-installation schema and structure setup
log "Called with parameters: $*"

find_ldif_files() {
	all_files=$(find /setup -name "*.ldif" | sort)
	init_conf_files=$(echo "${all_files}" | grep "/setup/init/conf")
	init_rootdn_files=$(echo "${all_files}" | grep "/setup/init/rootdn")
}

replace_env_in_ldif() {
	f=${1}
	if [ ! -e "$f.orig" ]; then
		cp "$f" "$f.orig"
	fi
	envsubst <"$f.orig" >"$f"
}

replace_env_in_all_ldif() {
	find_ldif_files
	for f in $all_files; do
		replace_env_in_ldif "$f"
	done
}

conf_mod() {
	file="$1"
	if [ -f "$file" ]; then
		ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f "$file"
	else
		log "$file is not a file. not processing"
	fi
}

rootdn_mod() {
	file="$1"
	if [ -f "$file" ]; then
		ldapmodify -x -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}" -f "$file"
	else
		log "$file is not a file. not processing"
	fi
}

if [ "$1" = "replace_env" ]; then
	log "Replacing variables in all ldif files"
	replace_env_in_all_ldif
elif [ "$1" = "conf" ]; then
	find_ldif_files
	log "Processing init_conf_files"
	for file in ${init_conf_files}; do
		conf_mod "$file"
	done
elif [ "$1" = "ldif" ]; then
	find_ldif_files
	log "Processing init_rootdn_files"
	for file in ${init_rootdn_files}; do
		rootdn_mod "$file"
	done
else

	log "No parameter passed to $0. You should pass either 'replace_env', 'conf' or 'ldif'."

fi
