#!/bin/sh

# entrypoint library functions for petzi/openldap

# shellcheck source=dist/bin/_log.sh
. ./_log.sh

# Check environment setting
check_env() {
	log "Checking environment variables"
	if [ -z "$SLAPD_ROOTDN" ]; then
		log_fatal "SLAPD_ROOTDN not set. " >&2
		exit 1
	fi
	if [ -z "$SLAPD_ROOTPW" ]; then
		log_fatal "SLAPD_ROOTPW not set. " >&2
		exit 1
	fi
	SLAPD_DOMAIN_PART=$(echo "${SLAPD_ROOTDN}" | awk -F"=|," -e '{print $2}')
	export SLAPD_DOMAIN_PART
	log "Calculated SLAPD_DOMAIN_PART: $SLAPD_DOMAIN_PART"
}

# Query LDAP server until ready
waitInit() {
	WAIT_MAX="$1"
	WAIT_STEP="$2"
	kind="$3"
	if [ "$kind" = "sasl" ]; then
		log "Connection test using SASL authentication"
		cmd="ldapwhoami -H ldapi://%2Fvar%2Frun%2Fopenldap%2Fldapi"
	else
		log "Connection test using normal authentication (port 389)"
		cmd="ldapwhoami -h localhost -p 389 -D cn=manager,${SLAPD_ROOTDN} -w ${SLAPD_ROOTPW}"
	fi
	$cmd
	rc="$?"
	count="$WAIT_MAX"
	while [ "$rc" -ne 0 ] && [ "$count" -ne 0 ]; do
		echo "Server not yet available (code: $rc, count: $count). Trying in $WAIT_STEP seconds."
		sleep "$WAIT_STEP"
		$cmd
		rc="$?"
		count=$((count - WAIT_STEP))
	done
	if [ "$rc" -ne 0 ]; then
		echo "Server was not ready within $WAIT_MAX seconds. Not running tests"
		exit 1
	fi
}
