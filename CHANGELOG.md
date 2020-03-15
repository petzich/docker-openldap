# Change Log

This changelog follows [Semantic Versioning](http://semver.org).

## Unreleased

### Incompatible changes

- The directories for the ldif files have been renamed (see README.md)

### Changed

- Renamed setup.sh to ldif.sh

### Added

## 0.5.2 - 2020-03-14

### Changed

- Upgrade base image alpine:3.9.4 -> 3.11.3

## 0.5.1 - 2019-05-14

### Changed

- Upgrade base image alpine:3.9.3 -> alpine:3.9.4

## 0.5.0 - 2019-04-24

### Changed

- Upgrade base image alpine:3.8 -> alpine:3.9.3

## 0.4.3 - 2018-10-20

### Fixed

- Checksum error without need for huge library

## 0.4.2 - 2018-10-20

### Fixed

- Checksum error

## 0.4.1 - 2018-10-19

### Added

- Useful logging output with timestamp and script name

### Changed

- Generate slapd.ldif.generated with pre-generated config files

### Fixed

- Many shellcheck suggestions in scripts

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
