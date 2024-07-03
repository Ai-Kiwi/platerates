URL="https://platerates.com/latestVersion"

response=$(curl -s -X POST -d "" "$URL")
clientVer=$(yq -r '.version' 'pubspec.yaml')

echo ""
echo "make sure verison has been updated and changes have been added to changelog"
echo "current server running $response"
echo "new client running $clientVer"

read -p "does this look correct? (kill if wrong): " correct


if [ "$response" == "$clientVer" ]
then
    echo "please update verison or build to push update"
    exit 1
fi



set -e

#already know start dir

echo " # building web"
flutter build web --release
echo "done"
/bin/sleep 2

echo " # building apk"
flutter build apk --release
echo "done"
/bin/sleep 2

cd .server

cargo build --release
echo "done"

echo " # injecting builds"
mkdir -p build/
mkdir -p build/static_data/
cd ..
#after build finished bring over files for web and what not
#only done now and wihtout sys link as not wanted to be included in typescript
cp .server/target/release/platerates_server ./.server/build/platerates_server
cp .server/static_data/jwt.key ./.server/build/static_data/jwt.key
cp -R ./build/web ./.server/build/static_data/web/
cp ./build/app/outputs/flutter-apk/app-release.apk ./.server/build/static_data/web/Platerates.apk

echo "all finished can now be used"