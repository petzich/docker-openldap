FROM alpine:3.11.3

EXPOSE 389
VOLUME /var/lib/openldap

RUN apk add --no-cache \
	gettext \
	openldap \
	openldap-back-mdb \
	openldap-clients \
	openldap-overlay-all

# Copy the entrypoint scripts
COPY dist/bin/*.sh /
RUN chmod u+x \
	/entrypoint.sh \
	/ldif.sh \
	&& mkdir -p \
	/setup/conf.dist \
	/setup/rootdn.dist \
	/setup/slapd.dist

COPY dist/conf.dist/* /setup/conf.dist/
COPY dist/rootdn.dist/* /setup/rootdn.dist/
COPY dist/slapd.dist/* /setup/slapd.dist/

ONBUILD COPY conf/ /setup/conf/
ONBUILD COPY rootdn/ /setup/rootdn/

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/usr/sbin/slapd", "-u", "ldap", "-g", "ldap", "-F", "/etc/openldap/slapd.d", "-d", "256"]
