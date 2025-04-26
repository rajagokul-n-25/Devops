import json
import pandas as pd

# Load the JSON file
with open('/home/gokul/backend.json', 'r') as f:
    data = json.load(f)

# Extract vulnerabilities with 'Target' as 'Library'
vulnerabilities = []
for result in data.get("Results", []):
    library = result.get("Target", "")  # Treat the Target as the library name
    for vuln in result.get("Vulnerabilities", []):
        vulnerabilities.append({
            "Library": library,
            "VulnerabilityID": vuln.get("VulnerabilityID"),
            "PkgName": vuln.get("PkgName"),
            "InstalledVersion": vuln.get("InstalledVersion"),
            "FixedVersion": vuln.get("FixedVersion", ""),  # Get FixedVersion if available
            "Severity": vuln.get("Severity"),
            "Title": vuln.get("Title"),
            "Status": vuln.get("Status", "")  # Get Status if available
        })

# Convert to DataFrame and save to Excel
df = pd.DataFrame(vulnerabilities)
df.to_excel("backend.xlsx", index=False)

