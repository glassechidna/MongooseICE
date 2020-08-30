FROM phusion/baseimage:18.04-1.0.0 as build

ENV HOME=/opt/app/ TERM=xterm
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ADD erlang-solutions_1.0_all.deb .

# Install Elixir and basic build dependencies
RUN apt-get update && apt-get install -y \
    gnupg \
    git \
    gcc \
    g++ \
    make && \
    dpkg -i erlang-solutions_1.0_all.deb && \
    apt-get update && \
    apt-get install -y esl-erlang elixir && \
    apt-get clean


# Install Hex+Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

WORKDIR /opt/app

ENV MIX_ENV=prod

# Cache elixir deps
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile

COPY . .

RUN mix release


FROM phusion/baseimage:18.04-1.0.0

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# required packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    bash \
    bash-completion \
    curl \
    dnsutils \
    vim && \
    apt-get clean

ENV MONGOOSEICE_UDP_BIND_IP=0.0.0.0 MONGOOSEICE_UDP_PORT=3478 MIX_ENV=prod \
    MONGOOSEICE_TCP_BIND_IP=0.0.0.0 MONGOOSEICE_TCP_PORT=3479 MIX_ENV=prod \
    REPLACE_OS_VARS=true SHELL=/bin/bash

WORKDIR /opt/app

COPY --from=build /opt/app/_build/prod/rel/mongooseice ./
ADD docker/start.sh /opt/app/start.sh
RUN chmod +x /opt/app/start.sh

# Move priv dir
RUN mv $(find lib -name mongooseice-*)/priv .
RUN ln -s $(pwd)/priv $(find lib -name mongooseice-*)/priv

VOLUME /opt/app/priv

CMD ["start"]
ENTRYPOINT ["/opt/app/start.sh"]
