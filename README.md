# Sample: DAPR Playground

This is a playground for understanding how to develop a DAPR function.

## Setup

__Login__

Log into the Azure CLI from a command line and set the subscription. 
If running with windows ensure that Azure Powershell is connected as well.

```bash
az login
azd auth login  # (Optional) --use-device-code
```

__Environment Variables__

An environment must be created using the following environment variables.

| Variable                  | Purpose |
| :-------                  | :------ |
| AZURE_SUBSCRIPTION_ID     | The Azure Subscription _(GUID)_ |
| AZURE_LOCATION            | The Azure Region |


```bash
azd init -e dev
```

## Workspace

The workspace is brought online using the azure developer cli additionally visual studio tasks can be used.

| Action    | Command  |
| :-------  | :------  |
| Start     | `azd up` |
| Stop      | `azd down --purge --force` |

