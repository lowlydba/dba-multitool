FROM node:latest

LABEL "com.github.actions.name"="TSQLLint action"
LABEL "com.github.actions.description"="Lint T-SQL files"
LABEL "com.github.actions.icon"="database"
LABEL "com.github.actions.color"="green"

###############################
# Add add'l packages required #
###############################
RUN apt-get -qq update \
    && apt-get -qq install libunwind8 \
    && yarn global add tsqllint
#
#RUN 

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]