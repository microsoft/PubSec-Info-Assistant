from pytest import fixture

def pytest_addoption(parser):
    """
    Add custom command line options to pytest.
    """
    parser.addoption("--azure_subscription_id", action="store", help="Azure subscription ID")
    parser.addoption("--azure_location", action="store", help="Azure location")
    parser.addoption("--env", action="store", help="Environment name")
