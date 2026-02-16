late List<CameraDescription> cameras; // Global list to hold available cameras

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Obtain a list of the available cameras on the device.
  cameras = await availableCameras();
  
  final prefs = await SharedPreferences.getInstance();
  bool isFirstRun = prefs.getBool('first_run') ?? true;

  runApp(FarmAidApp(isFirstRun: isFirstRun));
}