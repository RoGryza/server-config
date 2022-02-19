#!/bin/env python
import json
import subprocess
import sys
from base64 import b64decode

def gpg_decrypt(secret: bytes) -> str:
    cmd = subprocess.run(
        args=["gpg", "--batch", "-d"],
        input=secret,
        check=True,
        capture_output=True,
    )
    return cmd.stdout.decode('ascii')

def decrypt_aws_secret(secret: str) -> str:
    return gpg_decrypt(b64decode(secret))

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
                    'access_key_id': outputs['wasabi_server_backup_access_key_id']['value'],
                    'access_key_secret': decrypt_aws_secret(
                        outputs['wasabi_server_backup_access_key_secret']['value']
                    ),
                },
            },
        }
    }
}

json.dump(hosts, sys.stdout, separators=(',',':'))
