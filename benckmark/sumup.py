import json

# Define a function to parse the fio JSON output and return the desired metrics
def parse_fio_output(json_str):
    # Load the JSON string into a dictionary
    data = json.loads(json_str)

    # Extract the relevant stats based on whether it's a read or write test
    if 'read' in data['jobs'][0]['job options']['rw']:
        keys = "read"
    else:
        keys = "write"

    iops = data['jobs'][0]['read']['iops'] if keys == 'read' else data['jobs'][0]['write']['iops']
    bw = data['jobs'][0]['read']['bw'] if keys == 'read' else data['jobs'][0]['write']['bw']

    # Return a tuple with the extracted metrics
    return (iops, bw)

# Define the filenames of the fio output files
filenames = ['random-read-4k.json', 'random-write-4k.json', 'read-4M.json', 'write-4M.json']

# Create an empty list to store the results
results = []

# Loop through each file, parse the JSON output, and append the results to the list
for filename in filenames:
    with open(filename, 'r') as f:
        json_str = f.read()
        iops, bw = parse_fio_output(json_str)
        results.append((iops, bw))

# Define the headers for the markdown table
headers = ['Test', 'IOPS', 'BW']

# Create the markdown table
table_str = "| {} |\n".format(" | ".join(headers))
table_str += "| " + " | ".join(['-' * len(h) for h in headers]) + " |\n"
for i, (filename, result) in enumerate(zip(filenames, results)):
    test_name = filename.split('.')[0]
    test_type = 'Read' if 'read' in filename else 'Write'
    table_str += "| {} | {} | {} |\n".format(test_name, result[0], result[1])

print(table_str)