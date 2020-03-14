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

# Most tests require the daemon to be running.
# Wait for 1 second for the daemon to start.
/usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -d 256 &
sleep 1

cmd="slaptest"
testReturnCode "slaptest configuration check" 0 "$cmd"

cmd="ldapwhoami -h localhost -p 389 -D cn=manager,${SLAPD_ROOTDN} -w ${SLAPD_ROOTPW}"
testReturnCode "ldapwhoami - bind with root user" 0 "$cmd"

killall slapd
