BRANCH="latest"

#already know start dir

echo " # building web"
flutter build web
echo "done"
/bin/sleep 2

echo " # building apk"
flutter build apk --release
echo "done"
/bin/sleep 2

cd .server

sudo systemctl start docker

#build typescript
npm run build
echo "done"
/bin/sleep 2

echo " # injecting builds"
cd ..
#after build finished bring over files for web and what not
#only done now and wihtout sys link as not wanted to be included in typescript
cp -R ./build/web ./.server/web/
cp ./build/app/outputs/flutter-apk/app-release.apk ./.server/app-release.apk



cd .server

echo " # building docker image" 
sudo docker build -t aikiwi1/toaster:$BRANCH . 
echo "done"
/bin/sleep 2

echo " # logging into docker account" 
sudo docker login

echo " # pushing docker update"
sudo docker push aikiwi1/toaster:$BRANCH
echo "done"
/bin/sleep 2

echo " # showing local docker images" 
sudo docker images
/bin/sleep 2


#clean up after finished
echo " # cleaning up injected files" 
rm -R ./web/
rm ./app-release.apk

echo "opening server updating docker install"
firefox -new-tab "https://192.168.0.166:9443/"
echo "done, you can now rebuild container"

#to start
#sudo docker run toaster-server -p 3030:3030
#sudo docker container list
#sudo docker container kill 6c243b56af21