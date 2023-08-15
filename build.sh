cd /home/aikiwi/Projects/phoneApps/toaster/

echo " # building web"
flutter build web
echo "done"
/bin/sleep 2

echo " # building apk"
flutter build apk --release
echo "done"
/bin/sleep 2

cd /home/aikiwi/Projects/phoneApps/toaster/.server/

sudo systemctl start docker

#build typescript
npm run build
echo "done"
/bin/sleep 2

echo " # injecting builds"
#after build finished bring over files for web and what not
#only done now and wihtout sys link as not wanted to be included in typescript
cp -R /home/aikiwi/Projects/phoneApps/toaster/build/web /home/aikiwi/Projects/phoneApps/toaster/.server/web/
cp /home/aikiwi/Projects/phoneApps/toaster/build/app/outputs/flutter-apk/app-release.apk /home/aikiwi/Projects/phoneApps/toaster/.server/app-release.apk



echo " # clearing old docker image" 
sudo docker image rm toaster-server
echo " # building docker image" 
sudo docker build -t aikiwi1/toaster:latest . 
echo "done"
/bin/sleep 2
echo " # logging into docker account" 
sudo docker login
echo " # pushing docker update"
sudo docker push aikiwi1/toaster:latest

echo " # showing local docker images" 
sudo docker images


#clean up after finished
echo " # cleaning up injected files" 
rm -R /home/aikiwi/Projects/phoneApps/toaster/.server/web/
rm /home/aikiwi/Projects/phoneApps/toaster/.server/app-release.apk

echo "opening server updating docker install"
firefox -new-tab "https://192.168.0.166:9443/"

#to start
#sudo docker run toaster-server -p 3030:3030
#sudo docker container list
#sudo docker container kill 6c243b56af21