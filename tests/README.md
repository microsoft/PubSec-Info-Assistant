# Tests

This folder contains a functional test, which are used to validate the pipeline works as designed.

## Functional tests

The functional test are invoked as needed throughout the development process. It is initiated through a `make functional-tests` command which calls the `.\scripts\functional-tests.sh` script, which in turn parses the Terraform outputs and environment variables and invokes the Python-based functional tests. The goal of these is to make sure that throughout our development cycle, any changes made does not effect the expected processing pipeline outputs from a pre-determined set of input files (located in `.\tests`).