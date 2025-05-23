#If it's First time
git flow Init
#local 

git branch
git fetch --all
git pull
git checkout development 
git pull 
git checkout hotfix/1.0.0
git branch
git pull
git flow hotfix finish 1.0.0 #master :wq , tag , hotfix close, new tag creation to set tag hotfix/current hotfix
git push --tags
git push origin development
git checkout master
git push origin master




#kaitongo repo /opt/kaitongo/ prod server 1

git branch
git fetch --all
git checkout tags/1.0.1
git pull origin 1.0.1
git branch
bash +x k8_deploy.sh "" prod
k get pods #checks pods are running


