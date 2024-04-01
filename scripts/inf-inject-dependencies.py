# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script updates the imported terraform state file with required
# values that are not suppported or possible with the terraform import command

import json
import os
import sys

script_dir = os.path.dirname(os.path.realpath(__file__))
state_file_path = "../infra/terraform.tfstate.d/geearl-1973-v1.0/terraform.tfstate"
state_file_path = os.path.abspath(os.path.join(script_dir, state_file_path))
dependencide_file_path = script_dir


# **********************************************************
# Update the random text resource with required values

with open(state_file_path, 'r') as file:
    data = json.load(file)

# New attributes to be updated or added
updated_attributes = {
    "keepers": None,
    "length": 5,
    "lower": True,
    "min_lower": 0,
    "min_numeric": 0,
    "min_special": 0,
    "min_upper": 0,
    "number": False,
    "override_special": None,
    "special": False,
    "upper": False
}

# Update logic
for resource in data['resources']:
    if resource['mode'] == 'managed' and resource['type'] == 'random_string' and resource['name'] == 'random':
        # Assume there is only one instance in the instances array
        instance = resource['instances'][0]
        # Update the attributes, keeping existing ones and updating or adding from updated_attributes
        instance['attributes'].update(updated_attributes)

# Write the updated JSON data back to the same file
with open(state_file_path, 'w') as file:
    json.dump(data, file, indent=2)        
    
# **********************************************************



# **********************************************************
# Apply the dependencies to the imported state file

# Read JSON files
with open(os.path.join(script_dir, 'tf-dependencies.json')) as f:
    tf_dependencies_template = json.load(f)

with open(state_file_path) as f:
    tf_imported_state = json.load(f)
    


# # Iterate through each resource in the dependencies template
# for template_resource in tf_dependencies_template:  # Directly iterate over the list
#     for template_instance in template_resource.get('instances', []):
#         # Find the matching resource and instance in the imported state
#         for state_resource in tf_imported_state['resources']:
#             if (template_resource['type'] == state_resource['type'] and
#                 template_resource.get('module') == state_resource.get('module') and
#                 template_resource['name'] == state_resource['name']):
#                 for state_instance in state_resource.get('instances', []):
#                     # if (state_instance['attributes'].get('display_name') == template_instance.get('attributes', {}).get('display_name') and
#                     #     state_instance['attributes'].get('id') == template_instance.get('attributes', {}).get('id')):
#                         # Merge dependencies
#                         state_instance['dependencies'] = template_instance.get('dependencies', [])



# Iterate through each resource in the dependencies template
for template_resource in tf_dependencies_template:  # Directly iterate over the list
    for template_instance in template_resource.get('instances', []):
        # Find the matching resource and instance in the imported state
        for state_resource in tf_imported_state['resources']:
            if state_resource['type'] == "azurerm_role_assignment" and template_resource['type'] == "azurerm_role_assignment" :
                if (template_resource['type'] == state_resource['type'] and
                    template_resource['name'] == state_resource['name']):
                    for state_instance in state_resource.get('instances', []):
 
 
                          
                        if state_resource['type'] == 'azurerm_role_assignment':
                            print('hello')

                        # Merge dependencies                              
                        state_instance['dependencies'] = template_resource['instances'][0].get('dependencies', [])


# Save the merged result
with open('merged_doc.json', 'w') as f:
    json.dump(tf_imported_state, f, indent=2)
    
# **********************************************************



#*************************************************************************************************
# Below is a sample script to extract dependencies from the Terraform state file using jq
# the output can then be used to apply dependencies to the resources in the state file
# in the inject stage above

# import json
# import os

# # Change the working directory to the specified path
# os.chdir('/workspaces/infoassist-reston/scripts')

# # Print the current working directory to confirm the change
# print("Current working directory:", os.getcwd())

# # Load JSON data from file
# with open('terraform.tfstate', 'r') as file:
#     data = json.load(file)

# # List to store extracted data
# extracted_data = []

# # Iterate over resources in the JSON data
# for resource in data.get('resources', []):
#     # Extract required fields from each resource
#     resource_data = {
#         'mode': resource.get('mode'),
#         'type': resource.get('type'),
#         'name': resource.get('name'),
#         'provider': resource.get('provider'),
#         'instances': []
#     }
    
#     # Iterate over instances in the resource
#     for instance in resource.get('instances', []):
#         # Extract required fields from each instance
#         instance_data = {
#             'dependencies': instance.get('dependencies'),
#             'index_key': instance.get('index_key')
#         }
#         resource_data['instances'].append(instance_data)
    
#     extracted_data.append(resource_data)

# # Save the extracted data to a file
# with open('tf-dependencies.json', 'w') as outfile:
#     json.dump(extracted_data, outfile, indent=4)

#*************************************************************************************************