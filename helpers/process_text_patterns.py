import csv
import re

input_file  = "D:\Courses\AML\Datasets\HI-Medium_Patterns.txt"
output_file = "D:\Courses\AML\Datasets\HI-Medium_Patterns.csv"

columns = [
    "pattern_group_id", "pattern_type", "pattern_metadata",
    "timestamp", "from_bank", "from_account",
    "to_bank", "to_account",
    "amount_received", "receiving_currency",
    "amount_paid", "payment_currency",
    "payment_format", "is_laundering"
]

rows = []
pattern_group_id = 0
current_type     = None
current_meta     = None

with open(input_file, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue

        if line.startswith("BEGIN"):
            pattern_group_id += 1
            # "BEGIN LAUNDERING ATTEMPT - CYCLE:  Max 12 hops"
            after_dash = line.split(" - ", 1)[1] if " - " in line else ""
            if ":" in after_dash:
                parts        = after_dash.split(":", 1)
                current_type = parts[0].strip()
                current_meta = parts[1].strip() or None
            else:
                current_type = after_dash.strip()
                current_meta = None

        elif line.startswith("END"):
            continue

        else:
            # transaction line — same schema as Trans.csv
            parts = line.split(",")
            if len(parts) == 11:
                rows.append([
                    pattern_group_id,
                    current_type,
                    current_meta,
                    *parts   # timestamp through is_laundering
                ])

with open(output_file, "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(columns)
    writer.writerows(rows)

print(f"Done — {len(rows)} rows written to {output_file}")