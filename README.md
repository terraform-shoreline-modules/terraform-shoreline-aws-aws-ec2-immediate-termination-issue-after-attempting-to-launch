
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# EC2 instance immediate termination after attempting to launch.
---

This incident type refers to the immediate termination of an EC2 instance after attempting to launch it. There are various reasons why this can occur, such as exceeding EBS volume limits, corrupted EBS snapshots, encrypted root EBS volumes without proper permissions, missing parts in instance store-backed AMIs, among others. The solution to this incident type depends on the termination reason, and it may involve deleting unused volumes or ensuring proper permissions to access AWS KMS keys.

### Parameters
```shell
export INSTANCE_ID="PLACEHOLDER"

export SNAPSHOT_ID="PLACEHOLDER"

export VOLUME_ID="PLACEHOLDER"

export IMAGE_ID="PLACEHOLDER"

export GRANTEE_PRINCIPAL="PLACEHOLDER"
```

## Debug

### Get the instance ID of the terminated instance
```shell
aws ec2 describe-instances --filters Name=instance-state-name,Values=terminated --query 'Reservations[*].Instances[*].InstanceId' --output text
```

### Check if the instance exceeded EBS volume limits
```shell
aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=${INSTANCE_ID} --query 'Volumes[*].{ID:VolumeId,Size:Size,State:State}' --output table
```

### Check if an EBS snapshot is corrupted
```shell
aws ec2 describe-snapshots --snapshot-ids ${SNAPSHOT_ID}
```

### Check if the root EBS volume is encrypted
```shell
aws ec2 describe-volumes --volume-ids ${VOLUME_ID} --query 'Volumes[0].Encrypted' --output text
```

### Check if a snapshot specified in the block device mapping for the AMI is encrypted
```shell
aws ec2 describe-images --image-ids ${IMAGE_ID} --query 'Images[*].BlockDeviceMappings[*].Ebs.Encrypted'
```

### Check if the instance store-backed AMI is missing a required part
```shell
aws ec2 describe-images --image-ids ${IMAGE_ID} --query 'Images[*].ImageLocation'
```

### Get the termination reason of the instance
```shell
aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[*].Instances[*].StateReason.Message'
```

## Repair

### Delete the unused volumes to free up space if EBS volume limits are exceeded.
```shell


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


```

### Request the access to the KMS key if the root EBS volume is encrypted and the user does not have permissions to access the KMS key for decryption. 
```shell


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


```