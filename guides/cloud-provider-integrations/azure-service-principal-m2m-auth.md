## Using Azure Entra ID service principals for machine to machine auth with ACS

**Note:** Instructions provided in this guide are provided as-is without warranty or support from Red Hat.

### 1. Create Azure service principal

For this, we can use [the following guide from Microsoft Learn](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal?source=recommendations#register-an-application-with-microsoft-entra-id-and-create-a-service-principal).

The only step: “**Register an application with Microsoft Entra ID and create a service principal”** is required. We do not have to add roles for that service principal because it does not have to access any Azure resource. It will be used only for authentication in ACS.

### 2. Setup authentication for created service principal

This is required in order for the service principal to authenticate to Azure.

We can use [the following steps from the same Microsoft Learn page](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal?source=recommendations#set-up-authentication).

After authentication setup, we can use the `az` command to log into Azure and retrieve the access token required to do m2m authentication to ACS.

### 3. Login with `az`

This example uses a secret to authenticate (**Option 3** in the “Setup authentication” guide mentioned under step 2.).

```
az login --service-principal \
  --username <service principal Application (client) ID> \
  --password <created secret Value field> \
  --tenant <service principal Directory (tenant) ID> \
  --allow-no-subscriptions
```

It is important to use the `--allow-no-subscriptions` flag if the service principal does not have any roles.

**Note:** Logging as a regular user with `az login` would also work. In that case, the difference would be that we need to use `unique_name` or another claim from the token during the configuration of ACS machine access (Step 4\. below)

After this, the command:

```
az account list --output yamlc
```

Should output account with `user` property. The name of that user should be the service principal ID.

```
  user:
    name: <service principal Application (client) ID>
    type: servicePrincipal
```

### 4. Configure ACS

You can follow [Configuring short-lived access documentation on Red Hat documentation](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/4.6/html/operating/managing-user-access#configure-short-lived-access). *Ensure to use documentation from used ACS version.*

Create a **Machine access configuration** - with the following fields:

Issuer: `https://sts.windows.net/<service principal Directory (tenant) ID>/`

Add a rule with:
Key: `appid`
Value: `<service principal Application (client) ID>`

**Important:** ACS has to be able to access: `https://sts.windows.net/<service principal Directory (tenant) ID>/.well-known/openid-configuration`

### 5. Test everything

Use the following `roxctl` command:

```
roxctl central machine-to-machine exchange \
  --token="$(az account get-access-token --tenant "<service principal Directory (tenant) ID>" --query "accessToken" --output tsv)"
```

*If `--output tsv` does not provide valid token format. There is option to use JSON output and `jq` command to select token from payload.*

After successful login, running: `roxctl central whoami` should output ACS authentication information. And “User name:” in the output should be the same as provided `<service principal Application (client) ID>` in the `az` login command.
