
$MY_RESOURCE_GROUP_NAME="vidterraResourceGroup"
$REGION="usgovvirginia"
az group create --name $MY_RESOURCE_GROUP_NAME --location $REGION

$MY_VM_NAME="compassVM"
$MY_USERNAME="vidterra"
$MY_VM_IMAGE="vidterrallc1675287658838:vidterra_compass_pro:compassadv_adt_base:25.0115.1840"
az vm image terms accept --urn $MY_VM_IMAGE
az vm create --resource-group $MY_RESOURCE_GROUP_NAME --name $MY_VM_NAME --image $MY_VM_IMAGE --admin-username $MY_USERNAME --assign-identity --generate-ssh-keys --public-ip-sku Standard --size Standard_D4s_v4