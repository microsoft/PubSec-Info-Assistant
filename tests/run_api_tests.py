# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

'''
Command line functional test runner
'''
import argparse
import random
import string
import requests
from rich.console import Console
import rich.traceback


rich.traceback.install()
console = Console()

class TestFailedError(Exception):
    """Exception raised when a test fails."""

# Define top-level variables
TIMEOUT_VALUE = 60

def parse_arguments():
    """
    Parse command line arguments
    Note that extract_env must be ran before this script is invoked
    """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--enrichment_service_endpoint",
        required=True,
        help="Azure Search Endpoint")
    parser.add_argument(
        "--azure_websites_domain",
        default="False",
        help="Base domain for Azure Websites (e.g. azurewebsites.net)")

    return parser.parse_args()

def main(enrichment_service_endpoint, azure_websites_domain):
    """Main function to run API functional tests for Enrichment App"""
    try:
        console.print("Begin API tests...")

        # Define the base URL for the API
        base_url = ""

        base_url = f"https://{enrichment_service_endpoint}.${azure_websites_domain}/models"

        #Run requests and check responses
        response_data = get_models(base_url)
        get_models_detail(base_url, response_data)
        post_embeddings_check(base_url, response_data)


    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

def get_models(base_url):
    """Fetch list of available models via GET endpoint"""

    # Perform a GET request to /models
    response = requests.get(f"{base_url}", verify=False, timeout=TIMEOUT_VALUE)

    # Check the response status code
    if response.status_code == 200:
        console.print("[green]GET /models returned 200 OK[/green]")

        # Parse the JSON response body
        return response.json()

    else:
        console.print(f"[red]GET /models returned {response.status_code}[/red]")
        raise TestFailedError(f"GET /models returned {response.status_code}")

def get_models_detail(base_url, response_data):
    """Get models detail based on initial request"""

    if "models" in response_data:
        for model_info in response_data["models"]:
            model_name = model_info.get("model")

            # Perform a GET request to /models/{model}
            model_response = requests.get(f"{base_url}/{model_name}", verify=False, timeout=TIMEOUT_VALUE)

            # Check the response status code
            if model_response.status_code == 200:
                console.print(f"[green]GET /models/{model_name} returned 200 OK[/green]")
            else:
                console.print(f"[red]GET /models/{model_name} returned {model_response.status_code}[/red]")
                raise TestFailedError(f"GET /models/{model_name} returned {model_response.status_code}")
    else:
        console.print("[red]Response does not contain 'models' key[/red]")
        raise TestFailedError("Response does not contain 'models' key")

def post_embeddings_check(base_url, response_data):
    """Check embeddings post endpoint using available sentence transformers."""
    try:

        for model_info in response_data["models"]:
            model_name = model_info.get("model")
            if model_name.startswith('azure-openai_'):
                continue

            # Generate some random text data
            random_text = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))

            # Perform a POST request to /models/{model}/embed
            post_data = [random_text]
            post_response = requests.post(f"{base_url}/{model_name}/embed", json=post_data, verify=False, timeout=TIMEOUT_VALUE)

            # Check the response status code
            if post_response.status_code // 100 == 2:
                console.print(f"[green]POST /models/{model_name}/embed returned {post_response.status_code} OK[/green]")

                # Check for data in the response body
                if post_response.json().get("data"):
                    console.print(f"[green]Response body contains data[/green]")
                else:
                    console.print(f"[red]Response body does not contain data[/red]")
                    raise TestFailedError("Response body does not contain data")
            else:
                console.print(f"[red]POST /models/{model_name}/embed returned {post_response.status_code}[/red]")
                raise TestFailedError(f"POST /models/{model_name}/embed returned {post_response.status_code}")

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex

if __name__ == '__main__':
    args = parse_arguments()
    main(args.enrichment_service_endpoint, args.azure_websites_domain)
