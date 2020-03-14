#!/bin/sh

# Colour definitions
CRes='\e[0m'
CCya='\e[0;36m'
CGre='\e[0;32m'
CRed='\e[0;31m'

# Function to test return codes of commands
testReturnCode() {
	testname="ReturnCodeTest"
	name="$1"
	expected="$2"
	cmd="$3"
	# shellcheck disable=SC2039
	echo -e "$CCya [$0] [$testname] [$name] Starting $CRes"
	# The following has to be unquoted due to very sensitive expansion
	# shellcheck disable=SC2086
	$cmd
	rc="$?"
	if [ "$rc" -ne "$expected" ]; then
		# shellcheck disable=SC2039
		echo -e "$CCya [$0] [$testname] [$name] $CRed FAILED. Expected: $expected, Actual: $rc $CRes"
		exit 1
	else
		# shellcheck disable=SC2039
		echo -e "$CCya [$0] [$testname] [$name] $CGre SUCCEEDED $CRes"
	fi
}

# Function to test returned strings of commands
testStringCompare() {
	testname="StringCompare"
	name="$1"
	expected="$2"
	cmd="$3"
	grepfor="$4"
	# shellcheck disable=SC2039
	echo -e "$CCya [$0] [$testname] [$name] Starting $CRes"
	# The following has to be unquoted due to very sensitive expansion
	# shellcheck disable=SC2086
	actual=$($cmd | grep "$grepfor")
	if [ "$actual" != "$expected" ]; then
		# shellcheck disable=SC2039
		echo -e "$CCya [$0] [$testname] [$name] $CRed FAILED."
		echo "Expected: $expected"
		# shellcheck disable=SC2039
		echo -e "Actual:   $actual $CRes"
		exit 1
	else
		# shellcheck disable=SC2039
		echo -e "$CCya [$0] [$testname] [$name] $CGre SUCCEEDED $CRes"
	fi
}

# Most tests require the daemon to be running.
# Wait for 1 second for the daemon to start.
/usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -d 256 &
sleep 1

cmd="slaptest"
testReturnCode "slaptest configuration check" 0 "$cmd"

cmd="ldapwhoami -h localhost -p 389 -D cn=manager,${SLAPD_ROOTDN} -w ${SLAPD_ROOTPW}"
testReturnCode "ldapwhoami - root user" 0 "$cmd"

cmd="ldapwhoami -h localhost -p 389 -D uid=${FIRST_USER},ou=users,${SLAPD_ROOTDN} -w ${FIRST_USER_PASSWORD}"
testReturnCode "ldapwhoami - first user" 0 "$cmd"

cmd="ldapsearch -D uid=$FIRST_USER,ou=users,${SLAPD_ROOTDN} -w $FIRST_USER_PASSWORD -b $SLAPD_ROOTDN -LL (uid=$FIRST_USER) uid"
grepfor="uid:"
testStringCompare "ldapsearch uid" "uid: $FIRST_USER" "$cmd" "$grepfor"

cmd="ldapsearch -D uid=$FIRST_USER,ou=users,${SLAPD_ROOTDN} -w $FIRST_USER_PASSWORD -b $SLAPD_ROOTDN -LL (uid=$FIRST_USER) dn"
grepfor="dn:"
testStringCompare "ldapsearch dn" "dn: uid=$FIRST_USER,ou=users,$SLAPD_ROOTDN" "$cmd" "$grepfor"

killall slapd
