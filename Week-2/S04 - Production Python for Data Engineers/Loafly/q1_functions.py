
import csv


# ============================================================
# Q1 - FUNCTION DEFINITIONS
# ============================================================

def clean_price(text):
    """
    Remove leading/trailing spaces and commas.
    Convert the cleaned price into float.
    """
    cleaned_text = text.strip().replace(",", "")
    return float(cleaned_text)


def apply_discount(price, percent):
    """
    Calculate the discounted price.
    """
    discounted_price = price - (price * percent / 100)
    return discounted_price


# ============================================================
# READ CSV AND PROCESS ORDERS
# ============================================================

orders = {}

with open("raw_orders.csv", "r", newline="", encoding="utf-8") as file:

    reader = csv.DictReader(file)

    for row in reader:

        order_id = row["order_id"]
        customer = row["customer"]
        item_name = row["item_name"]
        item_price = row["item_price"]

        # Initialize order if it does not exist
        if order_id not in orders:
            orders[order_id] = {
                "customer": customer,
                "items": [],
                "subtotal": 0.0
            }

        # Temporarily skip missing prices.
        # Proper exception handling will be implemented in Q5.
        if not item_price.strip():
            print(f"Skipping missing price: Order {order_id}, Item: {item_name}")
            continue

        # Clean item price using Q1 function
        cleaned_price = clean_price(item_price)

        # Store item details
        orders[order_id]["items"].append(
            (item_name, cleaned_price)
        )

        # Calculate order subtotal
        orders[order_id]["subtotal"] += cleaned_price


# ============================================================
# APPLY DISCOUNT AND DISPLAY RESULTS
# ============================================================

DISCOUNT_PERCENT = 10

print("\n================ ORDER SUMMARY ================\n")

for order_id, order in orders.items():

    subtotal = order["subtotal"]

    final_total = apply_discount(
        subtotal,
        DISCOUNT_PERCENT
    )

    print(f"Order ID       : {order_id}")
    print(f"Customer       : {order['customer']}")
    print(f"Items          : {len(order['items'])}")
    print(f"Subtotal       : ₹{subtotal:.2f}")
    print(f"Discount       : {DISCOUNT_PERCENT}%")
    print(f"Final Total    : ₹{final_total:.2f}")
    print("-" * 45)
