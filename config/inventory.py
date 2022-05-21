#!/bin/env python
import json
import sys

# TODO validate outputs format
with open("../terraform/terraform.tfstate") as f:
    outputs = json.load(f)['outputs']

hosts = {
    "hosts": ["rogryza.me"],
    "_meta": {
        "hostvars": {
            "rogryza.me": {
                'ansible_host': outputs['ip']['value'],
                'ansible_port': outputs['ssh_port']['value'],
                'ansible_user': 'rogryza',
                'ansible_become_password': outputs['admin_password']['value'],

                'server_backup_bucket': {
                    'name': outputs['b2_server_backup_bucket_name']['value'],
                    'access_key_id': outputs['b2_server_backup_access_key_id']['value'],
                    'access_key_secret': outputs['b2_server_backup_access_key']['value'],
                },
            },
        }
    }
}

json.dump(hosts, sys.stdout, separators=(',',':'))
