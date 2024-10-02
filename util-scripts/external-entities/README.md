# Cluster External Entities Inspection
This tool communicates with the Central API to inspect known external
network entities for a given cluster. These entities are either
pre-defined CIDR blocks for known address ranges, or specific IP addresses.

The tool can either retrieve all known external entities, or all entities that
have communicated with a given deployment.

## Configuration

### Environment variables

- ROX_ENDPOINT: the endpoint for communication with central. This can usually
  be found using the following command

```sh
oc -n stackrox get route central -o=jsonpath='{.spec.host}'
```

- ROX_API_KEY: an API key generated within the ACS installation. From the UI
  this can be created via the integrations page.


## Example Commands

```sh
# Get all external entities for the 'remote' cluster
$ ./external-entities.py entities remote

# Get all external network flows for Central, in the 'remote' cluster
$ ./external-entities.py deployments remote central

# ... and with json output
$ ./external-entities.py --json deployment remote central

# Get external entities that match a given CIDR block
$ ./external-entities.py entities remote --cidr 192.168.0.0/24
```
