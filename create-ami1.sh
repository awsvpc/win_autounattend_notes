#! /bin/bash
 
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script will create a windows golden ami.
# If the required DNS entries do not exist, they will be created.
# You must have valid LDAP credentials for invtool in order to create DNS entries.
# You must be connected to the scl3 VPN in order to get a successful run.

# usage:
# try/y-2008:
# $ moztype="y-2008" ./create-ami.sh
# prod/b-2008:
# $ moztype="b-2008" ./create-ami.sh


: ${moztype:?moztype must be set}

sandbox=${sandbox:='/builds/aws_manager'}
aws_source_region=${aws_source_region:='us-east-1'}
aws_target_region=${aws_target_region:='us-west-2'}
target_hostname=${target_hostname:="$moztype-ec2-golden"}

set -e
set -o pipefail
lock_file="$sandbox/$target_hostname.lock"
lockfile -60 -r 3 "$lock_file"
trap "rm -f $lock_file" exit

case "$moztype" in
  "b-2008")
    target_domain="build.releng.use1.mozilla.com"
    target_cname="$target_hostname.build.mozilla.org"
    instance_data="$sandbox/cloud-tools/instance_data/$aws_source_region.instance_data_prod.json"
    ;;
  "y-2008")
    target_domain="try.releng.use1.mozilla.com"
    target_cname="$target_hostname.try.mozilla.org"
    instance_data="$sandbox/cloud-tools/instance_data/$aws_source_region.instance_data_try.json"
    ;;
esac
target_fqdn="$target_hostname.$target_domain"

if [[ $(host $target_cname) = *"not found"* ]]; then
  echo "No DNS entry found for $target_hostname. Creating..."
  target_ip=`$sandbox/bin/python $sandbox/cloud-tools/scripts/free_ips.py -c $sandbox/cloud-tools/configs/$moztype -r $aws_source_region -n1`
  echo "Using IP: $target_ip, FQDN: $target_fqdn, CNAME: $target_cname"
  $sandbox/bin/invtool A create --ip $target_ip --fqdn $target_fqdn --private --description "$target_hostname A record"
  $sandbox/bin/invtool PTR create --ip $target_ip --target $target_fqdn --private --description "$target_hostname reverse mapping"
  $sandbox/bin/invtool CNAME create --fqdn $target_cname --target $target_fqdn --private --description "$target_hostname alias"
  i=1
  while ! host $target_cname; do
    sleep 1m
    let i++
    echo "Slept ${i} minutes, waiting for DNS propagation"
  done
  echo "DNS updated"
fi

cd $sandbox/cloud-tools/scripts
$sandbox/bin/python "$sandbox/cloud-tools/scripts/aws_create_instance.py" -c $sandbox/cloud-tools/configs/$moztype -r $aws_source_region -s aws-releng -k $sandbox/secrets/aws-secrets.json --ssh-key ~/.ssh/aws-ssh-key -i $instance_data --create-ami --ignore-subnet-check --copy-to-region $aws_target_region $target_hostname
echo "Instance created: $target_hostname"

if [ -e "$sandbox/cloud-tools/scripts/$target_hostname.log" ]; then
  if [ -d $sandbox/log ]; then
    python_log="$sandbox/log/$target_hostname.$(date '+%Y%m%d%H%M%S').python.log"
    mv $sandbox/cloud-tools/scripts/$target_hostname.log $python_log
    cat $python_log
  else
    cat $sandbox/cloud-tools/scripts/$target_hostname.log
  fi
fi
