We can do a batch update to add groups in the following manner:


As always, we  export the Central address and your API token:
```
export CENTRAL=YOUR_CENTRAL_ADDRESS
```
```
export ROX_API_TOKEN=eyJhb....BlAh
```
Retrive your AuthProviderID:
```
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" https://$CENTRAL/v1/authProviders
```
```
export AUTH_ID=Id_from_previous_curl
```


Utilizing your AuthProvider ID, you can define utilize the "value" field to map your groups to the needed roles. 
```bash
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" --header "Content-Type: application/json" -X POST "https://$CENTRAL/v1/groupsbatch" -d '{ "requiredGroups": [{"props":{"id":"","authProviderId":"$AUTH_ID","key":"groups","value":"LDAP_Analyst_Group"},"roleName":"Analyst"},{"props":{"id":"","authProviderId":"$AUTH_ID","key":"groups","value":"LDAP_Analyst_Group_2"},"roleName":"Analyst"}]}'
```
