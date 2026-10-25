#!/bin/bash
ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="koladaws.store"
hosted_zone_id="Z03424011UR1W3TZ11HCW"

for instance in $@
do
    echo "creating instance: ${instance}"
done