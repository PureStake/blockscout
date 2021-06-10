FROM bitwalker/alpine-elixir-phoenix:1.11.4

RUN apk --no-cache --update add alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3

# Get Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="$HOME/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-feature=-crt-static"

EXPOSE 4000

ENV PORT=4000 \
    MIX_ENV="prod" \
    SECRET_KEY_BASE="RMgI4C1HSkxsEjdhtGMfwAHfyT6CKWXOgzCboJflfSm4jeAlic52io05KB6mqzc5"

# Cache elixir deps
ADD mix.exs mix.lock ./
ADD apps/block_scout_web/mix.exs ./apps/block_scout_web/
ADD apps/explorer/mix.exs ./apps/explorer/
ADD apps/ethereum_jsonrpc/mix.exs ./apps/ethereum_jsonrpc/
ADD apps/indexer/mix.exs ./apps/indexer/

RUN mix do deps.get, local.rebar --force, deps.compile

ADD . .

# Add blockscout npm deps
RUN cd apps/block_scout_web/assets/ && \
    npm install && \
    npm run deploy && \
    cd -

RUN cd apps/explorer/ && \
    npm install

ARG COIN="DEV"
ARG DISABLE_READ_API="false"
ARG DISABLE_WRITE_API="false"
ARG DISABLE_WEBAPP="false"
ARG BLOCKSCOUT_VERSION="v3.6.0+"
ARG RELEASE_LINK="https://github.com/blockscout/blockscout/releases/tag/v3.6.0-beta"

# Run foreground build and phoenix digest
RUN mix compile

RUN apk update && apk del --force-broken-world alpine-sdk gmp-dev automake libtool inotify-tools autoconf python3

RUN mix phx.digest
