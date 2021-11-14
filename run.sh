#!/bin/sh

set -e
# Point to the internal API server hostname
APISERVER=https://kubernetes.default.svc

# Path to ServiceAccount token
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount

# Read this Pod's namespace
NAMESPACE=$(cat ${SERVICEACCOUNT}/namespace)

# Read the ServiceAccount bearer token
TOKEN=$(cat ${SERVICEACCOUNT}/token)

HEADER="Authorization: Bearer ${TOKEN}"

# Reference the internal certificate authority (CA)
CACERT=${SERVICEACCOUNT}/ca.crt


# Shorten the curl commands
CURL_COMMAND=$(which curl)
CACERT_ARG="--cacert ${CACERT}"
BASE_URL="$APISERVER/api/v1/namespaces/$NAMESPACE"
REQUEST_ARG="-X GET $BASE_URL"


PODS="$($CURL_COMMAND $CACERT_ARG --header "$HEADER" $REQUEST_ARG/pods)"

echo "$PODS"
