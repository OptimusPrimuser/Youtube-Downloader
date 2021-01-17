import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Container;
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();

void main() {
  runApp(Phoenix(
    child: MaterialApp(
      home: FirstScreen(), //FirstScreen(),
    ),
  ));
}

class FirstScreen extends StatefulWidget {
  FirstScreen({Key key}) : super(key: key);

  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  var videoInfo;
  var url = "";
  var getURL = TextEditingController();
  var show = null;
  var quality;
  var yt = YoutubeExplode();
  var video;
  var download;
  var processing = false;

  @override
  void initState() {
    super.initState();
    setup();
  }

  setup() async {
    var status = await Permission.location.status;
    if (status.isUndetermined) {
      // We didn't ask for permission yet.
    }

    // You can can also directly ask the permission about its status.
    if (await Permission.storage.isRestricted) {
      // The OS restricts access, for example because of parental controls.
    }

    if (await Permission.storage.request().isGranted) {
      // Either the permission was already granted before or the user just granted it.
    }
    var temp =
        await getExternalStorageDirectories(type: StorageDirectory.downloads);
    download = temp[0].path.split("Android")[0] + "Youtube_Downloads";
    //print(download);
    if (await Directory(download).exists() == false) {
      Directory(download).create(recursive: true);
    }
  }

  getVideoInfo() async {
    await yt.videos.get(url);
    try {
      video = await yt.videos.get(url);

      var manifest = await yt.videos.streamsClient.getManifest(url);

      return {
        "title": video.title,
        "author": video.author,
        "duration": video.duration,
        "thumbnails": video.thumbnails,
        "quality": manifest.videoOnly.sortByVideoQuality(),
        "audio": manifest.audioOnly.withHighestBitrate()
      };
    } catch (e) {
      return "error";
    }
  }

  downloadVideo() async {
    processing = true;
    setState(() {});
    var manifest = await yt.videos.streamsClient.getManifest(url);

    var audio = manifest.audioOnly.withHighestBitrate();
    var downloadsDirectory = download;
    var tempDir = await getApplicationDocumentsDirectory();
    var tempPath = tempDir.path;
    if (quality == "audio") {
      Fluttertoast.showToast(
          msg: "Audio Downloading",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      //print("lol1");
      var mp3Stream = yt.videos.streamsClient.get(audio);
      //print("lol2");
      var mp3F = File(downloadsDirectory + "/" + video.title + ".mp3");
      var mp3FileStream = mp3F.openWrite();
      await mp3Stream.pipe(mp3FileStream);
      await mp3FileStream.flush();
      await mp3FileStream.close();
      Fluttertoast.showToast(
          msg: "Success",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: "Video And Audio Downloading",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      
      var mp3Stream = yt.videos.streamsClient.get(audio);
      var videoStream = yt.videos.streamsClient.get(quality);
      //print(downloadsDirectory + "/mp3.mp3");

      var mp3F = File(tempPath + "/mp3." + audio.container.toString());
      var videoF = File(tempPath + "/video." + quality.container.toString());

      var mp3FileStream = mp3F.openWrite();
      var videoFileStream = videoF.openWrite();

      await mp3Stream.pipe(mp3FileStream);
      await videoStream.pipe(videoFileStream);

      await mp3FileStream.flush();
      await mp3FileStream.close();
      await videoFileStream.flush();
      await videoFileStream.close();

      await Future.delayed(Duration(milliseconds: 500));
      Fluttertoast.showToast(
          msg: "Converting",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      _flutterFFmpeg
          .execute("-i " +
              tempPath +
              "/video." +
              quality.container.toString() +
              " -i " +
              tempPath +
              "/mp3." +
              audio.container.toString() +
              " -c:v copy -c:a aac -y " +
              downloadsDirectory +
              "/" +
              "\"" +
              video.title +
              ".mp4\"")
          .then((rc) {
        if (rc == 0) {
          Fluttertoast.showToast(
              msg: "downloaded to " +
                  downloadsDirectory +
                  "/" +
                  "\"" +
                  video.title +
                  ".mp4\"",
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        } else {
          Fluttertoast.showToast(
              msg: "Fail",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      });
    }
    processing = false;
    setState(() {});
  }

  downloadOrProcessButton() async {
    if (show == true) {
      downloadVideo();
    } else {
      url = getURL.text;
      videoInfo = await getVideoInfo();
      setState(() {
        if (videoInfo != "error") {
          show = true;
        } else if (videoInfo == "error") {
          show = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var widgetList = [
      Card(
        elevation: 0,
        key: Key("1"),
        child: TextField(
          controller: getURL,
          onChanged: (value) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: 'Youtube Link',
            hintStyle: TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white70,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
              borderSide: getURL.text == ""
                  ? BorderSide(color: Colors.black, width: 2)
                  : BorderSide(color: Colors.green, width: 3),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              borderSide: getURL.text == ""
                  ? BorderSide(color: Colors.red, width: 1)
                  : BorderSide(color: Colors.green, width: 3),
            ),
          ),
        ),
      ),
      if (show == false)
        Card(
            elevation: 10,
            key: Key("2"),
            child: Center(child: ListTile(title: Text("Wrong URL")))),
      if (show == true)
        Card(
            elevation: 10,
            key: Key("3"),
            child: ListTile(
                title: Image.network(videoInfo["thumbnails"].highResUrl))),
      if (show == true)
        Card(
            elevation: 10,
            key: Key("4"),
            child: ListTile(
                title: Text(
              videoInfo["title"],
              textAlign: TextAlign.center,
            ))),
      if (show == true)
        Card(
            elevation: 10,
            key: Key("5"),
            child: ListTile(
                title: Text(
              "by " + videoInfo["author"],
              textAlign: TextAlign.center,
            ))),
      if (show == true)
        Card(
            elevation: 10,
            key: Key("6"),
            child: ListTile(
              title: Text(
                "Duration: " + videoInfo["duration"].toString(),
                textAlign: TextAlign.center,
              ),
            )),
      if (show == true)
        Card(
            elevation: 10,
            child: RadioListTile(
              key: Key("7"),
              title: Text("mp3"),
              groupValue: quality,
              value: "audio",
              onChanged: (value) {
                quality = value;
                setState(() {});
              },
            )),
      if (show == true)
        for (int i = 0; i < videoInfo["quality"].length; i++)
          Card(
              elevation: 10,
              child: RadioListTile(
                key: Key(videoInfo["quality"][i].videoQualityLabel),
                title: Text(videoInfo["quality"][i].videoQualityLabel +
                    " " +
                    videoInfo["quality"][i].container.toString() +
                    "(" +
                    (videoInfo["quality"][i].size.totalMegaBytes +
                            videoInfo["audio"].size.totalMegaBytes)
                        .toStringAsFixed(2) +
                    " MB)"),
                subtitle: Text(
                    "CODEC " + videoInfo["quality"][i].videoCodec.toString()),
                value: videoInfo["quality"][i],
                groupValue: quality,
                onChanged: (value) {
                  quality = value;
                  setState(() {});
                },
              )),
      Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 1, 8.0, 1),
        child: OutlineButton(
            //elevation: 20,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(30.0)),
            borderSide: BorderSide(width: 1),
            color: Colors.white,
            key: Key("8"),
            child:
                (show == true) ? Text("Download Video") : Text("Process Video"),
            onPressed: processing ? null : downloadOrProcessButton),
      ),
      if (show == true)
        Container(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 1, 8.0, 1),
            child: OutlineButton(
                color: Colors.white,
                shape: new RoundedRectangleBorder(
                    borderRadius: new BorderRadius.circular(30.0)),
                borderSide: BorderSide(width: 1),
                key: Key("9"),
                child: Text("Clear"),
                onPressed: () {
                  Phoenix.rebirth(context);
                }),
          ),
        ),
    ];

    return Scaffold(
        appBar: AppBar(
          title: Text("Youtube Video/Audio Downloader"),
        ),
        body: Container(
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: PageView(
              children: [
                Center(
                    child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widgetList.length,
                  itemBuilder: (context, index) {
                    //print(index);
                    return widgetList[index];
                  },
                )),
                Container(
                  color: Colors.blue,
                  child: ListView(
                    children: [
                      Image.asset("images/author.jpg"),
                      Padding(padding: EdgeInsets.all(4)),
                      Center(
                          child: Text(
                        "Created by Rahul Sharma",
                        style: TextStyle(
                          fontSize: 25,
                        ),
                      )),
                      Padding(padding: EdgeInsets.all(4)),
                      Center(
                          child: Text(
                        "SDK Used Flutter",
                        style: TextStyle(fontSize: 20),
                      )),
                      Image.asset(
                        "images/flutter.jpeg",
                        fit: BoxFit.fitWidth,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
