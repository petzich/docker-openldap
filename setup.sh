#!/bin/sh

# setup.sh script for post-installation schema and structure setup
echo "### Starting setup.sh ###"

# First fill some variables
export SLAPD_DOMAIN_PART=`echo ${SLAPD_ROOTDN} | awk -F"=|," -e '{print $2}'`
echo "INFO: \$SLAPD_DOMAIN_PART: $SLAPD_DOMAIN_PART"
variable_map="\$SLAPD_ROOTDN \$SLAPD_DOMAIN_PART \$SLAPD_SETUP_EXTRA_VARS"
echo "INFO: \$variable_map: $variable_map"

find_files(){
	all_files=$(find /setup -name *.ldif | sort)
	add_files=$(echo "${all_files}" | grep "add\.ldif")
	mod_files=$(echo "${all_files}" | grep "mod\.ldif")
	conf_add_files=$(echo "${add_files}" | grep "/setup/conf")
	conf_mod_files=$(echo "${mod_files}" | grep "/setup/conf")
	ldif_add_files=$(echo "${add_files}" | grep "/setup/ldif")
	ldif_mod_files=$(echo "${mod_files}" | grep "/setup/ldif")
}

find_files

# Replace variables in ldif files with values
echo "# Replacing variables in LDIF files #"
for f in $all_files; do
	if [ -f "$f" ]; then
		cp "$f" "$f.bak"
		echo "Replacing envs in $f"
		envsubst <"$f.bak" >"$f"
	fi
done

echo "# Applying ldif files to directory #"

if [ $1 = "conf" ]; then
	# Process conf add files
	for file in ${conf_add_files}; do
		if [ -f "$file" ]; then
			echo "==> $file"
			ldapadd -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f $file
		else
			echo "xxx $file is not a file. not processing"
		fi
	done

	# Process conf mod files
	for file in ${conf_mod_files}; do
		if [ -f "$file" ]; then
			echo "==> $file"
			ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f $file
		fi
	done

elif [ $1 == "ldif" ]; then

	# Process ldif add files
	for file in ${ldif_add_files}; do
		if [ -f "$file" ]; then
			echo "==> $file"
			ldapadd -x -D "cn=manager,${SLAPD_ROOTDN}" -w ${SLAPD_ROOTPW} -f $file
		fi
	done

	# Process ldif mod files
	for file in ${ldif_mod_files}; do
		if [ -f "$file" ]; then
			echo "==> $file"
			ldapmodify -x -D "cn=manager,${SLAPD_ROOTDN}" -w ${SLAPD_ROOTPW} -f $file
		fi
	done

else

	echo "No parameter passed to $0. You should pass either 'conf' or 'ldif'."

fi
