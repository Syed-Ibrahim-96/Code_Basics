\# Loafly – Production-Ready Python Framework



\### -- Q1: Functions



\*\*Write-up:\*\*



Created reusable `clean\_price()` and `apply\_discount()` functions to eliminate repeated logic. The price-cleaning function handles spaces and comma-separated values, while the discount function calculates the discounted amount based on a parameter.



\### -- Q2: Object-Oriented Programming (OOP)



\*\*Write-up:\*\*



Implemented an `Order` class to represent each customer order, containing its order ID, customer details, and items. Added `add\_item()` and `total()` methods to manage order items and calculate the order subtotal.



\### -- Q3: Modules and Packages



\*\*Write-up:\*\*



Refactored the monolithic script into a structured `loafly` Python package, separating configuration, data extraction, transformation, and loading into individual modules. Created `run\_pipeline.py` to orchestrate the complete Extract–Transform–Load (ETL) workflow.



\### -- Q4: Config-Driven Design



\*\*Write-up:\*\*



Centralized application settings such as currency, discount percentage, input file path, and retry count in a single `SETTINGS` dictionary. This makes the pipeline configurable without modifying the underlying business logic.



\### -- Q5: Logging and Exception Handling



\*\*Write-up:\*\*



Replaced print statements with timestamped logging at appropriate levels and configured logs to be written to a file. Implemented `try-except-finally` handling during price parsing so missing or invalid prices are skipped with warnings without interrupting the pipeline.



\### -- Q6: Retry, Environments and Secrets



\*\*Write-up:\*\*



Implemented a retry mechanism around the API save operation to handle temporary connection failures, with a maximum of three attempts and a one-second wait between retries. Read the API key through environment variables, excluded `.env` from Git, and added `env.example`, `requirements.txt`, and `README.md` for secure configuration and project setup.

