### Requirements
```
pip install -r requirements.txt
```

### Set ACS API keys and Central API endpoint
```
export acs_api_key=<<api_key>>
export acs_central_api=<https://<acs_central_url/v1>
```

### Expected query arguments 

##### Limit cluster

`Cluster:cluster_name1,cluster_name2`

```
python generate_violations_csv.py --query_scope Cluster:dev_cluster,stating_cluster
```

##### Limit cluster and namespace

`Cluster:cluster_name+namespace_name`

```
python generate_violations_csv.py --query_scope Cluster:dev_cluster+Namespace:sandbox_namespace
```

#### Pull all violations

`all`

```
python generate_violations_csv.py --query_scope all
```
