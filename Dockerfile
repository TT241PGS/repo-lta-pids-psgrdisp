FROM elixir:1.10.3-alpine as base

ENV HOME=/opt/app

RUN mix do local.hex --force, local.rebar --force

COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

WORKDIR $HOME

# Deps such as phoenix are required during asset-builder phase
RUN mix do deps.get --only prod

########################################################################
FROM node:12-alpine as asset-builder

ENV HOME=/opt/app
WORKDIR $HOME

COPY --from=base $HOME/deps $HOME/deps

# Prepare assets
WORKDIR $HOME/assets
COPY assets/ ./
RUN npm i
RUN npm run deploy

########################################################################
FROM elixir:1.10.3-alpine as releaser

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG APP_NAME=display
# The version of the application we are building (required)
ARG APP_VERSION=1.0.0
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
  APP_VERSION=${APP_VERSION} \
  MIX_ENV=${MIX_ENV}

ENV HOME=/opt/app

ARG ERLANG_COOKIE
ENV ERLANG_COOKIE $ERLANG_COOKIE

# dependencies for comeonin
# RUN apk add --no-cache build-base cmake

ENV MIX_ENV=prod
ENV SECRET_KEY_BASE=yq2XDL2EK7JCIQTsUmT+G4DNn9omjTN+5hko0IKJB+RxxzwaEtYliKIU/L1EIH57

WORKDIR $HOME

COPY . .

# Digest precompiled assets
COPY --from=asset-builder $HOME/priv/static/ $HOME/priv/static/

# telemetry fails during digest hence installing hex rebar and deps again
RUN mix do local.hex --force, local.rebar --force

RUN mix do deps.get --only prod, deps.compile, compile

RUN mix phx.digest

# Release
RUN \
  mkdir -p /opt/built && \
  MIX_ENV=prod mix distillery.release --verbose --env=prod && \
  cp _build/${MIX_ENV}/rel/${APP_NAME}/releases/${APP_VERSION}/${APP_NAME}.tar.gz /opt/built && \
  cd /opt/built && \
  tar -xzf ${APP_NAME}.tar.gz && \
  rm ${APP_NAME}.tar.gz

########################################################################
# Downgraded to 3.9 due to https://github.com/processone/docker-ejabberd/issues/46
FROM alpine:3.9

# The name of your application/release (required)
ARG APP_NAME=display

ENV LANG=en_US.UTF-8 \
  HOME=/opt/app/ \
  TERM=xterm \
  LANG=C.UTF-8

RUN apk add --no-cache ncurses-libs openssl bash

ENV MIX_ENV=prod \
  REPLACE_OS_VARS=true

RUN addgroup -g 1000 -S app && \
  adduser -u 1000 -S app -G app

WORKDIR $HOME

COPY --from=releaser /opt/built .

RUN chown -R app:app $HOME
RUN chmod 755 $HOME

USER app

EXPOSE 4000

ENTRYPOINT [ "/opt/app/bin/display" ]

CMD ["foreground"]