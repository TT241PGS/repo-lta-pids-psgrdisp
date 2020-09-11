FROM elixir:1.10.3-alpine as build-stage

ENV HOME=/opt/app
WORKDIR $HOME

RUN mix do local.hex --force, local.rebar --force

COPY config/ $HOME/config/
COPY mix.exs mix.lock $HOME/

ENV MIX_ENV=prod
RUN mix do deps.get --only prod, deps.compile

COPY . .

ARG APP_NAME=display
# The version of the application we are building (required)
ARG APP_VERSION=1.0.0
# The environment to build with
ARG MIX_ENV=prod

ENV APP_NAME=${APP_NAME} \
  MIX_ENV=${MIX_ENV}

RUN mix compile

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

WORKDIR $HOME

COPY --from=build-stage /opt/built .

EXPOSE 80

ENTRYPOINT [ "/opt/app/bin/display" ]

CMD ["foreground"]