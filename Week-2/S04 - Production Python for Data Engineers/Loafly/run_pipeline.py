
# run_pipeline.py

import logging

from loafly.extract import extract_orders
from loafly.transform import transform_orders
from loafly.load import load_orders


# ============================================================
# LOGGING CONFIGURATION
# ============================================================

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("loafly.log", encoding="utf-8"),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)

import os
from pathlib import Path


def load_env_file():

    env_file = Path(".env")

    if not env_file.exists():
        return

    with env_file.open("r", encoding="utf-8") as file:

        for line in file:

            line = line.strip()

            if not line or line.startswith("#"):
                continue

            key, separator, value = line.partition("=")

            if separator:
                os.environ.setdefault(
                    key.strip(),
                    value.strip().strip('"').strip("'")
                )


load_env_file()

# ============================================================
# MAIN PIPELINE
# ============================================================

def main():

    logger.info("Starting Loafly Pipeline")

    # Step 1: Extract
    raw_orders = extract_orders()

    logger.info(
        "Extracted %d records",
        len(raw_orders)
    )

    # Step 2: Transform
    transformed_orders = transform_orders(raw_orders)

    logger.info(
        "Transformed %d orders",
        len(transformed_orders)
    )

    # Step 3: Load
    load_orders(transformed_orders)

    logger.info("Loafly Pipeline Completed")


if __name__ == "__main__":
    main()
