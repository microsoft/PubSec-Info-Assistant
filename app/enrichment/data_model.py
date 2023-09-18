# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

from typing import List

import pydantic

# === Data Models ===


class ModelInfo(pydantic.BaseModel):
    model: str
    max_seq_length: int
    vector_size: int


class Embedding(pydantic.BaseModel):
    object: str = "embedding"
    index: int
    embedding: List[float]


class EmbeddingResponse(pydantic.BaseModel):
    object: str = "list"
    data: List[Embedding]
    embedding_id: str
    model: str
    model_info: ModelInfo


class EmbeddingRequest(pydantic.BaseModel):
    sentences: List[str]


class ModelListResponse(pydantic.BaseModel):
    models: List[ModelInfo]


class StatusResponse(pydantic.BaseModel):
    status: str
    uptime_seconds: float
    version: str
