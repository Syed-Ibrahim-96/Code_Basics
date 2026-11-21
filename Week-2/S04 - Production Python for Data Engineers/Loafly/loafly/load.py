
# loafly/load.py

import logging
import os
import time

from gateway import save_to_orders_api
from loafly.config import SETTINGS


logger = logging.getLogger(__name__)


def load_orders(orders):

    currency = SETTINGS["currency"]
    retries = SETTINGS["retry_count"]

    # Read API key from environment variable
    api_key = os.getenv("LOAFLY_API_KEY", "demo-key")

    if api_key == "demo-key":
        logger.warning("Using demo API key")

    else:
        logger.info("API key loaded successfully from environment")

    # Process each order
    for record in orders:

        order = record["order"]
        total = record["total"]

        # Retry API call
        for attempt in range(1, retries + 1):

            try:

                response = save_to_orders_api(
                    order.order_id,
                    total
                )

                logger.info(
                    "Saved Order: %s | Customer: %s | "
                    "Total: %.2f %s | Status: %s",
                    order.order_id,
                    order.customer,
                    total,
                    currency,
                    response["status"]
                )

                # Stop retrying after successful save
                break

            except ConnectionError as error:

                logger.warning(
                    "API save failed for Order ID: %s | "
                    "Attempt: %d/%d | Reason: %s",
                    order.order_id,
                    attempt,
                    retries,
                    error
                )

                if attempt < retries:

                    logger.info(
                        "Retrying Order ID: %s after 1 second",
                        order.order_id
                    )

                    time.sleep(1)

                else:

                    logger.error(
                        "Failed to save Order ID: %s "
                        "after %d attempts. Moving to next order.",
                        order.order_id,
                        retries
                    )
