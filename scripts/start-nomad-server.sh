#!/bin/bash
# This script is meant to be run in the User Data of each EC2 Instance while it's booting. The script uses the
# run-nomad and run-consul scripts to configure and start Nomad and Consul in client mode. Note that this script
# assumes it's running in an AMI built from the Packer template in examples/nomad-consul-ami/nomad-consul.json.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# These variables are passed in via Terraform template interplation
sudo service docker start
sudo /opt/consul/bin/run-consul --client --cluster-tag-key ${cluster_tag_key} --cluster-tag-value ${cluster_tag_value}
sleep 100s
sudo /opt/nomad/bin/run-nomad --server --num-servers ${num_of_servers}
sleep 100s
wget https://s3.amazonaws.com/kinetica-se/nomad/nifi.nomad -P /tmp
wget https://s3.amazonaws.com/kinetica-se/nomad/spark.nomad -P /tmp
sudo /usr/local/bin/nomad run /tmp/nifi.nomad
sleep 200
sudo /usr/local/bin/nomad run /tmp/spark.nomad
