"""
This module configures logging, tracing, and metrics for the application.

It sets up logging with Azure Monitor, configures OpenTelemetry for tracing and metrics,
and instruments FastAPI and Requests if an app is provided.

Functions:
    configure_monitoring(app=None, logger_name: str = __name__) -> logging.Logger
"""

# Standard library imports
import logging

# Third-party imports
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace, metrics
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

# Local imports


def configure_monitoring(app=None, logger_name: str = __name__) -> tuple:
    """
    Configures logging, tracing, and metrics for the application.

    This function sets up logging with Azure Monitor, configures OpenTelemetry
    for tracing and metrics, and instruments FastAPI and Requests if an app is provided.

    Args:
        app (FastAPI, optional): The FastAPI application instance to instrument. Defaults to None.
        logger_name (str, optional): The name of the logger to configure. Defaults to __name__.

    Returns:
        tuple: A tuple containing the configured logger, tracer provider, and meter provider.
    """

    # Configure Azure Monitor
    configure_azure_monitor(
        logger_name=logger_name,
        enable_live_metrics=True,
    )

    # Configure logging
    log = logging.getLogger(logger_name)
    log.setLevel(logging.DEBUG)
    log.propagate = True

    # Create a resource with the application version
    resource = Resource.create({
        "service.name": "info-assistant-agent-template-backend",
        "service.version": app.version if app else "unknown"
    })

    # Configure tracing
    trace.set_tracer_provider(TracerProvider(resource=resource))
    trace_provider = trace.get_tracer_provider()
    span_processor = BatchSpanProcessor(OTLPSpanExporter())
    trace_provider.add_span_processor(span_processor)

    # Configure metrics
    metric_exporter = OTLPMetricExporter()
    metric_reader = PeriodicExportingMetricReader(metric_exporter)
    meter_provider = MeterProvider(metric_readers=[metric_reader])
    metrics.set_meter_provider(meter_provider)

    # Instrument FastAPI and Requests if app is provided
    if app:
        FastAPIInstrumentor.instrument_app(app)
    RequestsInstrumentor().instrument()

    return log, trace_provider, meter_provider
