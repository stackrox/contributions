# ACS API Examples

### Examples of API usage to perform configuration and reporting tasks with Red Hat Advanced Cluster Security

These examples use an ACS API Token [that you can issue from the ACS Central Integrations page](https://docs.openshift.com/acs/3.71/cli/getting-started-cli.html#cli-authentication_cli-getting-started)

---

The examples assume two environment variables:<br>
CENTRAL is the exposed hostname or IP address of the ACS Central pod's route or loadbalancer<br>
ROX_API_TOKEN is the full text of a token created in the Central UI's Integrations page<br>

API calls to ACS' RESTful API endpoints require the API token in the Authorization: Bearer header. The RESTful API documentation is available in the Central UI.

```
export CENTRAL=central-stackrox.apps.example.com
export ROX_API_TOKEN=eyJhbGciOiJSUzI1NiIsIm...HYkJj2uWo
```

---

Absurdly simple example:
```
curl -k -H "Authorization: Bearer ${ROX_API_TOKEN}" https://$CENTRAL:443/v1/ping
```
