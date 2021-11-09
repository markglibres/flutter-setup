
# Setup Flutter

This guide will help anyone install and run their first Flutter (with VS Code) on a jiffy!


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
	flutter create my-app
	```

## Run flutter app with an iOS simulator

1. Open iOS Simulator manually or thru the commands below

	```bash
	xcrun simctl list #list available ios simulators if you want to specify the device UDID
	open -a Simulator # -CurrentDeviceUDID <your device UDID>
	```

2. Once the iOS simulator is up and running, list available devices

	```bash
	flutter devices
	```

3. Run your Flutter app on a device

	```bash
	flutter run -d first-3-letters-of-device-id #the uuid of ios simulator
	```
	e.g. `flutter run -d dc3`

4. Your flutter app should be running within the iOS simulator

## Run flutter app with an Android Emulator

1. The setup script created an emulator called "Android31". All we need to do is run it by the command:

	```bash
	emulator -avd Android31
	```

2. Once the Android emulator is up and running, list available devices

	```bash
	flutter devices
	```

3. Run your Flutter app on a device

	```bash
	flutter run -d first-3-letters-of-device-id #the uuid of android virtual device
	```
	e.g. `flutter run -d emu`

4. Your flutter app should be running within the Android emulator
