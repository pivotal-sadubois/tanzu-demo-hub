import requests
import json

# API Endpoint and token
url = "https://10.0.101.2/api/load_balance_real_server"
headers = {
    "Content-Type": "application/json",
    "APITOKEN": "4af7c301032375ce39669748fdafff97"
}

# Disable SSL warnings
requests.packages.urllib3.disable_warnings()

# GET request to retrieve existing real servers
response = requests.get(url, headers=headers, verify=False)
if response.status_code == 200:
    data = response.json()
    
    # Parse and print real server data
    for server in data['payload']:
        print(f"Server: {server['mkey']}, Address: {server['address']}, Status: {server['status']}")
    
    # Example of configuring a real server (modifying status of one server)
    updated_server = {
        "mkey": "employee-demo-blue",
        "address": "10.0.101.171",
        "status": "disable"  # Update to disable the server
    }
    
    # PUT request to update the server configuration
    update_response = requests.put(f"{url}/{updated_server['mkey']}", headers=headers, json=updated_server, verify=False)
    
    if update_response.status_code == 200:
        print("Server configuration updated successfully.")
    else:
        print(f"Failed to update server configuration: {update_response.status_code}")
else:
    print(f"Failed to retrieve real servers: {response.status_code}")
