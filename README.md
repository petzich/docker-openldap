docker image petzi/openldap
===========================

This is a docker image providing openldap, running on Alpine linux.
It opens a non-encrypted LDAP socket on port 389.

Usage
-----

### Variables
The following environment variables are provided:

* `SLAPD_ROOTDN` (required) a value such as `dc=example,dc=org`
* `SLAPD_ROOTPW` (required) the password for the administrative user. Bind DN is `cn=manager,dc=example,dc=org`

Any other variables should be provided to the Docker container if they are defined as variables in any LDIF files.

### Standalone
This image is intended to be used by extending in your own image. To run the image as-is, you can issue the following command:
```
docker run -d -p 2389:389 -e SLAPD_ROOTDN="dc=example,dc=org" -e SLAPD_ROOTPW=NotSoSecret petzi/openldap
```
You can then connect using the bind DN `cn=manager,dc=example,dc=org`.

### Extending
This image is intended to be used by extending with your own docker image. Use a `Dockerfile` and provide two directories with your configuration as LDIF files:

* `init/conf/`
* `init/rootdn/`

The `init/conf` directory should contain ldif files operating on the `cn=config` tree in the initialization phase.
The `init/rootdn` directory should contain ldif files operating on your `SLAPD_ROOTDN` tree in the initialization phase.

### Volume
A volume is provided for the ldap database. You should create a volume container if you want data to persist across restarts.

* `/var/lib/openldap/`

Setup script
------------

The `entrypoint.sh` script provided only does some bootstrapping. `ldif.sh` is the script doing the hard lifting. The script reads ldif files from the following directories:

### Directory structure
* `/setup/init/conf.dist/` - provided by this image
* `/setup/init/conf.user/` - user-provided
* `/setup/init/rootdn.dist/` - provided by this image
* `/setup/init/rootdn.user/` - user-provided

All LDIF files are processed by ldapmodify, so all entries should contain a changetype, even add. Example:

```
dn: ou=users,dc=example,dc=org
changetype: add
objectClass: organizationalUnit
...
```

### Variables

The LDIF files may contain variables, they should be surrounded by environment variable quoting, example: `${MYAPP_VAR1}`. In order for `ldif.sh` to replace the variable, you should provide the following environment variables to the container. You might get weird errors otherwise. You can rewrite the example for above like so:

```
dn: ou=users,${SLAPD_ROOTDN}
changetype: add
objectClass: organizationalUnit
...
```

Contributing
------------

You can use any editor to do developping or bugfixing. The default Makefile target builds the docker images and runs the tests, so just run `make`. There is also a target `test-shell` which will drop you into a shell in the test image.

```
make
make test-shell
```

To run a test server, issue the command `docker-compose run`. This will run an ldap server with an empty rootdn. To connect from your host using an LDAP browser, use the following information:

* port: `localhost:2389`
* user: `cn=manager,dc=example,dc=org`
* password: `password`

If you see something missing in the image or have a bugfix, please submit a pull request. You can also submit an issue, but pull requests will usually be processed faster.
