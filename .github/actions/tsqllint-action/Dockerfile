FROM node:latest

###############################
# Add add'l packages required #
###############################
RUN DEBIAN_FRONTEND=noninteractive && \
    apt-get -qq update && \
    apt-get -qq install libunwind8  && \
    yarn global add tsqllint

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
RUN chmod +x ./entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
