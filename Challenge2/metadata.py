
import awscli
import subprocess

keyid = input("Enter AWS AWS Access Key \n")
accesskey = input("Enter AWS Secret Key \n")
region = input("Enter AWS region \n")

subprocess.run(['aws','configure','set','aws_access_key_id',keyid], shell= True)
subprocess.run(['aws','configure','set','aws_secret_access_key',accesskey], shell= True)
subprocess.run(['aws','configure','set','region',region], shell= True)

instanceid = input("Enter the instance id\n")
subprocess.run(['aws','ec2','describe-instances','--instance-ids',instanceid], shell= True)

