# Tests

The `/tests` folder contains a set of functional tests that validate the document pre-processing pipelines from ingestion to Azure AI Search indexing and the Info Assistant Embeddings REST API endpoints.

## Functional tests

The functional test are invoked as needed throughout the development process. It is initiated through a `make functional-tests` command which calls the `.\scripts\functional-tests.sh` script, which in turn parses the Bicep outputs and environment variables and invokes the Python-based functional tests. The goal of these is to make sure that throughout our development cycle, any changes made does not effect the expected processing pipeline outputs from a pre-determined set of input files (located in `.\tests`).

To add more test cases, include new files for ingestions into the `.\tests\test_data` folder and name the file `test_example` with the filetype extension appropriate for the new test case.
A search query for that file will need to be added to the test harness code near the top of the python file.
