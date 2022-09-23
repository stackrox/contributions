#Simple examples of ACS "alert" objects, the structure behind Violations in the UI

Simple curl examples

These examples all use environment variables for the Hostname of ACS Central (Control Plane) and for the contents of a StackRox API token that you can create from the UI under Platform Integration -> Integrations.   


Super simple alert retrieval:  
```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://$CENTRAL/v1/alerts | jq -r '.'
```

Using a search query for alerts:  
```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://$CENTRAL/v1/alerts?query="Namespace:test" | jq -r '.'
```

Combination search query:  
```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://$CENTRAL/v1/alerts?query="Cluster:kube+Namespace:stackrox,kube-system" | jq -r '.'
```

Combination search query with URL-safe encoding:  
```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://$CENTRAL/v1/alerts?query=Severity%3AHIGH_SEVERITY%2BNamespace%3Apayments | jq -r '.'
```

Search filter for time range:  
```bash
curl -k -H "Authorization: Bearer ${TOKEN}" https://$CENTRAL/v1/alerts?query==Violation%20Time%3A%3E1d | jq -r '.'
```
