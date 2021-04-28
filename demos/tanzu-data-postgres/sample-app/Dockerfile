FROM openjdk:8-jdk as build

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 5.6

RUN set -o errexit -o nounset \
	&& echo "Downloading Gradle" \
	&& wget --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
  \
  && echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
  \
  && echo "Adding gradle user and group" \
	&& groupadd --system --gid 1000 gradle \
	&& useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
	&& mkdir /home/gradle/.gradle \
	&& chown --recursive gradle:gradle /home/gradle

RUN set -o errexit -o nounset \
  && wget https://github.com/cloudfoundry-samples/spring-music/archive/master.zip \
  && unzip master.zip \
  && cd spring-music-master \
  && gradle clean assemble

# Using openjdk:8 due to https://github.com/cloudfoundry-samples/spring-music/issues/38
FROM openjdk:8-jdk as server

COPY --from=build /spring-music-master/build/libs/spring-music-master-1.0.jar /app/spring-music.jar
COPY start.sh /app/
EXPOSE 8080
ENV PORT 8080

WORKDIR /app

ENTRYPOINT ["/app/start.sh"]
