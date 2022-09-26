#!/bin/sh

warn() {
  printf '%s %s\n' "$(date '+%FT%T')" "$*" >&2
}

die() {
  warn "$* EXITING"
  exit 1
}

usage() {
  printf '%s\n' \
    "Usage: $0 [-h|--help] [--strict] [git-ref] [...]" \
    "" \
    "For each given git ref, this program applies patches to the source code" \
    "to make the container work (or work better)." \
    "" \
    "If given the --strict flag, the program will exit non-zero if any" \
    "given git ref is unknown." \
    "" \
    "$*"

  [ -n "$*" ] && exit 1
  exit 0
}

main() {
  STRICT=""

  set -e
  for arg in "$@"; do
    case "$arg" in

      refs/tags/v2.11.*|*v2.11.*)
        (
          warn "Applying patches for $arg"
          set -ex

          # nothing provided in this container
          sed -i.bak \
            's#<scope>provided</scope>##g;' \
            pom.xml

          # switch repo.ohdsi.org to TLS
          # see https://maven.apache.org/docs/3.8.1/release-notes.html and
          # https://github.com/OHDSI/WebAPI/issues/1825
          sed -i.bak \
            's#http://repo.ohdsi.org:8085#https://repo.ohdsi.org#g;' \
            pom.xml

        )
        ;;

      refs/tags/v2.10.*|*v2.10.*)
        (
          warn "Applying patches for $arg"
          set -ex

          # nothing provided in this container
          sed -i.bak \
            's#<scope>provided</scope>##g;' \
            pom.xml

          # switch repo.ohdsi.org to TLS
          # see https://maven.apache.org/docs/3.8.1/release-notes.html and
          # https://github.com/OHDSI/WebAPI/issues/1825
          sed -i.bak \
            's#http://repo.ohdsi.org:8085#https://repo.ohdsi.org#g;' \
            pom.xml

        )
        ;;

      refs/tags/v2.8.1|*v2.8.1)
        (
          warn "Applying patches for $arg"
          set -ex

          # nothing provided in this container
          sed -i.bak \
            's#<scope>provided</scope>##g;' \
            pom.xml

          # com.qmino:miredot-plugin:2.2 not currently available with TLS
          sed -i.bak \
            's#<miredot.phase>package</miredot.phase>#<miredot.phase>none</miredot.phase>#g;' \
            pom.xml

          # switch repo.ohdsi.org to TLS
          # see https://maven.apache.org/docs/3.8.1/release-notes.html and
          # https://github.com/OHDSI/WebAPI/issues/1825
          sed -i.bak \
            's#http://repo.ohdsi.org:8085#https://repo.ohdsi.org#g;' \
            pom.xml
        )
        ;;

      refs/tags/v2.7.9|*v2.7.9)
        (
          warn "Applying patches for $arg"
          set -ex

          # nothing provided in this container
          sed -i.bak \
            's#<scope>provided</scope>##g;' \
            pom.xml

          # org.hibernate 5.4.2.Final -> 5.4.22.Final
          sed -i.bak \
            's#5.4.2.Final#5.4.22.Final#g;' \
            pom.xml

          # fixing mssql broken migration
          sed -i.bak \
            's#VARCHAR(MAX);#VARCHAR(1024);#g;' \
            ./src/main/resources/db/migration/sqlserver/V2.8.0.20200427161830__modify_user_login.sql
        )
        ;;

      --strict)
        STRICT=1
        ;;

      -h|--help)
        usage
        ;;

      -*)
        usage "Unknown flag $arg"
        ;;

      *)
        if [ -n "$STRICT" ]; then
          die "Not patching unknown git ref ${arg}. This is fatal in strict mode."
        else
          warn "Not patching unknown git ref ${arg}"
        fi
        ;;

    esac
  done
}

[ -n "$IMPORT" ] || main "$@"
