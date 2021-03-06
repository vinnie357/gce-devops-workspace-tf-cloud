# logging
LOG_FILE=/var/log/startup-script.log
if [ ! -e $LOG_FILE ]
then
     touch $LOG_FILE
     exec &>>$LOG_FILE
else
    #if file exists, exit as only want to run once
    exit
fi

exec 1>$LOG_FILE 2>&1
# repos"
repositories="${repositories}"
user="${user}"
set -ex \
&& curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - \
&& curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - \
&& echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
&& sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
&& sudo apt-get update -y \
&& sudo apt-get install -y apt-transport-https wget unzip jq git software-properties-common python3-pip ca-certificates gnupg-agent docker-ce docker-ce-cli containerd.io google-cloud-sdk \
&& echo "docker" \
&& sudo usermod -aG docker $user \
&& sudo chown -R $user: /var/run/docker.sock \
&& echo "terraform" \
&& sudo wget https://releases.hashicorp.com/terraform/${terraformVersion}/terraform_${terraformVersion}_linux_amd64.zip \
&& sudo unzip ./terraform_${terraformVersion}_linux_amd64.zip -d /usr/local/bin/ \
&& echo "f5 cli" \
&& pip3 install f5-cli \
&& echo "terragrunt" \
&& sudo wget https://github.com/gruntwork-io/terragrunt/releases/download/v${terragruntVersion}/terragrunt_linux_amd64 \
&& sudo mv ./terragrunt_linux_amd64 /usr/local/bin/terragrunt \
&& sudo chmod +x /usr/local/bin/terragrunt \
&& echo "chef Inspec" \
&& curl https://omnitruck.chef.io/install.sh | sudo bash -s -- -P inspec \
&& echo "auto completion" \
&& complete -C '/usr/bin/aws_completer' aws \
&& terraform -install-autocomplete

echo "test tools"
echo '# test tools' >>/home/$user/.bashrc
echo '/bin/bash /testTools.sh' >>/home/$user/.bashrc
cat > /testTools.sh <<EOF 
#!/bin/bash
echo "=====Installed Versions====="
terraform -version
echo "inspec:"
inspec version
terragrunt -version
f5 --version
gcloud version
echo "=====Installed Versions====="
EOF
echo "clone repositories"
cwd=$(pwd)
ifsDefault=$IFS
IFS=','
cd /home/$user
for repo in $repositories
do
    git clone $repo
done
IFS=$ifsDefault
cd $cwd
echo "=====done====="
exit

echo "=====done====="
exit