#!/bin/sh

set -e

POD_FILE=/tmp/pods.json
PODS_DISCOVERED_FILE=/tmp/pods_discovered.txt

refresh_api () {
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
BASE_URL="$APISERVER/api/v1/namespaces/$NAMESPACE"


$CURL_COMMAND --cacert ${CACERT} \
	--header "$HEADER" \
	-s \
	-o $POD_FILE \
	-X GET "$BASE_URL"/pods
}


if [ -z "$LABELS" ]; then
		echo "No labels specified"
		exit 1
fi
LABELS_FILE=/tmp/labels.txt
# shellcheck disable=SC2016
AWK_SPLIT_LABELS='{ for (i = 1; i <= NF; ++i ) print $i }'
echo "$LABELS" | awk -F, "$AWK_SPLIT_LABELS" > $LABELS_FILE
NUMBER_OF_LABELS_TO_MATCH=$(wc -l < "$LABELS_FILE")
echo "$NUMBER_OF_LABELS_TO_MATCH labels to match with running pods: "
cat $LABELS_FILE
echo ""

discover_pods () {
# shellcheck disable=SC2016
jq_program='
	.items[]
|		.metadata.name as $name
|	  .status.phase as $status
|		.metadata.labels as $labels
|	  ( $labels
|		to_entries
|   map("\(.key)=\(.value)") )
|   join(",") as $labels_array
|  	[$name, $labels_array, $status]
|   @tsv
'

jq -r "$jq_program" < $POD_FILE > $PODS_DISCOVERED_FILE

}


if [ -z "$WAIT_TIME" ]; then
	WAIT_TIME=10
fi

MATCH=0
# Loop until all the labels has been match
while true; do
	refresh_api
	discover_pods
	while read -r pod_info; do
		POD_NAME=$(echo "$pod_info" | awk '{print $1}')
		POD_LABELS=$(echo "$pod_info" | awk '{print $2}')
		POD_STATUS=$(echo "$pod_info" | awk '{print $3}')
		for POD_LABEL in $(echo "$POD_LABELS" | awk -F, "$AWK_SPLIT_LABELS") ; do
			while read -r LABEL_TO_MATCH; do
				if [ "$POD_LABEL" = "$LABEL_TO_MATCH" ]; then
					echo "MATCH: $POD_LABEL"
					MATCH=$((MATCH+1))
					if [ "$MATCH" -eq "$NUMBER_OF_LABELS_TO_MATCH" ]; then
						if [  "$POD_STATUS" = "Running" ]; then
							echo "Pod $POD_NAME is running"
							echo "With this labels:"
							cat "$LABELS_FILE"
							echo "Pod info"
							echo "$pod_info"
							exit 0
						fi
						echo "Pod: $POD_NAME is not yet running"
						echo "the status is $POD_STATUS"
					fi
				fi
			done < $LABELS_FILE
		done
	MATCH=0
	done < $PODS_DISCOVERED_FILE
	echo "Waiting $WAIT_TIME seconds; timestamp: $(date -u +%Y%m%d%H%M%S)"
	echo ""
	sleep "$WAIT_TIME"
done
