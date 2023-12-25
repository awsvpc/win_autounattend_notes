#! /bin/bash
 
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# This script will create a windows testing instance from the same base ami that is used by golden.
# If the required DNS entries do not exist, they will be created.
# You must have valid LDAP credentials for invtool in order to create DNS entries.
# You must be connected to the scl3 VPN in order to get a successful run.

# usage:
# try/y-2008:
# $ moztype="y-2008" ./create-instance.sh
# prod/b-2008:
# $ moztype="b-2008" ./create-instance.sh


: ${moztype:?moztype must be set}
: ${bug:?bug must be set}

sandbox=${sandbox:='/builds/aws_manager'}
user=${user:=$(whoami)}
email=${sandbox:="$user@mozilla.com"}
target_hostname=${target_hostname:="$moztype-ec2-$user"}
target_region=${target_region:="us-east-1"}
secrets=${secrets:="$sandbox/secrets/aws-secrets.json"}

case "$target_region" in
  "us-east-1")
    target_dns_atom="use1"
    ;;
  "us-west-2")
    target_dns_atom="usw2"
    ;;
esac
case "$moztype" in
  "b-2008")
    target_domain="build.releng.$target_dns_atom.mozilla.com"
    target_cname="$target_hostname.build.mozilla.org"
    instance_data="$sandbox/cloud-tools/instance_data/$target_region.instance_data_prod.json"
    ;;
  "y-2008")
    target_domain="try.releng.$target_dns_atom.mozilla.com"
    target_cname="$target_hostname.try.mozilla.org"
    instance_data="$sandbox/cloud-tools/instance_data/$target_region.instance_data_try.json"
    ;;
esac
target_fqdn="$target_hostname.$target_domain"

if [[ $(host $target_cname) = *"not found"* ]]; then
  echo "No DNS entry found for $target_hostname. Creating..."
  target_ip=`$sandbox/bin/python $sandbox/cloud-tools/scripts/free_ips.py -c $sandbox/cloud-tools/configs/$moztype -r $target_region -n1`
  echo "Using IP: $target_ip, FQDN: $target_fqdn, CNAME: $target_cname"
  $sandbox/bin/invtool A create --ip $target_ip --fqdn $target_fqdn --private --description "bug $bug: loaner for $user"
  $sandbox/bin/invtool PTR create --ip $target_ip --target $target_fqdn --private --description "bug $bug: loaner for $user"
  $sandbox/bin/invtool CNAME create --fqdn $target_cname --target $target_fqdn --private --description "bug $bug: loaner for $user"
  i=1
  while ! host $target_cname; do
    sleep 1m
    let i++
    echo "Slept ${i} minutes, waiting for DNS propagation"
  done
  echo "DNS updated"
fi

cd $sandbox/cloud-tools/scripts
python "$sandbox/cloud-tools/scripts/aws_create_instance.py" \
  -c "$sandbox/cloud-tools/configs/$moztype" \
  -r $target_region \
  -s aws-releng \
  --loaned-to $email --bug $bug -k $secrets \
  --ssh-key ~/.ssh/aws-ssh-key \
  -i $instance_data $target_hostname

if [ -e "$sandbox/cloud-tools/scripts/$target_hostname.log" ]; then
  if [ -d $sandbox/log ]; then
    python_log="$sandbox/log/$target_hostname.$(date '+%Y%m%d%H%M%S').python.log"
    mv $sandbox/cloud-tools/scripts/$target_hostname.log $python_log
    cat $python_log
  else
    cat $sandbox/cloud-tools/scripts/$target_hostname.log
  fi
fi
