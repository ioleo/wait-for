#!/usr/bin/env bash
# Use this script to wait until given HTTP endpoint returns 200 OK.

# Based on:       [vishnubob/wait-for-it](https://github.com/vishnubob/wait-for-it)
# Modified by:    [ioleo](https://github.com/ioleo)
# Requirements:   curl

cmdname=$(basename $0)

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi }

usage()
{
    cat << USAGE >&2
Usage:
    $cmdname [-h host] [-p port] [-e endpoint] [--secure] [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST                TCP host under test
    -p PORT | --port=PORT                TCP port under test
    -e ENDPOINT | --endpoint=ENDPOINT    Endpoint under test
    --secure                             Use HTTPS
    -s | --strict                        Only execute subcommand if the test succeeds
    -q | --quiet                         Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT       Timeout in seconds, zero for no timeout
    -- COMMAND ARGS                      Execute command with args after the test finishes

    Example: $cmdname -h localhost -p 8080 -e health/check --secure -s -t 15 -- echo "Up and running!"
USAGE
    exit 1
}

wait_for()
{
    if [[ $TIMEOUT -gt 0 ]]; then
        echoerr "$cmdname: waiting $TIMEOUT seconds for $URL"
    else
        echoerr "$cmdname: waiting for $URL without a timeout"
    fi

    start_ts=$(date +%s)
    counter=0
    result=0

    until $(curl -XGET --output /dev/null --silent --head --fail $URL); do
        if [ ${counter} -eq ${TIMEOUT} ];then
            result=1
            break
        fi

        counter=$(($counter+1))
        sleep 1
    done

    if [[ $result -eq 0 ]]; then
        end_ts=$(date +%s)
        echoerr "$cmdname: $URL is available after $((end_ts - start_ts)) seconds"
    fi

    return $result
}

# process arguments
while [[ $# -gt 0 ]]
do
    case "$1" in
        --secure)
        SECURE=1
        shift 1
        ;;
        --child)
        CHILD=1
        shift 1
        ;;
        -q | --quiet)
        QUIET=1
        shift 1
        ;;
        -s | --strict)
        STRICT=1
        shift 1
        ;;
        -h)
        HOST="$2"
        if [[ $HOST == "" ]]; then break; fi
        shift 2
        ;;
        --host=*)
        HOST="${1#*=}"
        shift 1
        ;;
        -p)
        PORT="$2"
        if [[ $PORT == "" ]]; then break; fi
        shift 2
        ;;
        --port=*)
        PORT="${1#*=}"
        shift 1
        ;;
        -e)
        ENDPOINT="$2"
        if [[ $ENDPOINT == "" ]]; then break; fi
        shift 2
        ;;
        --endpoint=*)
        ENDPOINT="${1#*=}"
        shift 1
        ;;
        -t)
        TIMEOUT="$2"
        if [[ $TIMEOUT == "" ]]; then break; fi
        shift 2
        ;;
        --timeout=*)
        TIMEOUT="${1#*=}"
        shift 1
        ;;
        --)
        shift
        CLI=("$@")
        break
        ;;
        --help)
        usage
        ;;
        *)
        echoerr "Unknown argument: $1"
        usage
        ;;
    esac
done

if [[ "$HOST" == "" ]]; then
    echoerr "Error: you need to provide a host to test."
    usage
fi

SECURE=${SECURE:-0}
PORT=${PORT:-80}
TIMEOUT=${TIMEOUT:-15}
STRICT=${STRICT:-0}
CHILD=${CHILD:-0}
QUIET=${QUIET:-0}

PROTOCOL=$([[ $SECURE -gt 0 ]] && echo "https" || echo "http")
ADDRESS=$([[ $PORT -eq 80 ]] && echo "$HOST" || echo "$HOST:$PORT")
URL="$PROTOCOL://$ADDRESS/$ENDPOINT"

if [[ $CHILD -gt 0 ]]; then
    wait_for
    RESULT=$?
    exit $RESULT
else
    wait_for
    RESULT=$?
fi

if [[ $CLI != "" ]]; then
    if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
        echoerr "$cmdname: strict mode, refusing to execute subprocess"
        exit $RESULT
    fi
    exec "${CLI[@]}"
else
    exit $RESULT
fi
