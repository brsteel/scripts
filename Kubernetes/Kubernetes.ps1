
#docker for windows should be installed
az login --tenant 'cxpacegov.onmicrosoft.us'
az aks install-cli #put path into system path
kubectl.exe get nodes 

git clone https://github.com/Azure-Samples/azure-voting-app-redis.git C:\votingapp
cd C:\votingapp
docker-compose up -d
docker images
docker ps
http://localhost:8080
docker-compose down

#continer respository
az acr create --resource-group BrookeSteele --name KubeTestACR --sku Basic

az acr login --name KubeTestACR
docker images
az acr list --resource-group BrookeSteele --query "[].{acrLoginServer:loginServer}" --output table
docker tag azure-vote-front kubetestacr.azurecr.us/azure-vote-front:v1
docker images
docker push kubetestacr.azurecr.us/azure-vote-front:v1
az acr repository list --name KubeTestACR --output table
az acr repository show-tags --name KubeTestACR --repository azure-vote-front --output table

az aks update -n KubeClusterTest -g BrookeSteele --attach-acr KubeTestACR

#update manifest file
az acr list --resource-group BrookeSteele --query "[].{acrLoginServer:loginServer}" --output table
notepad .\azure-vote-all-in-one-redis.yaml #put in login server name
kubectl apply -f azure-vote-all-in-one-redis.yaml

#test app
kubectl get service azure-vote-front --watch
kubectl rollout status deployment azure-vote-front

start "http://20.140.186.178"


az aks update -n KubeClusterTest -g BrookeSteele --detach-acr KubeTestACR
az acr delete -n KubeTestACR