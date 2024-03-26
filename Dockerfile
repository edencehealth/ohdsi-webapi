FROM maven:3-amazoncorretto-8 as builder

# for updates, see: https://github.com/OHDSI/WebAPI/releases
ARG GIT_REF="v2.14.0"

# available MAVEN_PROFILE values:
#   webapi-bigquery, webapi-docker, webapi-gis, webapi-hive, webapi-impala,
#   webapi-mssql, webapi-netezza, webapi-oracle, webapi-postgresql
ARG MAVEN_PROFILE=webapi-postgresql

# normally you shouldn't need to change these
ARG NONROOT_UID=65532
ARG NONROOT_GID=65532

# OS-level deps
ARG YUM="yum -y"
RUN set -eux; \
  $YUM update; \
  $YUM upgrade; \
  $YUM install \
    ca-certificates \
    git \
    patch \
    unzip \
  ; \
  $YUM clean all; \
  rm -rf /var/cache/yum;

WORKDIR /build

# acquire the app code
RUN set -eux; \
  git clone \
    --single-branch \
    --branch "$GIT_REF" \
    --depth 1 \
    "https://github.com/OHDSI/WebAPI.git" \
    "/build";

# copy in the source code patches & run them
RUN set -eux; \
  curl --tlsv1.2 -sSL -o /bin/patch4ref \
  # v1 is a floating ref updated by the edencehealth/patch4ref release workflow
  "https://raw.githubusercontent.com/edencehealth/patch4ref/v1/patch4ref.sh"; \
  chmod +x /bin/patch4ref;
COPY patches patches/
RUN patch4ref --strict

# build the app
RUN --mount=type=cache,target=/root/.m2 \
  set -eux; \
  mvn package \
    --activate-profiles "${MAVEN_PROFILE}" \
    --define skipITtests \
    --define skipUnitTests \
    --no-transfer-progress \
  ; \
  unzip -q -d war target/WebAPI.war; \
  rm target/WebAPI.war;

FROM amazoncorretto:8
LABEL maintainer="edenceHealth ohdsi-containers <https://edence.health/>"
ARG NONROOT_UID
ARG NONROOT_GID

WORKDIR /app

# copy the extracted war file to /app
COPY --from=builder /build/war .

# the user 'nonroot' is not part of the amazoncorretto base image (it was
# there in our former distroless base image). additionally there doesn't seem
# to be an adduser style-command, so we do it manually
# nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
RUN set -ex; \
  printf 'nonroot:x:%s:%s:nonroot:/home/nonroot:/sbin/nologin\n' \
    "$NONROOT_UID" \
    "$NONROOT_GID" \
    >>/etc/passwd; \
  printf '\nnonroot:*:18313:0:99999:7:::\n' >>/etc/shadow; \
  printf 'nonroot:x:%s:\n' "$NONROOT_GID" >>/etc/group; \
  printf 'nonroot:::\n' >>/etc/gshadow; \
  :
USER nonroot

ENTRYPOINT [ \
  "/usr/bin/java", \
  "-classpath", ".:WEB-INF/lib:WEB-INF/lib/*:WEB-INF/classes", \
  "-Djava.security.egd=file:///dev/./urandom", \
  "org.ohdsi.webapi.WebApi" \
]
