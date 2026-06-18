FROM ruby:3.4
ARG POSTGRESQL_VERSION=17

RUN apt -y --purge autoremove subversion mariadb-common mercurial
RUN apt update && apt install -y --no-install-recommends lsb-release \
    && rm -rf /var/lib/apt/lists/*
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > \
    /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt update && apt install -y --no-install-recommends \
    postgresql-client-${POSTGRESQL_VERSION} \
    sudo \
    && rm -rf /var/lib/apt/lists/*

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
