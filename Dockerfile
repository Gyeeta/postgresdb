# syntax=docker/dockerfile:1

FROM ubuntu:18.04

LABEL description="This container provides the Gyeeta Postgres DB"

LABEL org.opencontainers.image.description="To run the container : \
3 inputs needed : The volume where the Postgres DB will be stored, Password of postgres user and Port to be used. \
The container needs to be initialized once for a specific data mount point. The initialization can be done either by \
running an init container or directly running the main container but passing the CFG_POSTGRES_PASSWORD and CFG_POSTGRES_PORT env along."

LABEL initusage="docker run -td --rm --name gyeetaInitPostgres --read-only -v /PATH_TO_PERSISTENT_VOLUME:/dbdata --env CFG_POSTGRES_PASSWORD=MyPassword --env CFG_POSTGRES_PORT=10040 <Gyeeta Postgres Image> --initdb"
LABEL usage="docker run -td --rm --name gyeetaPostgres --read-only -p 10040:10040 -v /PATH_TO_PERSISTENT_VOLUME:/dbdata <Gyeeta Postgres Image>"

LABEL initAndRunUsage="docker run -td --rm --name gyeetaPostgres --read-only -p 10040:10040 --env CFG_POSTGRES_PASSWORD=MyPassword --env CFG_POSTGRES_PORT=10040 -v /PATH_TO_PERSISTENT_VOLUME:/dbdata <Gyeeta Postgres Image>"

# LABEL for github repository link
LABEL org.opencontainers.image.source="https://github.com/gyeeta/postgresdb"

LABEL org.opencontainers.image.authors="https://github.com/gyeeta"

RUN apt-get update && rm -rf /var/lib/apt/lists/*

# tini handling...
ARG TINI_VERSION=v0.19.0
ARG TINI_SHA256="93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c"
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod 0755 /tini
RUN if [ `sha256sum /tini | awk '{print $1}'` != "$TINI_SHA256" ]; then echo -e "ERROR : SHA256 of tini is different from expected value. Binary has changed. Please contact on Github.\n\n"; return 1; else return 0; fi

RUN addgroup --gid 1001 gyeeta && adduser --system --no-create-home --uid 1001 --gid 1001 gyeeta

RUN mkdir -p -m 0755 /postgresdb; chown -R gyeeta:gyeeta /postgresdb

RUN mkdir -p -m 0755 /opt/lib_install/postgres; chown -R gyeeta:gyeeta /opt/lib_install

RUN mkdir -p -m 0775 /dbdata; chown -R gyeeta:gyeeta /dbdata

VOLUME [ "/dbdata" ]

COPY --chown=gyeeta:gyeeta . /postgresdb/

RUN echo -n "/dbdata/gyeetadb" > /postgresdb/cfg/dbdir.cfg

# Create dirs as the postgres shared libs are expected at this location
RUN ln -s /postgresdb/bin /opt/lib_install/postgres/bin && \
	ln -s /postgresdb/lib /opt/lib_install/postgres/lib && \
	ln -s /postgresdb/include /opt/lib_install/postgres/include

USER gyeeta:gyeeta

ENTRYPOINT ["/tini", "-s", "-g", "--", "/postgresdb/container_db.sh" ]

CMD ["start"]

