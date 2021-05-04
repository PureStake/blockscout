#!/bin/bash

# VARS
# visual / optional
export NETWORK="Moonbeam"
export SUBNETWORK="Development"
export LOGO="/images/moonbeam_logo.png"
export SUPPORTED_CHAINS='[{"title":"Moonbase","url":"https://blockscout.com/moon/moonbase","test_net?":true},{"title":"Moonbase - Subscan","url":"https://moonbase.subscan.io","test_net?":true},{"title":"Kovan - Etherscan","url":"https://kovan.etherscan.io","test_net?":true,"hide_in_dropdown?":true},{"title":"Rinkeby - Etherscan","url":"https://rinkeby.etherscan.io","test_net?":true,"hide_in_dropdown?":true},{"title":"Ropsten - Etherscan","url":"https://ropsten.etherscan.io","test_net?":true,"hide_in_dropdown?":true}]'
# required
export COIN="DAI"
export ETHEREUM_JSONRPC_VARIANT="geth"
export ETHEREUM_JSONRPC_HTTP_URL="http://localhost:9990"
export ETHEREUM_JSONRPC_WS_URL="ws://localhost:9991"
export DB_USER="postgres"
export DB_PASS=""
export DB_CONNECTION_STRING="postgresql://$DB_USER:$DB_PASS@localhost:5432/explorer"
export INDEXING_FROM_BLOCK="0"


# LAUNCH SCRIPT 

# create postgres container
docker kill postgres
docker rm postgres
export DOCKER_IMAGE="gcr.io/purestake-dev/blockscout:v3.6.0-indexer"
make postgres

echo "Waiting for Postgres to be ready to accept incoming connections..."
wget -qO- https://raw.githubusercontent.com/eficode/wait-for/v2.1.0/wait-for | sh -s -- localhost:5432 -- echo "Postgres is ready!"

# create blockscout indexer container
docker run --rm -d --name blockscout-indexer \
    -e PORT=4006 \
    -e DISABLE_WRITE_API="true" \
    -e DISABLE_WEBAPP="true" \
    -e ECTO_USE_SSL="false" \
    -e POOL_SIZE="20" \
    -e FIRST_BLOCK="$INDEXING_FROM_BLOCK" \
    -e PGUSER="$DB_USER" \
    -e PGPASSWORD="$DB_PASS" \
    -e DATABASE_URL="$DB_CONNECTION_STRING" \
    -e NETWORK="$NETWORK" \
    -e SUBNETWORK="$SUBNETWORK" \
    -e LOGO="$LOGO" \
    -e SUPPORTED_CHAINS="$SUPPORTED_CHAINS" \
    -e COIN="$COIN" \
    -e ETHEREUM_JSONRPC_VARIANT="$ETHEREUM_JSONRPC_VARIANT" \
    -e ETHEREUM_JSONRPC_HTTP_URL="$ETHEREUM_JSONRPC_HTTP_URL" \
    -e ETHEREUM_JSONRPC_WS_URL="$ETHEREUM_JSONRPC_WS_URL" \
    -e MIX_ENV="prod" \
    --network host \
    gcr.io/purestake-dev/blockscout:v3.6.0-indexer /bin/sh -c "mix phx.server"

# create blockscout explorer container
docker run --rm -d --name blockscout-explorer-rw \
    -e PORT=4003 \
    -e SHOW_PRICE_CHART="false" \
    -e DISABLE_EXCHANGE_RATES="true" \
    -e SHOW_TXS_CHART="true" \
    -e ENABLE_TXS_STATS="true" \
    -e HISTORY_FETCH_INTERVAL=2 \
    -e TXS_STATS_DAYS_TO_COMPILE_AT_INIT=7 \
    -e GAS_PRICE="0" \
    -e DISABLE_INDEXER="true" \
    -e ECTO_USE_SSL="false" \
    -e POOL_SIZE="20" \
    -e PGUSER="$DB_USER" \
    -e PGPASSWORD="$DB_PASS" \
    -e DATABASE_URL="$DB_CONNECTION_STRING" \
    -e NETWORK="$NETWORK" \
    -e SUBNETWORK="$SUBNETWORK" \
    -e LOGO="$LOGO" \
    -e SUPPORTED_CHAINS="$SUPPORTED_CHAINS" \
    -e COIN="$COIN" \
    -e ETHEREUM_JSONRPC_VARIANT="$ETHEREUM_JSONRPC_VARIANT" \
    -e ETHEREUM_JSONRPC_HTTP_URL="$ETHEREUM_JSONRPC_HTTP_URL" \
    -e ETHEREUM_JSONRPC_WS_URL="$ETHEREUM_JSONRPC_WS_URL" \
    -e MIX_ENV="prod" \
    -e BLOCKSCOUT_VERSION="v3.6.0+" \
    -e RELEASE_LINK="https://github.com/blockscout/blockscout/releases/tag/v3.6.0-beta" \
    --network host \
    gcr.io/purestake-dev/blockscout:v3.6.0-explorer-rw /bin/sh -c "mix phx.server"

    # -e SHOW_MAINTENANCE_ALERT=true \
    # -e MAINTENANCE_ALERT_MESSAGE="Sorry for the inconvenience :)" \
