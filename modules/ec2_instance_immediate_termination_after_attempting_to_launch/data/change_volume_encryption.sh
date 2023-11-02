

#!/bin/bash



# Set variables

INSTANCE_ID=${INSTANCE_ID}

GRANTEE_PRINCIPAL=${GRANTEE_PRINCIPAL}

VOLUME_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId' --output text)

KMS_KEY_ID=$(aws ec2 describe-volumes --volume-ids $VOLUME_ID --query 'Volumes[0].KmsKeyId' --output text)



# Check if volume is encrypted

if [ -n "$KMS_KEY_ID" ]

then

  # Request access to KMS key

  aws kms create-grant --key-id $KMS_KEY_ID --grantee-principal $GRANTEE_PRINCIPAL --operations Decrypt 

  

  # Wait for grant to propagate

  sleep 30

fi