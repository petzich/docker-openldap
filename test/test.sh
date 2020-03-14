#!/bin/sh

# Most tests require the daemon to be running.
# Wait for 1 second for the daemon to start.
/usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -d 256 &
sleep 1

testReturnCode() {
	testname="ReturnCodeTest"
	name="$1"
	expected="$2"
	cmd="$3"
	echo "[$0] [$testname] [$name] Starting - command: $cmd"
	# The following has to be unquoted due to very sensitive expansion
	# shellcheck disable=SC2086
	$cmd
	rc="$?"
	if [ "$rc" -ne "$expected" ]; then
		echo "[$0] [$testname] [$name] FAILED. Expected: $expected, Actual: $rc"
		exit 1
	else
		echo "[$0] [$testname] [$name] SUCCEEDED"
	fi
}

cmd="slaptest"
testReturnCode "slaptest configuration check" 0 "$cmd"

cmd="ldapwhoami -h localhost -p 389 -D cn=manager,${SLAPD_ROOTDN} -w ${SLAPD_ROOTPW}"
testReturnCode "ldapwhoami - bind with root user" 0 "$cmd"

killall slapd
