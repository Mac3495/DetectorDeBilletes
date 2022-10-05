import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraImage cameraImage;
  CameraController cameraController;
  String result = "";
  bool isWorking = false;
  final flutterTts = FlutterTts();

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    cameraController.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController.startImageStream((imageStream) {
          if(!isWorking){
            isWorking = true;
            cameraImage = imageStream;
            runModel();
          }
        });
      });
    });
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model_unquant.tflite", labels: "assets/labels.txt");
  }

  initSpeech() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1);
  }

  textToSpeech(String text) async {
    cameraController.stopImageStream();
    await flutterTts.speak(text);
    initCamera();
  }

  runModel() async {
    try {
      if (cameraImage != null) {
        //await Future.delayed(Duration(seconds: 1));
        var recognitions = await Tflite.runModelOnFrame(
            bytesList: cameraImage.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            imageHeight: cameraImage.height,
            imageWidth: cameraImage.width,
            imageMean: 127.5,
            imageStd: 127.5,
            rotation: 90,
            numResults: 30,
            threshold: 0.1,
            asynch: true);
        print('=========== RECO: $recognitions');
        setState(() {
          var element = recognitions[0];
          double confidence = element['confidence'];
          String label = element['label'];
          if(label == '0 100bs'){
            if(confidence > 0.75){
              result = '100 Bolivianos';
              textToSpeech('100 Bolivianos');
            } else {
              result = 'No Hay Billete';
            }
          } else if(label == '1 10bs'){
            if(confidence > 0.95){
              result = '10 Bolivianos';
              textToSpeech('10 Bolivianos');
            } else {
              result = 'No Hay Billete';
            }
          } else if(label == '2 200bs'){
            if(confidence > 0.30){
              result = '200 Bolivianos';
              textToSpeech('200 Bolivianos');
            } else {
              result = 'No Hay Billete';
            }
          } else if(label == '3 20bs'){
            if(confidence > 0.35){
              result = '20 Bolivianos';
              textToSpeech('20 Bolivianos');
            } else {
              result = 'No Hay Billete';
            }
          } else if(label == '4 50bs'){
            if(confidence > 0.80){
              result = '50 Bolivianos';
              textToSpeech('50 Bolivianos');
            } else {
              result = 'No Hay Billete';
            }
          } else {
            result = 'Otro';
          }
          
          isWorking = false;
        });
      }
    } catch (e){
      print('===== ERROR: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
    initSpeech();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("Detector de Billetes"),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                height: MediaQuery.of(context).size.height - 170,
                width: MediaQuery.of(context).size.width,
                child: !cameraController.value.isInitialized
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                        child: CameraPreview(cameraController),
                      ),
              ),
            ),
            Text(
              result,
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20),
            )
          ],
        ),
      ),
    );
  }
}
