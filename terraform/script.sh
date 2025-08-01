#!/bin/bash

#This is the path of the directory
SOURCE="/home/ubuntu/cont"

#Name of the bucket and destination
BUCKET_NAME="bucket_name"
DESTINATION="s3://${BUCKET_NAME}/backups/$(date +%F-%T)/"  #Each backup will have its own directory with date and time
 
#Push to s3, to execute this script, it must have the aws cli in our ec2
aws s3 cp "$SOURCE" "$DESTINATION" --recursive #recursive allows to copy all in the directory of the source 

