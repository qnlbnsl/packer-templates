source ../../.env
mkisofs -J -l -R -V "Label CD" -iso-level 4 -o Autounattend.iso answerFile
iso_hash=$(sha1sum ./Autounattend.iso | awk '{print $1}')
echo $iso_hash
echo $API_USER
echo $API_TOKEN
packer build -var "hash=$iso_hash" -var "username=$API_USER" -var "token=$API_TOKEN" -var "proxmox_url=$API_URL" win10x64-enterprise.json.pkr.hcl    