FROM ubuntu:16.04

## Meta information
LABEL version=0.1
LABEL name=ccci
LABEL description="For the Concourse Console by fly command"


## Install the fly command
COPY ./src/fly /usr/bin/fly
RUN chmod 755 /usr/bin/fly

## Install th CURL command for download
RUN apt-get update 
RUN apt-get install curl -y


RUN curl -sL "https://github.com/starkandwayne/concourse-tutorial/archive/v3.10.0.tar.gz" > concourse.tgz && tar zxvf concourse.tgz
COPY ./src/provisioning.sh provisioning.sh
COPY ./src/pipeline.yml pipeline.yml

## Clean up APT
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN rm -f concourse.tgz

ENTRYPOINT /provisioning.sh
