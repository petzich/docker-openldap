#!/bin/sh

log_with_time() {
	timestamp=$(date -Iseconds)
	echo "[$timestamp] $*"
}
log() {
	log_with_time "[$0] $*"
}
log_fatal() {
	log "[FATAL] $*"
}

