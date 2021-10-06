import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String url = "";
  final ImagePicker _imagePicker = ImagePicker();
  File? file;

  //get image function
  // ignore: non_constant_identifier_names
  get_image() async {
    var img = await _imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (img != null) {
        file = File(img.path);
      }
    });
  }

// upload image
  uploadFile() async {
    String date = DateTime.now().microsecondsSinceEpoch.toString();
    var imageFile = FirebaseStorage.instance.ref().child(date).child("/.jpg");
    UploadTask task = imageFile.putFile(file!);
    TaskSnapshot snapshot = await task;
    url = await snapshot.ref.getDownloadURL();
    FirebaseFirestore.instance.collection("image").doc().set({"ImageUrl": url});
    // ignore: avoid_print
    print(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Uploading..."),
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            InkWell(
              onTap: () {
                get_image();
              },
              child: CircleAvatar(
                radius: 80,
                // ignore: unnecessary_null_comparison
                backgroundImage: file == null
                    ? const AssetImage('ahmad.jpg')
                    : FileImage(File(file!.path)) as ImageProvider,
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  uploadFile();
                },
                child: const Text("Uploading..")),
            //for showing image in our app
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection("image").snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Loading");
                }
                if (snapshot.hasData) {
                  return GridView.builder(
                      shrinkWrap: true,
                      physics: const ScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 3),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, i) {
                        QueryDocumentSnapshot x = snapshot.data!.docs[i];
                        if (snapshot.hasData) {
                          return InkWell(
                            onDoubleTap: () => {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => View(
                                        url: x["ImageUrl"],
                                      )))
                            },
                            child: Hero(
                              tag: x["ImageUrl"],
                              child: Card(
                                child: Image.network(
                                  x["ImageUrl"],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        }
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            backgroundColor: Colors.red,
                          ),
                        );
                      });
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.red,
                    backgroundColor: Colors.red,
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class View extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final url;
  // ignore: use_key_in_widget_constructors
  const View({this.url});

  @override
  Widget build(BuildContext context) {
    return Hero(tag: url, child: Image.network(url));
  }
}
