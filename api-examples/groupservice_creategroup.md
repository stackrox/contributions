Creating a single group can be achieved by providing a key, value pair and mapping it to a role. 

```json
{
"props": {
"id": "string",
"authProviderId": "string",
"key": "string",
"value": "string"
},
"roleName": "string"
}
```

```bash
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://$CENTRAL/v1/groups" -d '{"props":{"id":"","authProviderId":"38c7afcd-d943-4163-bdb0-7787f9cdb3a4","key":"groups","value":"LDAP_Analyst_Group"},"roleName":"Analyst"}'
```

