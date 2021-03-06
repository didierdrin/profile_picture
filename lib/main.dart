import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:profile_picture_firebase/user.dart';
import 'package:provider/provider.dart';
import 'package:firebase/firebase.dart' as fb;
import 'dart:html';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamProvider<CurrentUser>(
      create: (context) => userStream(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: ProfilePage(),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _currentUser = Provider.of<CurrentUser>(context);
    if (_currentUser == null) return Center(child: CircularProgressIndicator());
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 100),
            ProfilePicture(),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                uploadToStorage(_currentUser);
              },
              child: Text('Update Profile Picture'),
            )
          ],
        ),
      ),
    );
  }
}

class ProfilePicture extends StatelessWidget {
  const ProfilePicture({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _currentUser = Provider.of<CurrentUser>(context);
    if (_currentUser == null) return Center(child: CircularProgressIndicator());

    return StreamBuilder<Uri>(
        stream: downloadUrl(_currentUser.photoUrl).asStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          return Container(
            width: 200,
            height: 200,
            child: Image.network(snapshot.data.toString()),
          );
        });
  }
}

Stream<CurrentUser> userStream() {
  return FirebaseFirestore.instance
      .collection('users')
      .doc('OVuum60JcXsz9ZyLctIQ')
      .snapshots()
      .map((doc) => CurrentUser.fromDoc(doc));
}

Future<Uri> downloadUrl(String photo_url) {
  return fb
      .storage()
      .refFromURL('gs://profilepictureflutter.appspot.com')
      .child(photo_url)
      .getDownloadURL();
}

void uploadImage({@required Function(File file) onSelected}) {
  InputElement uploadInput = FileUploadInputElement()..accept = 'image/*';
  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final file = uploadInput.files.first;
    final reader = FileReader();
    reader.readAsDataUrl(file);
    reader.onLoadEnd.listen((event) {
      onSelected(file);
    });
  });
}

void uploadToStorage(CurrentUser user) {
  final dateTime = DateTime.now();
  final userId = user.id;
  final path = '$userId/$dateTime';

  uploadImage(onSelected: (file) {
    fb
        .storage()
        .refFromURL('gs://profilepictureflutter.appspot.com')
        .child(path)
        .put(file).future.then((_) => {
          FirebaseFirestore.instance.collection('users').doc(user.id).update({'photo_url': path}),
        });
  });
}
