FROM ruby:2.2.6
ARG jenkins_uid=997
ARG jenkins_gid=994
ENV JENKINS_UID=$jenkins_uid
ENV JENKINS_GID=$jenkins_gid
RUN apt-get update && apt-get install -y sudo
RUN groupadd -g $JENKINS_GID  jenkins
RUN useradd jenkins -u $JENKINS_UID -g $JENKINS_GID --shell /bin/bash --create-home
RUN echo '%jenkins ALL=NOPASSWD: ALL' >> /etc/sudoers
RUN chown -R :jenkins /usr/local/bundle /usr/local/bin
USER jenkins
