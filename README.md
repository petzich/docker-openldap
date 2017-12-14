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
* `SLAPD_SETUP_EXTRA_VARS` (optional) A space-separated list of extra variables used in your LDIF files. Example: `MYAPP_VAR1 MYAPP_VAR2`. These variables in your LDIF files are then replaced with the values of the environment variables.

### Standalone
This image is intended to be used by extending in your own image. To run the image as-is, you can issue the following command:
```
docker run -d -p 2389:389 -e SLAPD_ROOTDN="dc=example,dc=org" -e SLAPD_ROOTPW=NotSoSecret petzi/openldap
```
You can then connect using the bind DN `cn=manager,dc=example,dc=org`.

### Extending
This image is intended to be used by extending with your own docker image. Use a `Dockerfile` and provide two directories with your configuration as LDIF files:

* `conf/`
* `ldif/`

### Volumes
Two volumes are provided. You should create volume containers for those volumes if you want data to persist across restarts (especially /var/lib/openldap/).

* `/var/lib/openldap/`
* `/var/log/openldap/`

Setup script
------------

The `entrypoint.sh` script provided only does some bootstrapping. `setup.sh` is the script doing the hard lifting. The script reads ldif files from the following four directories:

### Directory structure
* `/setup/conf.dist/` - provided by this image
* `/setup/conf/` - user-provided
* `/setup/ldif.dist/` - provided by this image
* `/setup/ldif/` - user-provided

The `conf` directory should contain ldif files operating on the `cn=config` tree.
The `ldif` directory should contain ldif files operating on your `SLAPD_ROOTDN` tree.

### File names
The file extension in all directories has a meaning:

* `*.add.ldif` - use `ldapadd` to process the file
* `*.mod.ldif` - use `ldapmodify` to process the file

### Variables
The ldif files can contain variables, they should be surrounded by double-hashes, example: `##MYAPP_VAR1##`
In order for `setup.sh` to replace the variable, you should provide the following environment variables when starting the container:

* `SLAPD_SETUP_EXTRA_VARS="MYAPP_VAR1"`
* `MYAPP_VAR1="my value of var1"`

Contributing
------------

There is a Vagrant machine for local development. Common commands:

```
vagrant up
vagrant ssh
make
make run
```
This will run an ldap server with an empty rootdn. To connect from your host using an LDAP browser, use the following information:

* port: `localhost:2389`
* user: `cn=manager,dc=example,dc=org`
* password: `test`

If you see something missing in the image or have a bugfix, please submit a pull request. You can also submit an issue, but pull requests will usually be processed faster.
