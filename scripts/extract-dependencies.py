# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

#*************************************************************************************************
# Below is a sample script to extract dependencies from the Terraform state file using jq
# the output can then be used to apply dependencies to the resources in the state file
# in the inject stage above

import json
import os

# Change the working directory to the specified path

script_dir = os.path.dirname(os.path.realpath(__file__))
state_file_path = "../infra/terraform.tfstate.d/geearl-7732-v1.1/terraform.tfstate"
state_file_path = os.path.abspath(os.path.join(script_dir, state_file_path))

# Print the current working directory to confirm the change
print("Current working directory:", os.getcwd())

# Load JSON data from file
with open(state_file_path, 'r') as file:
    data = json.load(file)

# List to store extracted data
extracted_data = []

# Iterate over resources in the JSON data
for resource in data.get('resources', []):
    # Extract required fields from each resource
    resource_data = {
        'mode': resource.get('mode'),
        'type': resource.get('type'),
        'name': resource.get('name'),
        'module': resource.get('module'),
        'provider': resource.get('provider'),
        'instances': []
    }
    
    # Iterate over instances in the resource
    for instance in resource.get('instances', []):
        # Extract required fields from each instance
        instance_data = {
            'dependencies': instance.get('dependencies'),
            'index_key': instance.get('index_key')
        }
        resource_data['instances'].append(instance_data)
    
    extracted_data.append(resource_data)

# Save the extracted data to a file
template_path = os.path.abspath(os.path.join(script_dir, 'tf-dependencies.json'))
with open(template_path, 'w') as outfile:
    json.dump(extracted_data, outfile, indent=4)

#*************************************************************************************************