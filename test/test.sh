#!/bin/sh

# Test configuration without daemon running
slaptest
rc="$?"
echo "rc is: $rc"
if [ "$rc" -ne 0 ]; then
	echo "slaptest failed"
	exit 1
fi

# The next tests require the daemon to be running.
# Wait for 1 second for the daemon to start.
/usr/sbin/slapd -u ldap -g ldap -F /etc/openldap/slapd.d -d 256 &
sleep 1

# Test binding with the root user
ldapwhoami -h localhost -p 389 -D "cn=manager,${SLAPD_ROOTDN}" -w "${SLAPD_ROOTPW}"
rc="$?"
echo "rc is: $rc"
if [ "$rc" -ne 0 ]; then
	echo "ldapwhoami failed"
	exit 1
fi

killall slapd
