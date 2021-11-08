# Setup Flutter
This guide will help anyone install and run their first Flutter on a jiffy!

 1. Checkout this repo
	 ```bash
	 git clone https://github.com/markglibres/flutter-setup.git
	 ```
 2. Change directory
	 ```bash
	 cd flutter-setup
	 ```
	 
 3. Execute setup script
	 ```bash
	 ./scripts/mac/setup.sh
	 ```
	 
 4. Create your first Flutter app
	 ```bash
	 cd whatever-your-app-path
	 flutter create my-ap
	```
	
 5. Open iOS Simulator manually or thru the commands below
	 ```bash
	 xcrun simctl list #list available ios simulators if you want to specify the device UDID
	 open -a Simulator # -CurrentDeviceUDID <your device UDID>
	 ```
	 
 6. Once the iOS simulator is up and running, list available devices
	 ```bash
	 flutter devices
	 ```
	 
 7. Run your Flutter app on a device
	 ```bash
	 flutter run -d first-3-letters-of-device-id #the uuid of ios simulator
	 ```
	 
 8. Your flutter app should be running within the iOS simulator

	 
