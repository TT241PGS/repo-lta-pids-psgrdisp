FROM elixir:1.11.2-alpine as base

ENV HOME=/opt/app
ENV MIX_ENV=prod

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
FROM elixir:1.11.2-alpine as releaser

ENV HOME=/opt/app
ENV MIX_ENV=prod

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
  MIX_ENV=prod mix release --path _build/${MIX_ENV}/rel/latest && \
  mv _build/${MIX_ENV}/rel/latest /opt/built

########################################################################
# Downgraded to 3.9 due to https://github.com/processone/docker-ejabberd/issues/46
FROM alpine:3.9

ENV LANG=en_US.UTF-8 \
  HOME=/opt/app/ \
  TERM=xterm \
  LANG=C.UTF-8 \
  MIX_ENV=prod

RUN apk add --no-cache ncurses-libs openssl bash

RUN addgroup -g 1000 -S app && \
  adduser -u 1000 -S app -G app

WORKDIR $HOME

COPY --from=releaser /opt/built .

RUN chown -R app:app $HOME
RUN chmod 755 $HOME

USER app

EXPOSE 4000

ENTRYPOINT [ "/opt/app/latest/bin/display" ]

CMD ["start"]