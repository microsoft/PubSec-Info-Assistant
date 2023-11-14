# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.


class Approach:
    """
    An approach is a method for answering a question from a query and a set of
    documents.
    """

    def run(self, history: list[dict], overrides: dict) -> any:
        """
        Run the approach on the query and documents. Not implemented.

        Args:
            history: The chat history. (e.g. [{"user": "hello", "bot": "hi"}])
            overrides: Overrides for the approach. (e.g. temperature, etc.)
        """
        raise NotImplementedError
