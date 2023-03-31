Parses results from "roxctl image scan" to determine which fixable CVEs fall into a defined "Grace Period" in days. Default grace period is 30 days.

Output lists each Fixable CVE as
- "in grace": CVE Published less than "grace period" days ago 
- "out of grace": CVE Published more than "grace period" days ago 

Usage:

`roxctl image scan -e $CENTRAL:443 --image quay.io/example:1.0 | ./grace.py
`
