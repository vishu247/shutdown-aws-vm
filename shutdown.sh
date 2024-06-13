#!/bin/bash

# Create tag and their value
TAG_KEY_1="autoShutdown"
TAG_VALUE_1="true"

# Create tag and their value
TAG_KEY_2="pauseShutdown"
TAG_VALUE_2=$(date +'%d-%m-%Y')

export AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SECRET_KEY_ID
aws configure set aws_access_key_id "$AWS_ACCESS_KEY_ID"
aws configure set aws_secret_access_key "$AWS_SECRET_ACCESS_KEY"
aws configure set region "$AWS_REGION"

# Describe instances with the specified region and tags
instances=$(aws ec2 describe-instances --region ${REGION} --query "Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key=='Name'].Value|[0],Tags[?Key=='${TAG_KEY_1}'].Value|[0],Tags[?Key=='${TAG_KEY_2}'].Value|[0]]" --output json)

# Iterate through each instance
echo "${instances}" | jq -c '.[][]' | while read -r instance; do
    instance_id=$(echo "${instance}" | jq -r '.[0]')
    instance_type=$(echo "${instance}" | jq -r '.[1]')
    instance_state=$(echo "${instance}" | jq -r '.[2]')
    instance_name=$(echo "${instance}" | jq -r '.[3]')
    auto_shutdown_tag=$(echo "${instance}" | jq -r '.[4]')
    pause_shutdown_tag=$(echo "${instance}" | jq -r '.[5]')

    # Check if the AutoShutdown tag value matches
    if [ "${auto_shutdown_tag}" == "${TAG_VALUE_1}" ] && [ "${pause_shutdown_tag}" != "${TAG_VALUE_2}" ]; then
        # If the instance is running, stop it
        if [ "${instance_state}" == "running" ]; then
            aws ec2 stop-instances --region ${REGION} --instance-ids "${instance_id}"
            echo "Stopped EC2 instance ${instance_name} (${instance_id}, ${instance_type})"
        else
            # If instance is already stopped in state, then skip the stop action.
            echo "EC2 instance ${instance_name} (${instance_id}, ${instance_type}) have tag ${TAG_KEY_1}:${TAG_VALUE_1} and not in a 'running' state, skipping."
        fi
    elif [ "${auto_shutdown_tag}" == "${TAG_VALUE_1}" ] && [ "${pause_shutdown_tag}" == "${TAG_VALUE_2}" ]; then
        # If the instance has tag paushShutdown then skip shutdown.
        echo "EC2 instance ${instance_name} (${instance_id}, ${instance_type}) has the tags ${TAG_KEY_1}:${TAG_VALUE_1}, ${TAG_KEY_2}:${TAG_VALUE_2} and is in 'running' state, skipping."
    else
        # If instance does not have tag provisioned-by: script, skipping
        echo "EC2 instance ${instance_name} (${instance_id}, ${instance_type}) does not have tag ${TAG_KEY_1}:${TAG_VALUE_1} skipping."
    fi
    echo "============================================================================================================================================="
done
