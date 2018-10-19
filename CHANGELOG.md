# Change Log

This changelog follows [Semantic Versioning](http://semver.org).

## 0.4.0 - 2018-10-18

### Breaking Changes

- Environment variable substitution in LDIF files must now use shell variable escaping syntax - see README.md for examples
- Vagrant was removed. All development should use docker and/or docker-compose.
- The openldap logging volume definiton was removed. You should use whatever logging infrastructure your docker environment offers to process stderr logging.

### Added

- Gettext to enable envsubst

### Fixed

- Processing of ldif files in setup.sh
- Smaller fixes in setup.sh