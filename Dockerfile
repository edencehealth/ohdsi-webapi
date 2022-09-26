FROM maven:3-jdk-8-slim as builder

# for updates, see: https://github.com/OHDSI/WebAPI/releases
ARG GIT_REF="refs/tags/v2.11.1"

ARG NONROOT_UID=65532
ARG NONROOT_GID=65532

# available MAVEN_PROFILE values:
#   webapi-bigquery, webapi-docker, webapi-gis, webapi-hive, webapi-impala,
#   webapi-mssql, webapi-netezza, webapi-oracle, webapi-postgresql
ARG MAVEN_PROFILE=webapi-mssql

# OS-level deps
RUN set -x \
  && AG="env DEBIAN_FRONTEND=noninteractive apt-get -yq" \
  && $AG update --no-install-recommends \
  && $AG upgrade \
  && $AG install --no-install-recommends \
    ca-certificates \
    git \
    patch \
    unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# acquire the app code
RUN set -ex \
  && git clone "https://github.com/OHDSI/WebAPI.git" "/build" \
  && if [ -n "$GIT_REF" ]; then \
    git checkout "${GIT_REF}" \
  ; fi

# copy in the source code patches & run them
COPY patch4ref.sh ./
RUN ./patch4ref.sh "${GIT_REF}"

# build the app
RUN --mount=type=cache,target=/root/.m2 set -x \
  && mvn package "-P${MAVEN_PROFILE}" -DskipITtests -DskipUnitTests --no-transfer-progress \
  && unzip -q -d war target/WebAPI.war \
  && rm target/WebAPI.war

# RUN mvn dependency:tree \
#   -Dverbose \
#   -DoutputFile=/build/war/dependency_tree.txt \
#   --no-transfer-progress

# (re)start from a minimal base container
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
  printf 'nonroot:x:%s:\n' "NONROOT_GID" >>/etc/group; \
  printf 'nonroot:::\n' >>/etc/gshadow; \
  :

# the user 'nonroot' is part of the base image
# nonroot:x:65532:65532:nonroot:/home/nonroot:/sbin/nologin
USER nonroot

ENTRYPOINT ["/usr/bin/java"]
CMD [ \
  "-classpath", ".:WEB-INF/lib:WEB-INF/lib/*:WEB-INF/classes", \
  "-Djava.security.egd=file:///dev/./urandom", \
  "org.ohdsi.webapi.WebApi" \
]
