# Loafly – Production-Ready Python Pipeline

## Project Overview

Loafly is a Python-based order processing pipeline that reads bakery orders from a CSV file, cleans item prices, applies discounts, calculates order totals and saves orders through an API.

This project demonstrates Python functions, object-oriented programming, modular architecture, configuration management, logging, exception handling, retry mechanisms and environment-based secret management.

## Project Structure

```text
Loafly/
│
├── loafly/
│   ├── __init__.py
│   ├── config.py
│   ├── models.py
│   ├── extract.py
│   ├── transform.py
│   └── load.py
│
├── raw_orders.csv
├── gateway.py
├── run_pipeline.py
├── requirements.txt
├── .gitignore
├── env.example
└── README.md
```

## Prerequisites

- Python 3.10 or above
- Git

## Setup Instructions

### 1. Clone the repository

```bash
git clone <your-repository-url>
cd Loafly
```

### 2. Create a virtual environment

Windows:

```powershell
python -m venv .venv
.venv\Scripts\activate
```

### 3. Configure environment variables

Copy `env.example` to `.env` and configure the API key.

```text
LOAFLY_API_KEY=your-api-key
```

Never commit `.env` to Git.

### 4. Install dependencies

```bash
pip install -r requirements.txt
```

No external dependencies are required.

### 5. Run the pipeline

```bash
python run_pipeline.py
```

## Pipeline Execution

The application follows the Extract, Transform and Load (ETL) approach.

1. **Extract:** Reads order records from `raw_orders.csv`.
2. **Transform:** Cleans prices, skips invalid items and applies the configured discount.
3. **Load:** Saves processed orders using the provided orders API client, with retry handling.

## Configuration

Application settings are maintained in `loafly/config.py`, including:

- Currency
- Discount percentage
- Input file path
- Retry count

## Logging and Exception Handling

The pipeline uses Python logging to record execution details, warnings and errors.

Logs are written to `loafly.log`.

Missing-price items are skipped without interrupting the pipeline.

## Security

API credentials are read from environment variables. The `.env` file is excluded from version control using `.gitignore`.

## Technology

- Python
- CSV
- Logging
- Object-Oriented Programming
- Environment Variables
- Python Standard Library