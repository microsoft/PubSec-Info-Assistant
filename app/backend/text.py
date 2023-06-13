# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

def nonewlines(s: str) -> str:
    return s.replace('\n', ' ').replace('\r', ' ')
