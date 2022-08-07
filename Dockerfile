# syntax=docker/dockerfile:1

FROM ubuntu:18.04

LABEL description="This container provides the Gyeeta Postgres DB"

LABEL initusage="docker run -td --rm --name gyeetaInitPostgres --read-only -v /PATH_TO_PERSISTENT_VOLUME:/dbdata --env CFG_POSTGRES_PASSWORD=MyPassword --env CFG_POSTGRES_PORT=10040 <Gyeeta Postgres Image> --initdb"
LABEL usage="docker run -td --rm --name gyeetaPostgres --read-only -p 10040:10040 -v /PATH_TO_PERSISTENT_VOLUME:/dbdata <Gyeeta Postgres Image>"

LABEL initAndRunUsage="docker run -td --rm --name gyeetaPostgres --read-only -p 10040:10040 --env CFG_POSTGRES_PASSWORD=MyPassword --env CFG_POSTGRES_PORT=10040 -v /PATH_TO_PERSISTENT_VOLUME:/dbdata <Gyeeta Postgres Image>"

RUN apt-get update && rm -rf /var/lib/apt/lists/*

# tini handling...
ARG TINI_VERSION=v0.19.0
ARG TINI_SHA256="93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod 0755 /tini
RUN if [ `sha256sum /tini | awk '{print $1}'` != "$TINI_SHA256" ]; then echo -e "ERROR : SHA256 of tini is different from expected value. Binary has changed. Please contact on Github.\n\n"; return 1; else return 0; fi

COPY . /postgresdb/

ENTRYPOINT ["/tini", "-s", "-g", "--", "/postgresdb/container_db.sh" ]

CMD ["start"]

