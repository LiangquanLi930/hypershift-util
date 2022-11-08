#!/bin/bash

export LC_CTYPE=C
set -o nounset
set -o errexit
set -o pipefail

count=$(oc get hostedclusters --no-headers --ignore-not-found -n clusters | wc -l)
if [ "$count" -lt 1 ]  ; then
    echo "namespace clusters don't have hostedcluster"
    exit 1
fi
#Limitation: we always & only select the first hostedcluster to add idp-htpasswd. "
cluster_name=$(oc get hostedclusters -n clusters -o jsonpath='{.items[0].metadata.name}')

# prepare users
users=""
htpass_file=/tmp/users.htpasswd

for i in $(seq 1 40);
do
    username="testuser-${i}"
    password=$(< /dev/urandom tr -dc 'a-z0-9' | fold -w 12 | head -n 1 || true)
    users+="${username}:${password},"
    if [ -f "${htpass_file}" ]; then
        htpasswd -B -b ${htpass_file} "${username}" "${password}"
    else
        htpasswd -c -B -b ${htpass_file} "${username}" "${password}"
    fi
done

## add users to cluster
oc create secret generic "$cluster_name" --from-file=htpasswd="$htpass_file" -n clusters
oc patch hostedclusters $cluster_name -n clusters --type=merge -p '{"spec":{"configuration":{"oauth":{"identityProviders":[{"htpasswd":{"fileData":{"name":"'$cluster_name'"}},"mappingMethod":"claim","name":"htpasswd","type":"HTPasswd"}]}}}}'

echo "$users"