
# loafly/transform.py

import logging

from loafly.models import Order
from loafly.config import SETTINGS


logger = logging.getLogger(__name__)


# ============================================================
# PRICE CLEANING
# ============================================================

def clean_price(text):

    cleaned_text = text.strip().replace(",", "")

    return float(cleaned_text)


# ============================================================
# DISCOUNT CALCULATION
# ============================================================

def apply_discount(price, percent):

    discounted_price = price - (price * percent / 100)

    return discounted_price


# ============================================================
# TRANSFORM ORDERS
# ============================================================

def transform_orders(rows):

    orders = {}

    for row in rows:

        order_id = row["order_id"]
        customer = row["customer"]
        item_name = row["item_name"]
        item_price = row["item_price"]

        # Create Order object
        if order_id not in orders:

            orders[order_id] = Order(
                order_id,
                customer
            )

        # ----------------------------------------------------
        # Exception handling for price parsing
        # ----------------------------------------------------

        try:

            cleaned_price = clean_price(item_price)

            # Add item to Order object
            orders[order_id].add_item(
                item_name,
                cleaned_price
            )

        except (ValueError, TypeError, AttributeError) as error:

            logger.warning(
                "Skipping item. Order ID: %s | Item: %s | "
                "Invalid price: %r | Reason: %s",
                order_id,
                item_name,
                item_price,
                error
            )

            continue

        finally:

            logger.debug(
                "Price parsing completed for Order ID: %s | Item: %s",
                order_id,
                item_name
            )

    # --------------------------------------------------------
    # Calculate discounted totals
    # --------------------------------------------------------

    transformed_orders = []

    discount_percent = SETTINGS["discount_percent"]

    for order in orders.values():

        subtotal = order.total()

        final_total = apply_discount(
            subtotal,
            discount_percent
        )

        transformed_orders.append({
            "order": order,
            "total": final_total
        })

    logger.info(
        "Transformation completed. Total orders: %d",
        len(transformed_orders)
    )

    return transformed_orders
