import argparse
import pytest
import subprocess
import json
import os

def parse_arguments():
    """
    Parse command line arguments using argparse
    """
    parser = argparse.ArgumentParser(description="Run azd preprovision tests")
    parser.add_argument("--azure_subscription_id", required=True, help="Azure subscription ID")
    parser.add_argument("--azure_location", required=True, help="Azure location")
    parser.add_argument("--env", required=True, help="Environment name")
    return parser.parse_args()

def pytest_addoption(parser):
    """
    Add custom command line options to pytest.
    """
    parser.addoption("--azure_subscription_id", action="store", help="Azure subscription ID")
    parser.addoption("--azure_location", action="store", help="Azure location")
    parser.addoption("--env", action="store", help="Environment name")

@pytest.fixture(scope="module")
def azure_subscription_id(request):
    """
    Fixture to get the Azure subscription ID from the command line options.
    """
    return request.config.getoption("--azure_subscription_id")

@pytest.fixture(scope="module")
def azure_location(request):
    """
    Fixture to get the Azure location from the command line options.
    """
    return request.config.getoption("--azure_location")

@pytest.fixture(scope="module")
def env(request):
    """
    Fixture to get the environment name from the command line options.
    """
    return request.config.getoption("--env")

def test_preprovision_script_azureusgov_webchat_enabled(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with AzureUSGovernment environment and webchat enabled.
    Fails on webchat enabled.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    try:
        # Set environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'AZURE_ENVIRONMENT', 'AzureUSGovernment'], check=True)
        subprocess.run(['azd', 'env', 'set', 'USE_WEB_CHAT', 'true'], check=True)
        subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
        subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
        # Verify that the environment variables are set correctly
        env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
        print("Environment Variables:\n", env_vars.stdout)
        # Define the command to run the preprovision step via azd
        command = ['azd hooks run preprovision --debug']
        # Call the command and check the result
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
        print("Command Output:\n", result.stdout)
        print("Command Error Output:\n", result.stderr)
        print("Return Code:", result.returncode)
        # Assert that the command failed with the expected error
        expected_error_message = (
            "Web Chat is not available on AzureUSGovernment deployments. "
            "Check your values for USE_WEB_CHAT and AZURE_ENVIRONMENT."
        )
        assert expected_error_message in result.stdout, "Expected error message not found in stderr"
        assert result.returncode != 0, "Expected the command to fail but it succeeded"
    finally:
        # Clean up environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'AZURE_ENVIRONMENT', ''], check=True)
        subprocess.run(['azd', 'env', 'set', 'USE_WEB_CHAT', ''], check=True)

def test_preprovision_script_azureusgov_webchat_notenabled(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with AzureUSGovernment environment and webchat enabled.
    Should pass.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    # Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AZURE_ENVIRONMENT', 'AzureUSGovernment'], check=True)
    subprocess.run(['azd', 'env', 'set', 'USE_WEB_CHAT', 'false'], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    # Verify that the environment variables are set correctly
    env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables:\n", env_vars.stdout)
    # Define the command to run the preprovision step via azd
    command = ['azd hooks run preprovision --debug']
    # Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
    # Assert that the command ran successfully with no errors
    assert result.returncode == 0, f"Command failed with return code {result.returncode}"
    
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AZURE_ENVIRONMENT', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'USE_WEB_CHAT', ''], check=True)

def test_preprovision_script_existing_openai_rg(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with an existing open ai resource group.
    Script errors because it doesn't have existing open ai details, such as location, service name.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    # Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_RESOURCE_GROUP', 'test_rg'], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    # Verify that the environment variables are set correctly
    env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables:\n", env_vars.stdout)
    # Define the command to run the preprovision step via azd
    command = ['azd hooks run preprovision --debug']
    # Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
    #Assert that the command failed with the expected error
    expected_error_message = (
       "Either both EXISTING_AZURE_OPENAI_RESOURCE_GROUP and EXISTING_AZURE_SERVICE_NAME must be populated, or neither." 
    )
    assert expected_error_message in result.stderr, "Expected error message not found in stderr"
    assert result.returncode != 0, "Expected the command to fail but it succeeded"
        
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_RESOURCE_GROUP', ''], check=True)

# TO DO: update to test for further questions in the script
def test_preprovision_script_existing_openai_resource(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with an existing open ai resource.
    Should prompt user with a warning.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    # Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_RESOURCE_GROUP', 'test_rg'], check=True)
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_SERVICE_NAME', 'test_ai_svc'], check=True)
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_LOCATION', 'uksouth'], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    # Verify that the environment variables are set correctly
    env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables:\n", env_vars.stdout)
    # Define the command to run the preprovision step via azd
    command = 'azd hooks run preprovision --debug'
    # Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    # print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
    # Check if the command is prompting the user with a question
    prompt_text = "Do you want to continue? (y/n):"
    assert prompt_text in result.stdout, "Expected prompt not found in command output"
    # Assert that the command ran successfully with no errors
    assert result.returncode != 0, f"Command failed with return code {result.returncode}"
    assert "Process aborted by user." in result.stdout, "Command was aborted by user."
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_RESOURCE_GROUP', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_SERVICE_NAME', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'EXISTING_AZURE_OPENAI_LOCATION', ''], check=True)

def test_preprovision_script_use_dos(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with DDOS enabled.
    Move on if DDOS plan doesn't exist.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    try:
        # Set environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
        subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
        subprocess.run(['azd', 'env', 'set', 'USE_DDOS_PROTECTION_PLAN', 'true'], check=True)
        # Verify that the environment variables are set correctly
        env_vars = subprocess.run(
            ['azd', 'env', 'get-values'], 
            capture_output=True, 
            text=True, 
            check=True
        )
        print("Environment Variables:\n", env_vars.stdout)
        # Define the command to run the preprovision step via azd
        command = 'azd hooks run preprovision --debug'
        # Call the command and check the result
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
        expected_warning = (
            "No existing DDOS protection plan found. "
            "Terraform will create a new one."
        )
        print("Command Error Output:\n", result.stderr)
        print("Return Code:", result.returncode)
        with open('/workspaces/info-assistant-copilot-template/infra/main.tfvars.json', 'r', encoding='utf-8') as f:
            expected_warning = "No existing DDOS protection plan found. Terraform will create a new one."
            assert expected_warning in result.stderr, "Expected prompt not found in command output"
        # Assert that the command ran successfully with no errors
        assert result.returncode == 0, f"Command failed with return code {result.returncode}"
        # Check that DDOS_PLAN_ID is set to an empty string in main.tfvars.json
        with open('/workspaces/info-assistant-copilot-template/infra/main.tfvars.json', 'r', encoding='utf-8') as f:
            tfvars = json.load(f)
            assert tfvars.get('ddos_plan_id') == "", "DDOS_PLAN_ID is not set to an empty string"
    finally:
        # Clean up environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'USE_DDOS_PROTECTION_PLAN', ''], check=True)

#This cannot be tested, it requires a subscription with DDOS enabled.
def test_preprovision_script_use_existing_ddos_plan(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with DDOS enabled and an existing DDOS plan.
    """

def test_preprovision_script_use_existing_ddos_plan_id(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script with DDOS enabled and a ddos plan id.
    Should pass and set DDOS_PLAN_ID in tfvars.json.
    """
    try: 
        ddos_plan_id =  '/subscriptions/b13f2a48-3217-4d41-a44d-4a078dd14f30/resourceGroups/mcfps-rg-hub-network-eastus2-isa/providers/Microsoft.Network/ddosProtectionPlans/mcfps-ddos-plan-eastus2-isa'
        # List existing environments
        env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
        existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
        # Check if the environment already exists
        if env in existing_envs:
            # Select the existing environment
            subprocess.run(['azd', 'env', 'select', env], check=True)
        else:
            # Create a new environment
            subprocess.run(['azd', 'env', 'new', env], check=True)
        # Set environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
        subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
        subprocess.run(['azd', 'env', 'set', 'USE_DDOS_PROTECTION_PLAN', 'true'], check=True)
        subprocess.run(['azd', 'env', 'set', 'DDOS_PLAN_ID', ddos_plan_id], check=True)
        # Verify that the environment variables are set correctly
        env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
        print("Environment Variables:\n", env_vars.stdout)
        # Define the command to run the preprovision step via azd
        command = 'azd hooks run preprovision --debug'
        # Call the command and check the result
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
        print("Command Output:\n", result.stdout)
        print("Command Error Output:\n", result.stderr)
        print("Return Code:", result.returncode)
        # Check if the command gives a warning that the DDOS_PLAN_ID is set
        expected_warning = "Using provided DDOS Protection Plan ID from environment: " + ddos_plan_id
        assert expected_warning in result.stderr, "Expected prompt not found in command output"
        # Assert that the command ran successfully with no errors
        assert result.returncode == 0, f"Command failed with return code {result.returncode}"
        # Check that DDOS_PLAN_ID is set in main.tfvars.json
        with open('/workspaces/info-assistant-copilot-template/infra/main.tfvars.json', 'r', encoding='utf-8') as f:
            tfvars = json.load(f)
            assert tfvars.get('ddos_plan_id') == ddos_plan_id, "DDOS_PLAN_ID is not set to the correct value"
    
    finally:
        # Clean up environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'USE_DDOS_PROTECTION_PLAN', ''], check=True)
        subprocess.run(['azd', 'env', 'set', 'DDOS_PLAN_ID', ''], check=True)

def test_preprovision_script_from_pipeline_true(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script when from pipeline is set to true.
    Should fail with a warning that the BUILD_BUILDNUMBER is required.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    # Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    subprocess.run(['azd', 'env', 'set', 'FROM_PIPELINE', 'true'], check=True)
    # Verify that the environment variables are set correctly
    env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables:\n", env_vars.stdout)
    # Define the command to run the preprovision step via azd
    command = 'azd hooks run preprovision --debug'
    # Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
    # Assert that the command failed with the expected warning
    expected_warning = "Require BUILD_BUILDID to be set for CI builds"
    assert expected_warning in result.stdout, "Expected warning not found in command output"
    # Assert that the command failed
    assert result.returncode != 0, f"Command failed with return code {result.returncode}"
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'FROM_PIPELINE', ''], check=True)

def test_preprovision_script_from_pipeline_true_with_build_id(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script when from pipeline is set to true and build id is set.
    Should pass and create ./infra/provider.conf.json.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    
    # Initialize file_path variable
    file_path = os.path.join(os.path.dirname(__file__), '../../.', 'infra', 'provider.conf.json')
    
    try:
        # Set environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
        subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
        subprocess.run(['azd', 'env', 'set', 'FROM_PIPELINE', 'true'], check=True)
        subprocess.run(['azd', 'env', 'set', 'BUILD_BUILDID', '123'], check=True)
        # Verify that the environment variables are set correctly
        env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
        print("Environment Variables:\n", env_vars.stdout)
        # Define the command to run the preprovision step via azd
        command = 'azd hooks run preprovision --debug'
        # Call the command and check the result
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
        print("Command Output:\n", result.stdout)
        print("Command Error Output:\n", result.stderr)
        print("Return Code:", result.returncode)
        # Assert that the command is successful
        assert result.returncode == 0, f"Command failed with return code {result.returncode}"
        # Check that the file ./infra/provider.conf.json is created
        assert os.path.exists(file_path), "provider.conf.json file was not created"
    finally:
        # Clean up environment variables using azd
        subprocess.run(['azd', 'env', 'set', 'FROM_PIPELINE', ''], check=True)
        subprocess.run(['azd', 'env', 'set', 'BUILD_BUILDID', ''], check=True)
        # Remove the provider.conf.json file
        if os.path.exists(file_path):
            os.remove(file_path)
        # Revert the action by copying backend.tf.ci to backend.tf
        subprocess.run(['mv', '../../infra/backend.tf', '../../infra/backend.tf.ci'], check=True)

def test_preprovision_script_use_custom_entra_objects(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script when when use custom entra objects is set to true.
    Should fail indicating App  Reg should be set up.
    """
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    #Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    subprocess.run(['azd', 'env', 'set', 'USE_CUSTOM_ENTRA_OBJECTS', 'true'], check=True)
    #Verify that the environment variables are set correctly
    env_vars = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables:\n", env_vars.stdout)
    #Define the command to run the preprovision step via azd
    command = 'azd hooks run preprovision --debug'
    #Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
     # Assert that the command failed with the expected error
    expected_error_message = (
        "An Azure AD App Registration and Service Principal must be manually created for the targeted workspace."
     )
    assert expected_error_message in result.stdout, "Expected error message not found in stderr"
    assert result.returncode != 0, "Expected the command to fail but it succeeded"
               
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'USE_CUSTOM_ENTRA_OBJECTS', ''], check=True)
    
def test_preprovision_script_use_custom_entra_objects_and_app_reg(azure_subscription_id, azure_location, env):
    """
    Test the preprovision script when when use custom entra objects is set to true.
    Should fail indicating App  Reg should be set up.
    """
    ad_webapp_client_id = '1234234'
    ad_mgmtapp_client_id = '123123'
    ad_mgmt_service_principal_id = '123123'
    # List existing environments
    env_list_result = subprocess.run(['azd', 'env', 'list'], capture_output=True, text=True, check=True)
    existing_envs = [line.split()[0] for line in env_list_result.stdout.splitlines() if line and not line.startswith('NAME')]
    # Check if the environment already exists
    if env in existing_envs:
        # Select the existing environment
        subprocess.run(['azd', 'env', 'select', env], check=True)
    else:
        # Create a new environment
        subprocess.run(['azd', 'env', 'new', env], check=True)
    
    #Set environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AZURE_SUBSCRIPTION_ID', azure_subscription_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AZURE_LOCATION', azure_location], check=True)
    subprocess.run(['azd', 'env', 'set', 'USE_CUSTOM_ENTRA_OBJECTS', 'true'], check=True)
    subprocess.run(['azd', 'env', 'set', 'AD_WEBAPP_CLIENT_ID', ad_webapp_client_id], check=True)
    subprocess.run(['azd', 'env', 'set', 'AD_MGMTAPP_CLIENT_ID', ad_mgmtapp_client_id], check=True)
    subprocess.run(
        ['azd', 'env', 'set', 'AD_MGMT_SERVICE_PRINCIPAL_ID', ad_mgmt_service_principal_id], 
        check=True
    )
    #Verify that the environment variables are set correctly
    env_vars = subprocess.run(
        ['azd', 'env', 'get-values'], 
        capture_output=True, 
        text=True, 
        check=True
    )
    print("Environment Variables:\n", env_vars.stdout)
    #Define the command to run the preprovision step via azd
    command = 'azd hooks run preprovision --debug'
    #Call the command and check the result
    result = subprocess.run(command, shell=True, capture_output=True, text=True, check=False)
    print("Command Output:\n", result.stdout)
    print("Command Error Output:\n", result.stderr)
    print("Return Code:", result.returncode)
    # Verify that the environment variables are still set correctly after running the command
    env_vars_after = subprocess.run(['azd', 'env', 'get-values'], capture_output=True, text=True, check=True)
    print("Environment Variables After Command:\n", env_vars_after.stdout)
    # Check that the new environment variables are still set correctly
    assert f'AD_WEBAPP_CLIENT_ID={ad_webapp_client_id}' in env_vars_after.stdout, "AD_WEBAPP_CLIENT_ID not set correctly after command"
    assert f'AD_MGMTAPP_CLIENT_ID={ad_mgmtapp_client_id}' in env_vars_after.stdout, "AD_MGMTAPP_CLIENT_ID not set correctly after command"
    assert f'AD_MGMT_SERVICE_PRINCIPAL_ID={ad_mgmt_service_principal_id}' in env_vars_after.stdout, "AD_MGMT_SERVICE_PRINCIPAL_ID not set correctly after command"
    # Assert that the command is successful
    assert result.returncode == 0, f"Command failed with return code {result.returncode}"
    # Clean up environment variables using azd
    subprocess.run(['azd', 'env', 'set', 'AD_WEBAPP_CLIENT_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'AD_MGMTAPP_CLIENT_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'AD_MGMT_SERVICE_PRINCIPAL_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'AAD_WEB_CLIENT_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'AAD_MGMT_SP_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'AAD_MGMT_CLIENT_ID', ''], check=True)
    subprocess.run(['azd', 'env', 'set', 'USE_CUSTOM_ENTRA_OBJECTS', ''], check=True)

if __name__ == "__main__":
    args = parse_arguments()
    pytest.main()