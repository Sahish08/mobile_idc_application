import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';


void main() => runApp(new App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  List? _outputs;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('IDC Classifier',
            style:
                TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Column(
        children: [
          if (_image != null)
            Container(
                margin: EdgeInsets.all(8),
                child: Center(
                    child: Image.file(
                  _image!,
                  width: width * 0.9,
                  height: height * 0.4,
                  fit: BoxFit.fill,
                )))
          else
            Container(
              margin: EdgeInsets.all(8),
              child: Center(
                child: Text('No Image Selected!',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          _outputs != null
              ? Container(
                  margin: EdgeInsets.all(8),
                  child: Center(
                      child: Text('IDC Predictions',
                          style: TextStyle(color: Colors.black, fontSize: 20))))
              : Text(''),
          SingleChildScrollView(
            child: Column(
              children: _outputs != null
                  ? _outputs!.map((result) {
                      return Card(
                        color: Colors.red,
                        child: Container(
                          margin: EdgeInsets.all(8),
                          child: Text(
                            "${result["label"]} -  ${result["confidence"].toStringAsFixed(2)}",
                            style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList()
                  : [],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _optiondialogbox,
        backgroundColor: Colors.red,
        child: Icon(Icons.image),
      ),
    );
  }

  //camera method
  Future<void> _optiondialogbox() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.red,
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: Center(child:Text(
                      "Take Photo",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: openCamera,
                  ),
                  Divider(
                      color: Colors.black
                  ),
                  GestureDetector(
                    child: Center(child: Text(
                      "Select Photo",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: openGallery,
                  ),
                  _image != null ?
                  Divider(
                      color: Colors.black
                  ):Padding(padding:EdgeInsets.all(0)),
                  _image != null ?
                  GestureDetector(
                    child: Center(child: Text(
                      "Save image",
                      style: TextStyle(color: Colors.yellow, fontSize: 20.0),
                    ),
                    ),
                    onTap: saveImage,
                  ):Padding(padding:EdgeInsets.all(0))
                ],
              ),
            ),
          );
        });
  }

  Future loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
      model: "assets/model.tflite",
      labels: "assets/labels.txt",
    );
  }

  Future openCamera() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      cropImage(image.path);
    } else {
      return;
    }
    Navigator.of(context).pop();
  }

  Future openGallery() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      cropImage(image.path);
    } else {
      return;
    }
    Navigator.of(context).pop();
  }

  Future cropImage(filePath) async {
    final croppedImage = await ImageCropper().cropImage(
      sourcePath: filePath, aspectRatioPresets: [
      CropAspectRatioPreset.square,
      CropAspectRatioPreset.ratio3x2,
      CropAspectRatioPreset.original,
      CropAspectRatioPreset.ratio4x3,
      CropAspectRatioPreset.ratio16x9
    ],
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(
          title: 'Cropper',
        ),
      ],
    );
    if(croppedImage != null){
      setState((){
        _image = File(croppedImage.path);
      });
      classifyImage(croppedImage);
    } else {
      return;
    }
  }

  Future classifyImage(image) async {
    final result = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0,
      imageMean: 0.45,
      imageStd: 0.226,
    );
    setState(() {
      //Declare List _outputs in the class which will be used to show the classified class name and confidence
      _outputs = result;
    });
  }

  Future saveImage() async {
    GallerySaver.saveImage(_image!.path);
    Navigator.of(context).pop();
  }
}
