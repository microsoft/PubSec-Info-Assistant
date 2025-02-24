# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

# This script updates the imported terraform state file with required
# values that are not suppported or possible with the terraform import command

import json
import os
from pyfiglet import Figlet

f = Figlet()
print(f.renderText('Inject Dependencies'))
print()
print('This script updates the imported terraform state file with required')
print('values that are not supported or possible with the terraform import command.')
print()

# if 'infra_output.json' does not exist
cwd = os.getcwd()  # Get the current working directory
print(cwd)

config_file_path = os.path.join(cwd, "upgrade_repoint.config.json")
with open(config_file_path, 'r') as file:
    old_env = json.load(file)
    rg_name = old_env['old_env']['resource_group']
    random_text = old_env['old_env']['random_text'].lower()    
    

script_dir = os.path.dirname(os.path.realpath(__file__))
workspace = rg_name.replace("infoasst-", "")
state_file_path = f"../infra/terraform.tfstate.d/{workspace}/terraform.tfstate"
state_file_path = os.path.abspath(os.path.join(script_dir, state_file_path))

script_dir = os.path.dirname(os.path.realpath(__file__))
dependencies_file_path = "tf-dependencies.json"
dependencies_file_path = os.path.abspath(os.path.join(script_dir, dependencies_file_path))


# **********************************************************
# Update the random text resource with required values

print("Opening the state file... ", state_file_path)

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

# Iterate through each resource in the dependencies template
for state_resource in tf_imported_state['resources']:
    for template_resource in tf_dependencies_template:  # Directly iterate over the list
            if (template_resource.get('type') == state_resource.get('type') and
                template_resource.get('module') == state_resource.get('module') and
                template_resource.get('name') == state_resource.get('name')):
                
                for state_instance in state_resource.get('instances', []):
                    # Merge dependencies                              
                    state_instance['dependencies'] = template_resource['instances'][0].get('dependencies', [])

   
# Save the merged result
with open(state_file_path, 'w') as f:
    json.dump(tf_imported_state, f, indent=2)
    
# **********************************************************

print('Done')