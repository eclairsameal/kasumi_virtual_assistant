import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../api/api_service.dart';


class HomeScreen extends StatefulWidget
{
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
{
  TextEditingController userInputTextEditingController = TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextUrlFromOpenAI = "";

  void initializeSpeechToText() async
  {
    await speechToTextInstance.initialize();
    setState(() {

    });
  }

  void startListeningNow() async
  {
    FocusScope.of(context).unfocus();
    await speechToTextInstance.listen(onResult: onSpeechToTextResult);
    setState(() {

    });
  }

  void stopListeningNow() async
  {
    await speechToTextInstance.stop();
    setState(() {

    });
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult)
  {
    recordedAudioString = recognitionResult.recognizedWords;

    speechToTextInstance.isListening
        ? null
        : sendRequestToOpenAI(recordedAudioString);

    print("Speech Result:");
    print(recordedAudioString);
  }

  Future<void> sendRequestToOpenAI(String userInput) async
  {
    stopListeningNow();

    setState(() {
      isLoading = true; // 發送請求需要一點時間，所以設定為 true
    });
    // 送要求給 openai 利用 APIService
    await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value)
    {
      setState(() {
        isLoading = false;
      });

      if(value.statusCode == 401)
      {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Api Key you are/were using expired or it is not working anymore.",
            ),
          ),
        );
      }
      userInputTextEditingController.clear();
      
      final responseAvailable = jsonDecode(value.body);

      if(modeOpenAI == "chat")
      {
        answerTextUrlFromOpenAI = utf8.decode(responseAvailable["choices"][0]["text"].toString().codeUnits);
      }
      else
      {
        // image generation
        setState(() {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];
        });
      }
      
    }).catchError((errorMessage){
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
              "Error: " + errorMessage.toString()
            ),
        ),
      );
    });
  }

  @override
  void initState(){
    super.initState();
    initializeSpeechToText();
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          
        },
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            "images/sound.png",
          ),
        ),
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purpleAccent.shade100,
                Colors.deepPurple,
              ]
            )
          ),
        ),
        title: Image.asset(
          "images/logo.png",
          width: 140,
        ),
        titleSpacing: 10,
        elevation: 14,
        actions: [

          //chat
          Padding(
            padding:  const EdgeInsets.only(right: 4, top: 4),
            child: InkWell(
              onTap: (){

              },
              child: const Icon(
                Icons.chat,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),

          //image
          Padding(
            padding:  const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: (){

              },
              child: const Icon(
                Icons.image,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 40,),
              Center(
                child: InkWell(
                  onTap: (){
                    speechToTextInstance.isListening
                        ? stopListeningNow()
                        : startListeningNow();
                  },
                    child: speechToTextInstance.isListening
                        ? Center(child: LoadingAnimationWidget.beat(
                            size: 300,
                            color: speechToTextInstance.isListening
                              ? Colors.deepPurple
                              : isLoading
                              ? Colors.deepPurple[400]!
                              : Colors.deepPurple[200]!
                        ),)
                        : Image.asset(
                      "images/assistant_icon.png",
                      height: 300,
                      width: 300,
                    ),
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              // text field with a button
              Row(
                children: [
                  // text field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: TextField(
                        controller: userInputTextEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "How can i help you?",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap:(){
                      print("send user input");  // Test button event
                      // stopListeningNow();
                      if(userInputTextEditingController.text.isNotEmpty)
                      {
                        sendRequestToOpenAI(userInputTextEditingController.text.toString());
                      }
                    },
                    child: AnimatedContainer(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.deepPurpleAccent,
                      ),
                      duration: const Duration(
                        milliseconds: 1000,
                      ),
                      curve: Curves.bounceInOut,
                      child: const Icon(
                        Icons.send,
                        // Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
