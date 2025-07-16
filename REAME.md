
- log in to azure portal
```
az login
```

- create azure container registry
```
az group create --name churnappRG --location australiaeast
az acr create --resource-group churnappRG --name churnappregistry --sku Basic

```