import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

String exampleWord = 'Мороз и солнце день чудесный Ещё ты дремлешь друг прелестный Пора красавица проснись Открой сомкнутые негой взоры Навстречу северной Авроры Звездою севера явись';
bool startSpech = false;

void main() => runApp(SpeechSampleApp());

class SpeechSampleApp extends StatefulWidget {
  @override
  _SpeechSampleAppState createState() => _SpeechSampleAppState();
}

/// Пример, демонстрирующий базовую функциональность
/// Плагин SpeechToText для использования возможности распознавания речи
/// базовой платформы.
class _SpeechSampleAppState extends State<SpeechSampleApp> {
  bool _hasSpeech = false;
  bool _logEvents = false;
  double level = 0.0;
  double minSoundLevel = 50000;
  double maxSoundLevel = -50000;
  String lastWords = '';
  String lastError = '';
  String lastStatus = '';
  String _currentLocaleId = '';
  List<LocaleName> _localeNames = [];
  final SpeechToText speech = SpeechToText();

  String resultWord = '';


  @override
  void initState() {
    super.initState();
    initSpeechState();
  }

  ///Инициализация SpeechToText.
  ///Делается один раз при запуске приложения, хотя повторный вызов безвреден
  ///тоже ничего не делает. UX примера приложения гарантирует, что
  ///его можно вызвать только один раз.
  Future<void> initSpeechState() async {
    _logEvent('Initialize');
    try {
      var hasSpeech = await speech.initialize(
        onError: errorListener,
        onStatus: statusListener,
        debugLogging: true,
      );
      if (hasSpeech) {
        // Получить список языков, установленных на поддерживающей платформе, чтобы они
        // могли отображаться в пользовательском интерфейсе для выбора пользователем.
        _localeNames = await speech.locales();

        var systemLocale = await speech.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
      }
      if (!mounted) return;

      setState(() {
        _hasSpeech = hasSpeech;
      });
    } catch (e) {
      setState(() {
        lastError = 'Speech recognition failed: ${e.toString()}';
        _hasSpeech = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
       /* appBar: AppBar(
          title: const Text('Speech to Text Example'),
        ),*/
        body: Column(children: [
          //HeaderWidget(),
          /*Container(
            child: Column(
              children: <Widget>[

                InitSpeechWidget(_hasSpeech, initSpeechState),
                SpeechControlWidget(_hasSpeech, speech.isListening, startListening, stopListening, cancelListening),
                SessionOptionsWidget(_currentLocaleId, _switchLang,_localeNames, _logEvents, _switchLogging),
              ],
            ),
          ),*/
          SizedBox(height: 50,),
          Expanded(
            flex: 4,
            child: startSpech ? RecognitionResultsWidget(lastWords: lastWords, level: level, resultWord: resultWord,) :
            GestureDetector(
              onTap: (){
                setState(() {
                  startSpech = true;
                });
                startListening();
                },
              child:Container(
              margin: const EdgeInsets.fromLTRB(16,0,16,0),
              padding: const EdgeInsets.fromLTRB(10,10,10,10),
              alignment: Alignment.topCenter,
              child:Text(exampleWord, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))
            ),
            ),
          ),
         /* Expanded(
            flex: 1,
            child: ErrorWidget(lastError: lastError),
          ),*/
          //SpeechStatusWidget(speech: speech),
        ]),
      ),
    );
  }

  // Это вызывается каждый раз, когда пользователи хотят начать новую речь.
  // сессия признания
  void startListening() {
    _logEvent('start listening');
    lastWords = '';
    resultWord = '';
    lastError = '';
    // Note that `listenFor` is the maximum, not the minimun, on some
    // recognition will be stopped before this value is reached.
    // Similarly `pauseFor` is a maximum not a minimum and may be ignored
    // on some devices.
    speech.listen(
        onResult: resultListener,
        listenFor: Duration(seconds: 60),
        pauseFor: Duration(seconds: 5),
        partialResults: true,
        localeId: _currentLocaleId,
        //localeId: 'en_EN',
        onSoundLevelChange: soundLevelListener,
        cancelOnError: true,
        listenMode: ListenMode.confirmation);
    setState(() {});
  }

  void stopListening() {
    _logEvent('stop');
    speech.stop();
    setState(() {
      level = 0.0;
      startSpech = false;
    });
  }

  void cancelListening() {
    _logEvent('cancel');
    speech.cancel();
    setState(() {
      level = 0.0;
      startSpech = false;
    });
  }

  /// Этот обратный вызов вызывается каждый раз, когда становятся доступны новые результаты распознавания после вызова `listen`.
  void resultListener(SpeechRecognitionResult result) {
    _logEvent(
        'Result listener final: ${result.finalResult}, words: ${result.recognizedWords}');
    setState(() {
      //lastWords = '${result.recognizedWords} - ${result.finalResult}';
      lastWords = result.recognizedWords;
      resultWord = result.recognizedWords;
    });
  }

  void soundLevelListener(double level) {
    minSoundLevel = min(minSoundLevel, level);
    maxSoundLevel = max(maxSoundLevel, level);
    // _logEvent('sound level $level: $minSoundLevel - $maxSoundLevel ');
    setState(() {
      this.level = level;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    _logEvent(
        'Received error status: $error, listening: ${speech.isListening}');
    setState(() {
      lastError = '${error.errorMsg} - ${error.permanent}';
    });
  }

  void statusListener(String status) {
    _logEvent(
        'Received listener status: $status, listening: ${speech.isListening}');
    setState(() {
      lastStatus = '$status';
    });
  }

  void _switchLang(selectedVal) {
    setState(() {
      _currentLocaleId = selectedVal;
    });
    print(selectedVal);
  }

  void _logEvent(String eventDescription) {
    if (_logEvents) {
      var eventTime = DateTime.now().toIso8601String();
      print('$eventTime $eventDescription');
    }
  }

  void _switchLogging(bool? val) {
    setState(() {
      _logEvents = val ?? false;
    });
  }
}

/// Отображает последние распознанные слова и уровень звука.
class RecognitionResultsWidget extends StatelessWidget {
  const RecognitionResultsWidget({
    Key? key,
    required this.lastWords,
    required this.resultWord,
    required this.level,

  }) : super(key: key);

  final String lastWords;
  final String resultWord;
  final double level;





  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        /*Center(
          child: Text(
            'Recognized Words',
            style: TextStyle(fontSize: 22.0),
          ),
        ),*/
        /*Container(
          margin: const EdgeInsets.fromLTRB(16,0,16,0),
          padding: const EdgeInsets.fromLTRB(10,10,10,10),
          alignment: Alignment.topCenter,
          //width: MediaQuery.of(context).size.width - 40,
          child:RichText(
            textAlign: TextAlign.left,
            text: TextSpan(text:'${exampleWord.toLowerCase().indexOf(lastWords) > -1 ? exampleWord.substring(0,exampleWord.toLowerCase().indexOf(lastWords)) : exampleWord}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black,),
                children: <TextSpan>[
                  TextSpan(text: '${exampleWord.toLowerCase().indexOf(lastWords) > -1 ? exampleWord.substring(exampleWord.toLowerCase().indexOf(lastWords), exampleWord.toLowerCase().indexOf(lastWords) + lastWords.length) : ''}', style: const TextStyle(fontSize: 16.0, color: Colors.red,),),
                  TextSpan(text: '${exampleWord.toLowerCase().indexOf(lastWords) > -1 ? exampleWord.substring(exampleWord.toLowerCase().indexOf(lastWords) + lastWords.length,exampleWord.length-1) : ''}',
                    style: const TextStyle(fontSize: 16.0, color: Colors.green,),)
                ]
            ),),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16,0,16,0),
          padding: const EdgeInsets.fromLTRB(10,10,10,10),
          alignment: Alignment.topCenter,
          //width: MediaQuery.of(context).size.width - 40,
          child:RichText(
            textAlign: TextAlign.left,
            text: TextSpan(text:'${lastWords.toLowerCase().indexOf(exampleWord) > -1 ? lastWords.substring(0,lastWords.toLowerCase().indexOf(exampleWord)) : lastWords}',
                style: const TextStyle(fontSize: 16.0, color: Colors.black,),
                children: <TextSpan>[
                  TextSpan(text: '${lastWords.toLowerCase().indexOf(exampleWord) > -1 ? lastWords.substring(lastWords.toLowerCase().indexOf(exampleWord), lastWords.toLowerCase().indexOf(exampleWord) + exampleWord.length) : ''}', style: const TextStyle(fontSize: 16.0, color: Colors.red,),),
                  TextSpan(text: '${lastWords.toLowerCase().indexOf(exampleWord) > -1 ? lastWords.substring(lastWords.toLowerCase().indexOf(exampleWord) + lastWords .length,lastWords.length-1) : ''}',
                    style: const TextStyle(fontSize: 16.0, color: Colors.green,),)
                ]
            ),),
        ),*/
    Container(
    margin: const EdgeInsets.fromLTRB(16,0,16,0),
    padding: const EdgeInsets.fromLTRB(10,10,10,10),
    alignment: Alignment.topCenter,
    //width: MediaQuery.of(context).size.width - 40,
    child:RichText(
          text: TextSpan(
            children: highlightOccurrences(exampleWord, lastWords),
            style: const TextStyle(color: Colors.grey),
          ),
        ),
    ),

        /*Expanded(
          child: Stack(
            children: <Widget>[
              Container(
                color: Theme.of(context).selectedRowColor,
                child: Center(
                  child: Text(
                    lastWords,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned.fill(
                bottom: 10,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            blurRadius: .26,
                            spreadRadius: level * 1.5,
                            color: Colors.black.withOpacity(.05))
                      ],
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(50)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.mic),
                      onPressed: () => null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),*/
      ],
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Speech recognition available',
        style: TextStyle(fontSize: 22.0),
      ),
    );
  }
}

/// Показать текущий статус ошибки из распознавателя речи

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    Key? key,
    required this.lastError,
  }) : super(key: key);

  final String lastError;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Center(
          child: Text(
            'Error Status',
            style: TextStyle(fontSize: 22.0),
          ),
        ),
        Center(
          child: Text(lastError),
        ),
      ],
    );
  }
}

/// Элементы управления для запуска и остановки распознавания речи
class SpeechControlWidget extends StatelessWidget {
  const SpeechControlWidget(this.hasSpeech, this.isListening,
      this.startListening, this.stopListening, this.cancelListening,
      {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final bool isListening;
  final void Function() startListening;
  final void Function() stopListening;
  final void Function() cancelListening;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: !hasSpeech || isListening ? null : startListening,
          child: Text('Start'),
        ),
        TextButton(
          onPressed: isListening ? stopListening : null,
          child: Text('Stop'),
        ),
        TextButton(
          onPressed: isListening ? cancelListening : null,
          child: Text('Cancel'),
        )
      ],
    );
  }
}

class SessionOptionsWidget extends StatelessWidget {
  const SessionOptionsWidget(this.currentLocaleId, this.switchLang,
      this.localeNames, this.logEvents, this.switchLogging,
      {Key? key})
      : super(key: key);

  final String currentLocaleId;
  final void Function(String?) switchLang;
  final void Function(bool?) switchLogging;
  final List<LocaleName> localeNames;
  final bool logEvents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: [
              Text('Language: '),
              DropdownButton<String>(
                onChanged: (selectedVal) => switchLang(selectedVal),
                value: currentLocaleId,
                items: localeNames
                    .map(
                      (localeName) => DropdownMenuItem(
                    value: localeName.localeId,
                    child: Text(localeName.name),
                  ),
                )
                    .toList(),
              ),
            ],
          ),
          Row(
            children: [
              Text('Log events: '),
              Checkbox(
                value: logEvents,
                onChanged: switchLogging,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class InitSpeechWidget extends StatelessWidget {
  const InitSpeechWidget(this.hasSpeech, this.initSpeechState, {Key? key})
      : super(key: key);

  final bool hasSpeech;
  final Future<void> Function() initSpeechState;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        TextButton(
          onPressed: hasSpeech ? null : initSpeechState,
          child: Text('Initialize'),
        ),
      ],
    );
  }
}

/// Отображение текущего состояния listener
class SpeechStatusWidget extends StatelessWidget {
  const SpeechStatusWidget({
    Key? key,
    required this.speech,
  }) : super(key: key);

  final SpeechToText speech;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      color: Theme.of(context).backgroundColor,
      child: Center(
        child: speech.isListening
            ? Text(
          "I'm listening...",
          style: TextStyle(fontWeight: FontWeight.bold),
        )
            : Text(
          'Not listening',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


///моя функция маркирования
List<TextSpan> highlightOccurrences(String source, String query) {
  if (query == null || query.isEmpty || !source.toLowerCase().contains(query.toLowerCase())) {
    //startSpech = false;
    return [ TextSpan(text: source) ];
  }

  final matches = query.toLowerCase().allMatches(source.toLowerCase());

  int lastMatchEnd = 0;

  final List<TextSpan> children = [];
  for (var i = 0; i < matches.length; i++) {
    final match = matches.elementAt(i);

    if (match.start != lastMatchEnd) {
      children.add(TextSpan(
        text: source.substring(lastMatchEnd, match.start),
      ));
    }

    children.add(TextSpan(
      text: source.substring(match.start, match.end),
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
    ));

    if (i == matches.length - 1 && match.end != source.length) {
      children.add(TextSpan(
        text: source.substring(match.end, source.length),
      ));
    }

    lastMatchEnd = match.end;
  }
  return children;
}