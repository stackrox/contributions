### Install required python libs
```
pip install -r requirements.txt
```

### Export ACS API key and Central
```
export acs_api_key=<api_key>
export acs_central_api=<acs_central_url:443>
```

### Pull all violations

```
python generate_violations_csv.py
```
