import csv
import random
import os
import argparse

def pick_random_rows(csv_file, factor, seed=None):
    # Initialize random number generator with seed
    random.seed(seed)

    # Read CSV file
    with open(csv_file, 'r', newline='') as file:
        reader = csv.reader(file)
        rows = list(reader)
    
    # Remove header if exists
    header = None
    if len(rows) > 0:
        header = rows[0]
        rows = rows[1:]

    # Calculate number of rows to pick
    num_rows = int(factor * len(rows[0]))

    # Pick random rows
    if num_rows > len(rows):
        print("Number of rows to pick is greater than the total number of rows in the CSV file.")
        return []
    random_rows = random.sample(rows, num_rows)

    # Add back header if exists
    if header:
        random_rows.insert(0, header)

    return random_rows

def write_to_csv(data, filename):
    with open(filename, 'w', newline='') as file:
        writer = csv.writer(file)
        writer.writerows(data)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Pick random rows from a CSV file.")
    parser.add_argument("csv_file", help="Path to the CSV file")
    parser.add_argument("factor", type=float, help="Factor to determine the number of rows to pick (multiplied by number of columns)")
    parser.add_argument("seed", type=int, help="Seed for random number generation")
    parser.add_argument("output_file", help="Path to the output CSV file")
    args = parser.parse_args()

    csv_file = args.csv_file
    factor = args.factor
    seed = args.seed
    output_file = args.output_file

    # Append seed value to the output file name
    output_file_with_seed = f"{output_file}_{seed}.csv"

    random_rows = pick_random_rows(csv_file, factor, seed)

    # Write random rows to the output CSV file
    write_to_csv(random_rows, output_file_with_seed)
    print(f"Random rows written to file: {output_file_with_seed}")