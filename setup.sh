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
	conf_add_files=$(${add_files} | grep "/setup/conf")
	conf_mod_files=$(${mod_files} | grep "/setup/conf")
	ldif_add_files=$(${add_files} | grep "/setup/ldif")
	ldif_mod_files=$(${mod_files} | grep "/setup/ldif")
}

find_files

echo "[DEBUG] \$add_files:"
echo "$add_files"
echo "[DEBUG] \$mod_files:"
echo "$mod_files"

# Replace variables in ldif files with values
echo "# Replacing variables in LDIF files #"
for f in $ldif_files; do
	for v in $variable_map; do
		eval var_val="\$$v"
		sed -i "s/##$v##/${var_val}/g" $f
	done
done

echo "# Applying ldif files to directory #"

if [ $1 = "conf" ]; then
	# Process conf add files
	for f in "${conf_add_files}"; do
	    echo "==> $f"
	    ldapadd -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f $f
	done

	# Process conf mod files
	for f in "${conf_mod_files}"; do
	    echo "==> $f"
	    ldapmodify -Q -Y EXTERNAL -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi -f $f
	done

elif [ $1 == "ldif" ]; then

	# Process ldif add files
	for f in "${ldif_add_files}"; do
	    echo "==> $f"
	    ldapadd -x -D "cn=manager,${SLAPD_ROOTDN}" -w ${SLAPD_ROOTPW} -f $f
	done

	# Process ldif mod files
	for f in "${ldif_mod_files}"; do
	    echo "==> $f"
	    ldapmodify -x -D "cn=manager,${SLAPD_ROOTDN}" -w ${SLAPD_ROOTPW} -f $f
	done

else

	echo "No parameter passed to $0. You should pass either 'conf' or 'ldif'."

fi
