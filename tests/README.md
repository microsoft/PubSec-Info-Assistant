# Tests

The `/tests` folder contains a set of functional tests and unit tests. 
Functional tests validate the document pre-processing pipelines from ingestion to Azure AI Search indexing and the Information Assistant Embeddings REST API endpoints. Unit tests validate the 
all the possible variants that a user would configure prior to deployment. 

## Unit tests

Unit tests are located in the `/unit_tests` folder. They are built using the `pytest` library. For more details on `pytest`, follow this [link](https://docs.pytest.org/en/stable/).

### Running All Unit Tests

The recommended way to run all unit tests is by using the following command:

```sh
./scripts/unit-tests.sh --azure_subscription_id <sub-id> --azure_location <location>
```

### Running Tests Directly with pytest

You can also run the tests directly by invoking the Python script with pytest:

```bash
pytest -s test_azd_preprovision.py --azure_subscription_id <sub-id> --azure_location <location> --env unittesting1
```

The -s flag is used for printing debugging output, which is useful when you want to see the details of your test run.

### Running a Specific Test

If you want to run a specific test, you can use the following command and specify the test case name (in this example, it is test_preprovision_script_use_custom_entra_objects_and_app_reg):

```bash
pytest -s test_azd_preprovision.py::test_preprovision_script_use_custom_entra_objects_and_app_reg --azure_subscription_id e91c5fa0-c49c-441b-b1d9-375924d5d3ae --azure_location uksouth --env unittesting1
```

## Functional tests

The functional tests are invoked as needed throughout the development process. They are initiated through:

```sh
./scripts/functional-tests.sh
```

 This script parses the Terraform outputs and environment variables and invokes the Python-based functional tests. The goal of these tests is to ensure that any changes made during the development cycle do not affect the expected processing pipeline outputs from a predetermined set of input files (located in `.\tests`).

To add more test cases, include new files for ingestion into the `.\tests\test_data` folder and name the file `test_example` with the appropriate file type extension for the new test case. A search query for that file will need to be added to the test harness code near the top of the Python file.
