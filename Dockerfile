FROM alpine:3.12.1

EXPOSE 389
VOLUME /var/lib/openldap

RUN apk add --no-cache \
	gettext \
	openldap \
	openldap-back-mdb \
	openldap-clients \
	openldap-overlay-all

# Copy the entrypoint scripts
COPY bin/*.sh /
RUN chmod u+x \
	/entrypoint.sh \
	/setup.sh \
	&& mkdir -p \
	/setup/conf.dist \
	/setup/ldif.dist \
	/setup/slapd.ldif

COPY conf.dist/* /setup/conf.dist/
COPY ldif.dist/* /setup/ldif.dist/
COPY slapd.ldif/* /setup/slapd.ldif/

ONBUILD COPY conf/ /setup/conf/
ONBUILD COPY ldif/ /setup/ldif/

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/usr/sbin/slapd", "-u", "ldap", "-g", "ldap", "-F", "/etc/openldap/slapd.d", "-d", "256"]
