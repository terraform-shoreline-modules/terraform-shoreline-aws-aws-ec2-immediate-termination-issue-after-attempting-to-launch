resource "shoreline_notebook" "ec2_instance_immediate_termination_after_attempting_to_launch" {
  name       = "ec2_instance_immediate_termination_after_attempting_to_launch"
  data       = file("${path.module}/data/ec2_instance_immediate_termination_after_attempting_to_launch.json")
  depends_on = [shoreline_action.invoke_ec2_delete_unused_volumes,shoreline_action.invoke_change_volume_encryption]
}

resource "shoreline_file" "ec2_delete_unused_volumes" {
  name             = "ec2_delete_unused_volumes"
  input_file       = "${path.module}/data/ec2_delete_unused_volumes.sh"
  md5              = filemd5("${path.module}/data/ec2_delete_unused_volumes.sh")
  description      = "Delete the unused volumes to free up space if EBS volume limits are exceeded."
  destination_path = "/tmp/ec2_delete_unused_volumes.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "change_volume_encryption" {
  name             = "change_volume_encryption"
  input_file       = "${path.module}/data/change_volume_encryption.sh"
  md5              = filemd5("${path.module}/data/change_volume_encryption.sh")
  description      = "Request the access to the KMS key if the root EBS volume is encrypted and the user does not have permissions to access the KMS key for decryption."
  destination_path = "/tmp/change_volume_encryption.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_ec2_delete_unused_volumes" {
  name        = "invoke_ec2_delete_unused_volumes"
  description = "Delete the unused volumes to free up space if EBS volume limits are exceeded."
  command     = "`chmod +x /tmp/ec2_delete_unused_volumes.sh && /tmp/ec2_delete_unused_volumes.sh`"
  params      = ["INSTANCE_ID"]
  file_deps   = ["ec2_delete_unused_volumes"]
  enabled     = true
  depends_on  = [shoreline_file.ec2_delete_unused_volumes]
}

resource "shoreline_action" "invoke_change_volume_encryption" {
  name        = "invoke_change_volume_encryption"
  description = "Request the access to the KMS key if the root EBS volume is encrypted and the user does not have permissions to access the KMS key for decryption."
  command     = "`chmod +x /tmp/change_volume_encryption.sh && /tmp/change_volume_encryption.sh`"
  params      = ["INSTANCE_ID","VOLUME_ID","GRANTEE_PRINCIPAL"]
  file_deps   = ["change_volume_encryption"]
  enabled     = true
  depends_on  = [shoreline_file.change_volume_encryption]
}

