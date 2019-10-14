FROM trafex/alpine-nginx-php7 as moodlo

ENV VERSION 37
ENV MD_MD5 279b07bb854205f149cec3688767c8c5
ENV MD_DOWNLOAD_URL https://download.moodle.org/stable${VERSION}/moodle-latest-${VERSION}.tgz

USER root 

WORKDIR /tmp/

RUN apk --no-cache update && apk --no-cache upgrade && apk --no-cache add postgresql-client && apk --no-cache add tar &&\
    curl -o moodle.tgz -SL $MD_DOWNLOAD_URL &&\
    echo "$MD_MD5 *moodle.tgz" | md5sum -c - \
    && tar -xzf moodle.tgz -C /opt/ \
    && rm moodle.tgz










FROM alpine as postgresdb

ENV MUSL_LOCPATH="/usr/share/i18n/locales/musl"

RUN apk --no-cache update && apk --no-cache upgrade && apk --no-cache add postgresql &&\
    apk add --no-cache su-exec &&\
    set -ex && apk --no-cache add sudo &&\
    apk --no-cache add libintl && \
    apk --no-cache --virtual .locale_build add cmake make musl-dev gcc gettext-dev git && \
    git clone https://gitlab.com/rilian-la-te/musl-locales && \
    cd musl-locales && cmake -DLOCALE_PROFILE=OFF -DCMAKE_INSTALL_PREFIX:PATH=/usr . && make && make install && \
    cd .. && rm -r musl-locales && \
    apk del .locale_build &&\
#   echo "Docker!" | passwd -d root 12345 &&\
    echo "ALL ALL = (ALL) NOPASSWD: ALL" > /etc/sudoers &&\
    mkdir -p /run/postgresql/ &&\ 
    chown -R postgres:postgres /run/postgresql/ &&\
    mkdir -p /var/lib/postgresql/data &&\
    chmod -R 700 /var/lib/postgresql/data &&\
    chown -R postgres:postgres /var/lib/postgresql/data 

USER postgres

RUN  initdb  /var/lib/postgresql/data &&\
     echo "host all  all  0.0.0.0/0  md5" >> /var/lib/postgresql/data/pg_hba.conf &&\
     echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf &&\
     pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/log.log &&\
     psql -U postgres -c "CREATE USER moodleuser WITH PASSWORD '346j178s'"&&\
     psql -U postgres -c "CREATE DATABASE moodle WITH OWNER moodleuser ENCODING 'UTF8' TEMPLATE=template0" 

#ENTRYPOINT pg_ctl start -D /var/lib/postgresql/data -l /var/lib/postgresql/log.log && /bin/sh

COPY ./start.sh /
#RUN chmod +x /start.sh

ENTRYPOINT ["/start.sh"]
#VOLUME ["/var/lib/postgresql/data"]
#WORKDIR  /var/lib/postgresql

#CMD pg_ctl start -D /var/lib/postgresql/data && tail -F /var/lib/postgresql/log.log;
#CMD tail -f /dev/null

EXPOSE 5432