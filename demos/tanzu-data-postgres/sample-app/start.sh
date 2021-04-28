#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
DATABASE_JDBC_URL="jdbc:postgresql://${INSTANCE_NAME}.${NAMESPACE_NAME}.svc.cluster.local:5432/${DATABASE_NAME}?targetServerType=master"

if [[ "${DATABASE_JDBC_URL:-X}" == "X" ]]; then
  exec java -jar -Dspring.profiles.active="in-memory" spring-music.jar
else
  if [[ "${DATABASE_JDBC_URL}" =~ "jdbc:postgresql" ]]; then

    # see Hikari Connection Pool for documentation on parameters: https://github.com/brettwooldridge/HikariCP
    exec java -jar -Dspring.profiles.active=postgres \
              -Dspring.datasource.url=${DATABASE_JDBC_URL} \
              -Dspring.datasource.username=${DATABASE_USERNAME} \
              -Dspring.datasource.password=${DATABASE_PASSWORD} \
              -Dspring.datasource.hikari.initializationFailTimeout=0 \
              -Dspring.datasource.hikari.maxLifetime=30000 \
              -Djavax.net.debug=ssl \
              -Dlogging.level.com.zaxxer.hikari.HikariConfig=DEBUG \
              -Dlogging.level.com.zaxxer.hikari=TRACE \
              -XX:TieredStopAtLevel=1 \
      spring-music.jar --debug
  else
    echo "ERROR: unknown \$DATABASE_JDBC_URL protocol; currently supporting jdbc:postgresql://"
    echo "-- \$DATABASE_JDBC_URL: $DATABASE_JDBC_URL"
    exit 1
  fi
fi
