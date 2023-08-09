# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import csv
from os import path
from typing import Optional

from langchain.agents import Tool


class CsvLookupTool(Tool):
    def __init__(
        self,
        filename: path,
        key_field: str,
        name: str = "lookup",
        description: str = "useful to look up details given an input key as opposite to searching data with an unstructured question",
    ):
        super().__init__(name, self.lookup, description)
        self.data = {}
        with open(filename, newline="") as csvfile:
            reader = csv.DictReader(csvfile)
            for row in reader:
                self.data[row[key_field]] = "\n".join([f"{i}:{row[i]}" for i in row])

    def lookup(self, key: str) -> Optional[str]:
        return self.data.get(key, "")
