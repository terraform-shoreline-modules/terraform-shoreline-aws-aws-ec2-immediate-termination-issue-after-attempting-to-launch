

#!/bin/bash



# Set the variables

INSTANCE_ID=${INSTANCE_ID}



# Check EBS volumes exceed condition

VOLUME_LIMIT_EXCEEDED=$(aws ec2 describe-instances --filters Name=instance-state-name,Values=terminated | grep VolumeLimitExceeded)



if [ -n "$VOLUME_LIMIT_EXCEEDED" ]; then

  # Delete unused volumes

  VOLUMES=$(aws ec2 describe-volumes --query 'Volumes[?State==`available`].VolumeId' --output json --region us-east-1 | jq -r '.[]')

  for VOLUME in $VOLUMES; do

    aws ec2 delete-volume --volume-id $VOLUME

    echo "Deleted volume $VOLUME"

  done

fi