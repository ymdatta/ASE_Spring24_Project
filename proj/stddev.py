import sys
import statistics

def calculate_std_dev(filename):
    # List to store values
    data = []

    # Open the file
    with open(filename, 'r') as file:
        # Read each line
        for line in file:
            # Convert line to float and append to data list
            data.append(float(line.strip()))

    # Calculate standard deviation
    std_dev = statistics.stdev(data)

    return std_dev

if __name__ == "__main__":
    # Check if filename is provided as command line argument
    if len(sys.argv) != 2:
        print("Usage: python script.py <filename>")
        sys.exit(1)

    filename = sys.argv[1]
    std_dev = calculate_std_dev(filename)
    print(round(0.35 * std_dev, 2))