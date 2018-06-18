#!/bin/sh

# setup.sh script for post-installation schema and structure setup
echo "### Starting setup.sh ###"

# First fill some variables
slapd_domain_part=`echo ${SLAPD_ROOTDN} | awk -F"=|," -e '{print $2}'`
echo "INFO: \$slapd_domain_part: $slapd_domain_part"
variable_map="SLAPD_ROOTDN slapd_domain_part ${SLAPD_SETUP_EXTRA_VARS}"
echo "INFO: \$variable_map: $variable_map"

find_files(){
	add_files=$(find /setup -name *.add.ldif | sort)
	mod_files=$(find /setup -name *.mod.ldif | sort)
	conf_add_files=$(echo "${add_files}" | grep "/setup/conf")
	conf_mod_files=$(echo "${mod_files}" | grep "/setup/conf")
	ldif_add_files=$(echo "${add_files}" | grep "/setup/ldif")
	ldif_mod_files=$(echo "${mod_files}" | grep "/setup/ldif")
	all_files=$(echo "${add_files}${mod_files}")
}

find_files

# Replace variables in ldif files with values
echo "# Replacing variables in LDIF files #"
for f in $all_files; do
	if [ -f "$f" ]; then
		for v in $variable_map; do
			eval var_val="\$$v"
			sed -i "s/##$v##/${var_val}/g" $f
		done
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
