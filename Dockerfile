FROM alpine:3.7

EXPOSE 389
VOLUME /var/lib/openldap /var/log/openldap

RUN apk add --no-cache \
	gettext \
	openldap \
	openldap-back-mdb \
	openldap-clients \
	openldap-overlay-all

# Copy the entrypoint scripts
COPY entrypoint.sh setup.sh /
RUN chmod u+x \
	/entrypoint.sh \
	/setup.sh \
	&& mkdir -p \
	/setup/conf.dist \
	/setup/ldif.dist

COPY conf.dist/* /setup/conf.dist/
COPY ldif.dist/* /setup/ldif.dist/

ONBUILD COPY conf/ /setup/conf/
ONBUILD COPY ldif/ /setup/ldif/

ENTRYPOINT ["/entrypoint.sh"]
CMD [ "/usr/sbin/slapd", "-u", "ldap", "-g", "ldap", "-F", "/etc/openldap/slapd.d", "-d", "256"]
