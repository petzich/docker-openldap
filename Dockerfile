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
	/setup/init/conf.dist \
	/setup/init/rootdn.dist \
	/setup/init/slapd.dist

COPY dist/init/conf.dist/* /setup/init/conf.dist/
COPY dist/init/rootdn.dist/* /setup/init/rootdn.dist/
COPY dist/init/slapd.dist/* /setup/init/slapd.dist/

ONBUILD COPY init/conf/ /setup/init/conf.user/
ONBUILD COPY init/rootdn/ /setup/init/rootdn.user/

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/usr/sbin/slapd", "-u", "ldap", "-g", "ldap", "-F", "/etc/openldap/slapd.d", "-d", "256"]
