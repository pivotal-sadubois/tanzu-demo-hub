import os
import requests
import json
import sys

# Get API key and URL from environment variables
api_token = os.getenv("FORTIADC_APIKEY")
url = os.getenv("FORTIADC_HOST")+"/api/load_balance_real_server"

if not api_token or not url:
    print("Error: FORTIADC_APIKEY or FORTIADC_HOST environment variable is not set")
    sys.exit(1)

# Set headers
headers = {
    "Content-Type": "application/json",
    "APITOKEN": api_token
}

print("HEADERS: ", headers)

# Disable SSL warnings
requests.packages.urllib3.disable_warnings()

# GET request to retrieve real servers
response = requests.get(url, headers=headers, verify=False)
if response.status_code == 200:
    data = response.json()

    # Pretty-print the JSON data
    pretty_json = json.dumps(data, indent=4)
    print(pretty_json)
    
    # Parse and print real server data
    for server in data['payload']:
        print(f"Server: {server['mkey']}, Address: {server['address']}, Status: {server['status']}")
    
    # Example: Modify one server's status
    updated_server = {
        "mkey": "employee-demo-blue",
        "address": "10.0.101.171",
        "status": "disable"  # Update to disable the server
    }
    
    # PUT request to update server config
    update_response = requests.put(f"{url}/{updated_server['mkey']}", headers=headers, json=updated_server, verify=False)
    
    if update_response.status_code == 200:
        print("Server configuration updated successfully.")
    else:
        print(f"Failed to update server configuration: {update_response.status_code}")
else:
    print(f"Failed to retrieve real servers: {response.status_code}")
