
# loafly/extract.py

import csv
import logging

from loafly.config import SETTINGS


logger = logging.getLogger(__name__)


def extract_orders():

    rows = []

    input_file = SETTINGS["input_file_path"]

    logger.info("Starting CSV extraction from %s", input_file)

    with open(
        input_file,
        "r",
        newline="",
        encoding="utf-8"
    ) as file:

        reader = csv.DictReader(file)

        for row in reader:
            rows.append(row)

    logger.info("CSV extraction completed successfully")

    return rows
