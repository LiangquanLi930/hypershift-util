#!/bin/bash


prow() {
    local option=$1

    GANGWAY_API='https://gangway-ci.apps.ci.l2s4.p1.openshiftapps.com'
    TOKEN=$(cat config/gangwaytoken)

    case "$option" in
        "trigger-job")
            echo "trigger a prow job"
            echo -n "JOB NAME?"
            read -r JOB_NAME
            curl -X POST -d '{"job_execution_type": "1"}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"
#            curl -X POST -d '{"job_execution_type": "1","pod_spec_options":{"envs":{"RELEASE_IMAGE_MCE":"quay.io/openshift-release-dev/ocp-release:4.13.3-x86_64","RELEASE_IMAGE_LATEST":"quay.io/openshift-release-dev/ocp-release:4.13.2-x86_64"}}}' -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${JOB_NAME}"
            ;;
        "get-job")
            echo "get a prow job by id"
            echo -n "PROW JOB ID?"
            read -r PROW_JOB_ID
            curl -s -X GET -H "Authorization: Bearer ${TOKEN}" "${GANGWAY_API}/v1/executions/${PROW_JOB_ID}"
            ;;
        *)
            echo "other"
            ;;
    esac
}


menu=("trigger-job" "get-job")
selected=0

while true; do
    tput el

    for i in "${!menu[@]}"; do
        if [ $i -eq $selected ]; then
            echo -e "\e[32m> ${menu[$i]}\e[0m"
        else
            echo "  ${menu[$i]}"
        fi
    done

    read -rsn1 input
    case $input in
        "A")
            selected=$(( (selected - 1 + ${#menu[@]}) % ${#menu[@]} ))
            ;;
        "B")
            selected=$(( (selected + 1) % ${#menu[@]} ))
            ;;
        "")
            prow "${menu[$selected]}"
            break
            ;;
    esac

    tput cuu "${#menu[@]}"
done