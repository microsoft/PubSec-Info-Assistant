# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

'''
Command line functional test runner
'''
import argparse
import requests
from rich.console import Console
import rich.traceback

rich.traceback.install()
console = Console()

class TestFailedError(Exception):
    """Exception raised when a test fails"""

# Define top-level variables
TIMEOUT_VALUE = 10

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

    return parser.parse_args()

def main(enrichment_service_endpoint):
    """Main function to run API functional tests"""
    try:
        console.print("Begin API tests...")

        # Define the base URL for the API
        base_url = f"https://{enrichment_service_endpoint}.azurewebsites.net/models"

        # Perform a GET request to /models
        response = requests.get(f"{base_url}", verify=False, timeout=TIMEOUT_VALUE)

        # Check the response status code
        if response.status_code == 200:
            console.print("[green]GET /models returned 200 OK[/green]")

            # Parse the JSON response body
            response_data = response.json()

            # Check for the expected structure
            if "models" in response_data:
                for model_info in response_data["models"]:
                    model_name = model_info.get("model")
                    vector_size = model_info.get("vector_size")

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
        else:
            console.print(f"[red]GET /models returned {response.status_code}[/red]")
            raise TestFailedError(f"GET /models returned {response.status_code}")

    except (Exception, TestFailedError) as ex:
        console.log(f'[red]❌ {ex}[/red]')
        raise ex


if __name__ == '__main__':
    args = parse_arguments()
    main(args.enrichment_service_endpoint)
