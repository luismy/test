# Variables
$instanceId = "i-xxxxxxxxxxxxxx"   # Replace with your EC2 instance ID
$snapshotId = "snap-xxxxxxxxxxxxxx" # Replace with the snapshot ID you want to restore
$availabilityZone = "us-east-1a"    # Replace with the instance's availability zone
$region = "us-east-1"               # Replace with your AWS region

# Stop the instance
Write-Host "Stopping instance $instanceId..."
aws ec2 stop-instances --instance-ids $instanceId --region $region
aws ec2 wait instance-stopped --instance-ids $instanceId --region $region

# Get the current root volume ID
Write-Host "Getting current root volume ID..."
$rootVolumeId = (aws ec2 describe-instances --instance-ids $instanceId --region $region --query "Reservations[].Instances[].BlockDeviceMappings[?DeviceName=='/dev/sda1'].Ebs.VolumeId" --output text)
Write-Host "Current root volume ID: $rootVolumeId"

# Detach the current root volume
Write-Host "Detaching current root volume..."
aws ec2 detach-volume --volume-id $rootVolumeId --region $region
aws ec2 wait volume-available --volume-ids $rootVolumeId --region $region
Write-Host "Detached root volume: $rootVolumeId"

# Create a new volume from the snapshot
Write-Host "Creating a new volume from snapshot $snapshotId..."
$newVolumeId = (aws ec2 create-volume --snapshot-id $snapshotId --availability-zone $availabilityZone --region $region --volume-type gp3 --query "VolumeId" --output text)
Write-Host "New volume created with ID: $newVolumeId"
aws ec2 wait volume-available --volume-ids $newVolumeId --region $region

# Attach the new volume as the root volume
Write-Host "Attaching new volume as root..."
aws ec2 attach-volume --volume-id $newVolumeId --instance-id $instanceId --device /dev/sda1 --region $region
aws ec2 wait volume-in-use --volume-ids $newVolumeId --region $region
Write-Host "New volume attached as root."

# Start the instance
Write-Host "Starting instance $instanceId..."
aws ec2 start-instances --instance-ids $instanceId --region $region
aws ec2 wait instance-running --instance-ids $instanceId --region $region
Write-Host "Instance started."

# Optional: Delete the old root volume
# Uncomment the next lines if you want to delete the old root volume after replacing
# Write-Host "Deleting old root volume $rootVolumeId..."
# aws ec2 delete-volume --volume-id $rootVolumeId --region $region
# Write-Host "Old root volume deleted."
