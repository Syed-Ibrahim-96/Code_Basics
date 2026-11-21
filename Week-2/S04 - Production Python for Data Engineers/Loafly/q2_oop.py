
import csv


# ============================================================
# Q1 - FUNCTIONS
# ============================================================

def clean_price(text):
    """
    Clean the price and convert it into float.
    """
    cleaned_text = text.strip().replace(",", "")
    return float(cleaned_text)


def apply_discount(price, percent):
    """
    Apply discount to the given price.
    """
    discounted_price = price - (price * percent / 100)
    return discounted_price


# ============================================================
# Q2 - ORDER CLASS
# ============================================================

class Order:

    def __init__(self, order_id, customer):
        """
        Initialize an Order object.
        """

        self.order_id = order_id
        self.customer = customer
        self.items = []

    def add_item(self, name, price):
        """
        Add an item and its price to the order.
        """

        self.items.append((name, price))

    def total(self):
        """
        Calculate the total price of all items.
        """

        return sum(price for name, price in self.items)


# ============================================================
# EXTRACT - READ CSV AND BUILD ORDER OBJECTS
# ============================================================

orders = {}

with open("raw_orders.csv", "r", newline="", encoding="utf-8") as file:

    reader = csv.DictReader(file)

    for row in reader:

        order_id = row["order_id"]
        customer = row["customer"]
        item_name = row["item_name"]
        item_price = row["item_price"]

        # Create Order object if it does not exist
        if order_id not in orders:

            orders[order_id] = Order(
                order_id,
                customer
            )

        # Temporarily skip missing prices.
        # Proper exception handling will be implemented in Q5.
        if not item_price.strip():
            print(
                f"Skipping missing price: "
                f"Order {order_id}, Item: {item_name}"
            )
            continue

        # Clean the item price using Q1 function
        cleaned_price = clean_price(item_price)

        # Add item to Order object
        orders[order_id].add_item(
            item_name,
            cleaned_price
        )


# ============================================================
# CALCULATE TOTALS AND APPLY DISCOUNT
# ============================================================

DISCOUNT_PERCENT = 10

print("\n================ ORDER SUMMARY ================\n")

for order_id, order in orders.items():

    # Calculate subtotal using Order class method
    subtotal = order.total()

    # Apply discount
    final_total = apply_discount(
        subtotal,
        DISCOUNT_PERCENT
    )

    print(f"Order ID       : {order.order_id}")
    print(f"Customer       : {order.customer}")
    print(f"Items          : {len(order.items)}")
    print(f"Subtotal       : ₹{subtotal:.2f}")
    print(f"Discount       : {DISCOUNT_PERCENT}%")
    print(f"Final Total    : ₹{final_total:.2f}")
    print("-" * 45)
