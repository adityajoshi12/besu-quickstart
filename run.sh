#!/bin/bash -u

NO_LOCK_REQUIRED=true
pwd
. ./.env
. ./.common.sh


PARAMS=""

displayUsage() {
    echo "This script creates and start a local private Besu network using Docker."
    echo "You can select the consensus mechanism to use.\n"
    echo "Usage: ${me} [OPTIONS]"
    echo "    -c <ibft2|clique|ethash> : the consensus mechanism that you want to run
                                       on your network, default is ethash"
    echo "    -e                       : setup ELK with the network."
    echo "    -s                       : test ethsigner with the rpcnode (available when using a POA consensus algorithm. Note the -s option must be preceeded by the -c option"
    exit 0
}

# options values and api values are not necessarily identical.
# value to use for ibft2 option as required for Besu --rpc-http-api and --rpc-ws-api
# we want to explicitely display IBFT2 in the options to prevent people from
# being confused with previous version IBFT, however the RPC API remains commons, so the name
# that's the reason of this not obvious mapping.
# variables names must be similar to the option -c|--consensus values to map.
ibft2='ibft'
clique='clique' # value to use for clique option

composeFile="docker-compose"

while getopts "hesc:" o; do
    case "${o}" in
    h)
        displayUsage
        ;;
    c)
        algo=${OPTARG}
        case "${algo}" in
        ibft2 | clique)
            export SAMPLE_POA_NAME="${algo}"
            export SAMPLE_POA_API="${!algo}"
            export SAMPLE_VERSION="${BESU_VERSION}"
            composeFile="${composeFile}_poa"
            ;;
        ethash) ;;

        *)
            echo "Error: Unsupported consensus value." >&2
            displayUsage
            ;;
        esac
        ;;
    e)
        elk_compose="${composeFile/docker-compose/docker-compose_elk}"
        composeFile="$elk_compose"
        ;;
    s)
        if [[ $composeFile == *"poa"* ]]; then
            signer_compose="${composeFile/poa/poa_signer}"
            composeFile="$signer_compose"
        else
            echo "Error: Unsupported consensus value." >&2
            displayUsage
        fi
        ;;
    *)
        displayUsage
        ;;
    esac
done

composeFile="-f ${composeFile}.yml"

# Build and run containers and network
echo "${composeFile}" >${LOCK_FILE}
echo "${SAMPLE_VERSION}" >>${LOCK_FILE}

echo "${bold}*************************************"
echo "Sample Network for Besu at ${SAMPLE_VERSION}"
echo "*************************************${normal}"
echo "Start network"
echo "--------------------"

echo "Starting network..."
docker-compose ${composeFile} build --pull
docker-compose ${composeFile} up --detach

#list services and endpoints
./list.sh
