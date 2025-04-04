import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'screens/loading_page.dart';
import 'screens/guardian_page.dart';
import 'dart:convert'; // 추가
import 'dart:typed_data'; // 추가
import 'package:image/image.dart' as imglib; // 추가
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';  // 추가
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'utils/font_manager.dart';
import 'utils/text_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  
  // 초기 폰트 로드
  final initialFont = await FontManager.getCurrentFont();
  
  runApp(MyApp(camera: cameras.first));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  
  const MyApp({Key? key, required this.camera}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시각장애인용 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: LoadingPage(camera: camera),
    );
  }
}

class ButtonPage extends StatefulWidget {
  final CameraDescription camera;
  
  const ButtonPage({Key? key, required this.camera}) : super(key: key);
  
  @override
  _ButtonPageState createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  late CameraController _controller;
  bool _isStreaming = false;
  int _frameCount = 0;
  double _buttonSize = 152.5;
  bool _isDarkMode = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  Color _buttonColor = Color.fromRGBO(72, 59, 25, 1);  // 기본 색상
  String _resultText = ""; // API 응답 텍스트 저장용
  Timer? _apiTimer; // API 호출 타이머
  String _currentMode = "";
  String _previousText = "";  // 이전 메시지 저장용
  bool _showMessage = true;  // 메시지 UI 표시 여부

  // backgroundColor를 getter로 변경
  Color get backgroundColor => _isDarkMode 
      ? Color.fromRGBO(50, 50, 50, 1)
      : Color.fromRGBO(255, 183, 2, 1);

  // 텍스트 색상을 getter로 추가
  Color get textColor => _isDarkMode 
      ? Colors.white
      : Colors.black87;

  final WebSocketChannel _channel = WebSocketChannel.connect(
    Uri.parse('ws://13.125.196.37:8080/image-websocket'), // 웹소켓 서버 주소
  );

  // 청크 크기를 32KB로 조정
  static const int chunkSize = 65536;  // 32KB

  // 이미지 전송을 위한 시퀀스 번호 추가
  int _sequenceNumber = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeCamera();
    _initializeAudio();
    _initTts();
    _setupWebSocketListener();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('ko-KR');  // 한어 설정
    await flutterTts.setSpeechRate(0.5);    // 말하기 속도 설정
    await flutterTts.setVolume(1.0);        // 볼륨 설정
    await flutterTts.setPitch(1.0);         // 음높이 설정
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();  // 기존 음성 중지
    await flutterTts.speak(text);
  }

  // 카메라 초기화 메서드 분리
  void _initializeCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  // 오디오 초기화 메서드 수정
  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/main_camera.mp3'));
      print('Audio initialized successfully');  // 디버깅용 로그
    } catch (e) {
      print('Error initializing audio: $e');  // 에러 로그
    }
  }

  // 오디오 재생 메서드 수정
  Future<void> _playAudio() async {
    try {
      await _audioPlayer.stop();  // 기존 재생 중지
      await _audioPlayer.resume();  // 재생 시작
      print('Audio playing');  // 디버깅용 로그
    } catch (e) {
      print('Error playing audio: $e');  // 에러 로그
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  // 설정 불러오기 메서드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _buttonSize = prefs.getDouble('buttonSize') ?? 182.5;
      _buttonColor = _isDarkMode
          ? Color.fromRGBO(72, 59, 25, 1)  // 어두운 모드 색상
          : Color.fromRGBO(255, 183, 2, 1); // 밝은 모드 색상
    });
  }

  // 설정 변경 감지를 위한 스너 추가
  void _startSettingsListener() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.reload().then((_) {
        setState(() {
          _isDarkMode = prefs.getBool('isDarkMode') ?? false;
          _buttonSize = prefs.getDouble('buttonSize') ?? 182.5;
          _buttonColor = !_isDarkMode
              ? Color.fromRGBO(72, 59, 25, 1)  // 어두운 모드 색상
              : Color.fromRGBO(255, 183, 2, 1); // 밝은 모드 색상
        });
      });
    });
  }

  // 대화 모드 API 호출 메서드
  Future<void> _fetchChatResult() async {
    try {
      final response = await http.get(
        Uri.parse('http://13.125.196.37:8080/api/info/chat')
      );
      
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        if (decodedResponse.isEmpty || decodedResponse == "null") {
          setState(() {
            _resultText = "";
            _showMessage = true;
            _previousText = "";
          });
        } else {
          setState(() {
            _resultText = decodedResponse;
            // 이전 메시지와 다를 경우에만 UI 활성화
            if (_resultText != _previousText) {
              _showMessage = true;
              _speak(_resultText);
              _previousText = _resultText;
            } else {
              _showMessage = false;  // 같은 메시지면 UI 비활성화
            }
          });
        }
      } else {
        setState(() {
          _resultText = "";
          _showMessage = true;
          _previousText = "";
        });
      }
    } catch (e) {
      print('대화 모드 API 호출 에러: $e');
      setState(() {
        _resultText = "";
        _showMessage = true;
        _previousText = "";
      });
    }
  }

  // 이동 모드 API 호출 메서드
  Future<void> _fetchMoveResult() async {
    try {
      final response = await http.get(
        Uri.parse('http://13.125.196.37:8080/api/info2/move')
      );
      
      if (response.statusCode == 200) {
        final decodedResponse = utf8.decode(response.bodyBytes);
        if (decodedResponse.isEmpty || decodedResponse == "null") {
          setState(() {
            _resultText = "";
            _showMessage = true;
            _previousText = "";
          });
        } else {
          setState(() {
            _resultText = decodedResponse;
            // 이전 메시지와 다를 경우에만 UI 활성화
            if (_resultText != _previousText) {
              _showMessage = true;
              _speak(_resultText);
              _previousText = _resultText;
            } else {
              _showMessage = false;  // 같은 메시지면 UI 비활성화
            }
          });
        }
      } else {
        setState(() {
          _resultText = "";
          _showMessage = true;
          _previousText = "";
        });
      }
    } catch (e) {
      print('이동 모드 API 호출 에러: $e');
      setState(() {
        _resultText = "";
        _showMessage = true;
        _previousText = "";
      });
    }
  }

  // 스트리밍 시작 메서드 수정
  void _startStreaming() async {
    if (!_controller.value.isInitialized) return;
    
    setState(() {
      _isStreaming = true;
      _frameCount = 0;
      _resultText = "";
    });

    // API 호출 타이머를 2초로 변경
    _apiTimer = Timer.periodic(Duration(seconds: 2), (_) {
      if (_currentMode == "대화") {
        _fetchChatResult();
      } else if (_currentMode == "이동") {
        _fetchMoveResult();
      }
    });

    await _controller.startImageStream((CameraImage image) {
      _frameCount++;
      if (_frameCount % 60 == 0) {
        _processAndSendImage(image);
      }
    });
  }

  // 스트리밍 중지 메서드 수정
  void _stopStreaming() async {
    if (_isStreaming) {
      _apiTimer?.cancel();
      await _controller.stopImageStream();
      setState(() {
        _isStreaming = false;
        _resultText = "";
      });
    }
  }

  // YUV 이미지를 JPEG로 변환 - 수정
  Uint8List yuvToJpeg(CameraImage image) {
      print("Image Format: ${image.format.group}"); // yuv420 format 확인

      final int width = image.width;
      final int height = image.height;

      // YUV420 데이터 처리
      final Uint8List yBuffer = image.planes[0].bytes;
      final Uint8List uBuffer = image.planes[1].bytes;
      final Uint8List vBuffer = image.planes[2].bytes;

      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      final int uvRowStride = image.planes[1].bytesPerRow;

      // RGB 데이터 생성
      imglib.Image rgbImage = imglib.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
              final int yIndex = y * width + x;
              final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

              // Y 데이터 인덱스 확인
              if (yIndex >= yBuffer.length) {
                  print("Y Buffer Index Out of Range: yIndex=$yIndex, Length=${yBuffer.length}");
                  continue;
              }

              // UV 데이터 확인
              if (uvIndex >= uBuffer.length || uvIndex >= vBuffer.length) {
                  print("UV Buffer Index Out of Range: uvIndex=$uvIndex, U Length=${uBuffer.length}, V Length=${vBuffer.length}");
                  continue;
              }

              final int yValue = yBuffer[yIndex] & 0xFF;
              final int uValue = uBuffer[uvIndex] & 0xFF;
              final int vValue = vBuffer[uvIndex] & 0xFF;

              // RGB 변환
              final int r = (yValue + 1.403 * (vValue - 128)).clamp(0, 255).toInt();
              final int g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128)).clamp(0, 255).toInt();
              final int b = (yValue + 1.770 * (uValue - 128)).clamp(0, 255).toInt();

              rgbImage.setPixel(x, y, imglib.ColorRgb8(r, g, b));
          }
      }

      // JPEG 인코딩
      final jpegData = imglib.encodeJpg(rgbImage);
      print("Total data size: ${jpegData.length} bytes"); // 데이터 크기 출력
      return Uint8List.fromList(jpegData);
  }

  // 이미지 처리 및 전송 - 추가
  void _processAndSendImage(CameraImage image) async {
    try {
      Uint8List jpegBytes = yuvToJpeg(image);
      
      final decodedImage = imglib.decodeImage(jpegBytes);
      if (decodedImage != null) {
        // 이미지를 90도 시계방향으로 회전
        final rotatedImage = imglib.copyRotate(decodedImage, angle: 90);
        
        // 회전된 이미지를 리사이즈
        final resizedImage = imglib.copyResize(
          rotatedImage,
          width: 224,
          height: 224
        );
        
        jpegBytes = Uint8List.fromList(imglib.encodeJpg(resizedImage, quality: 100));
      }

      String base64EncodedData = base64Encode(jpegBytes);
      
      if (_channel != null && _channel.sink != null) {
        _sequenceNumber++;
        sendImageWithLastChunk(base64EncodedData, chunkSize);
      }
    } catch (e) {
      print("이미지 처리 및 전송 오류: $e");
      _sequenceNumber = 0;
    }
  }

  void sendImageWithLastChunk(String base64EncodedData, int chunkSize) {
    try {
      int totalChunks = (base64EncodedData.length / chunkSize).ceil();
      int offset = 0;
      int currentChunk = 1;

      while (offset < base64EncodedData.length) {
        final end = (offset + chunkSize < base64EncodedData.length)
            ? offset + chunkSize
            : base64EncodedData.length;

        final chunk = base64EncodedData.substring(offset, end);
        
        // JSON 데이터 구조 개선
        final Map<String, dynamic> chunkData = {
          'sequence': _sequenceNumber,
          'chunk': currentChunk,
          'totalChunks': totalChunks,
          'data': chunk,
          'isLast': end == base64EncodedData.length,
        };

        // 마지막 청크에 모드 정보 추가
        if (end == base64EncodedData.length) {
          chunkData['mode'] = _currentMode;
        }

        // JSON 인코딩 및 전송
        _channel.sink.add(jsonEncode(chunkData));

        offset = end;
        currentChunk++;
      }
    } catch (e) {
      print("청크 전송 오류: $e");
      _sequenceNumber = 0; // 에러 발생 시 시퀀스 리셋
    }
  }

  // WebSocket 리스너 개선
  void _setupWebSocketListener() {
    _channel.stream.listen(
      (data) {
        try {
          final decodedData = jsonDecode(data.toString());
          print("Received from server: $decodedData");
        } catch (e) {
          print("WebSocket 데이터 처리 오류: $e");
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
        _handleWebSocketError();
      },
      onDone: () {
        print("WebSocket connection closed");
        _handleWebSocketClosure();
      },
    );
  }

  // WebSocket 에러 처리
  void _handleWebSocketError() {
    _sequenceNumber = 0;
    if (_isStreaming) {
      _stopStreaming();
    }
    _channel.sink.close();
    // 필요한 경우 재연결 로직 추가
  }

  // WebSocket 종료 처리
  void _handleWebSocketClosure() {
    _sequenceNumber = 0;
    if (_isStreaming) {
      _stopStreaming();
    }
    // 필요한 경우 재연결 로직 추가
  }

  @override
  void dispose() {
    _apiTimer?.cancel();
    flutterTts.stop();
    _stopStreaming();
    _controller.dispose();
    _channel.sink.close();  // 종료 시에만 close
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 설정 변경 감지 시작
    _startSettingsListener();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              if (_controller.value.isInitialized)
                Expanded(
                  flex: 3,
                  child: Semantics(
                    label: '카메라 화면입니다. 현재 촬영 중인 영상을 보여줍니다.',
                    onTapHint: 'main_camera.mp3',
                    child: GestureDetector(
                      onTap: () {
                        _speak('카메라 화면입니다. 현재 촬영 중인 영상을 보여줍니다.');
                        _playAudio();
                      },
                      child: Container(
                        margin: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.0),
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildCameraPreview(),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 0,
                    bottom: 0,
                  ),
                  color: backgroundColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildModeButton(
                            '대화',
                            'assets/chat_mode.png',
                            '표정을 확인하기 위해 카메라 촬영을 시작합니다.',
                          ),
                          SizedBox(width: 40),
                          _buildModeButton(
                            '이동',
                            'assets/move_mode.png',
                            '안전한 이동을 위해 카메라 촬영을 시작합니다.',
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      _buildUserTypeSelector(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeButton(String title, String assetPath, String semanticsLabel) {
    return Semantics(
      label: semanticsLabel,
      child: GestureDetector(
        onTap: () {
          if (_isStreaming) {
            _speak("촬영을 종료합니다");
            _stopStreaming();
          } else {
            setState(() {
              _currentMode = title;  // 현재 모드 저장
            });
            _speak(semanticsLabel);
            _startStreaming();
          }
        },
        child: Container(
          width: 152.5,
          height: 152.5,
          child: Stack(
            children: <Widget>[
              Container(
                width: 152.5,
                height: 152.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(39),
                  color: _buttonColor,
                  border: Border.all(
                    color: Color.fromRGBO(0, 0, 0, 1),
                    width: 1,
                  ),
                ),
              ),
              Positioned(
                top: _buttonSize * 0.28,
                left: _buttonSize * 0.12,
                child: SizedBox(
                  width: _buttonSize * 0.76,
                  child: FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: _buttonSize * 0.3,
                      color: Colors.white,
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1.2,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '${title.split(' ')[0]}',
                          textAlign: TextAlign.center,
                          style: snapshot.data,
                        );
                      }
                      return Text(
                        '${title.split(' ')[0]}',
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      margin: EdgeInsets.only( 
        bottom: 5,     // 하단 여백
      right: 0,     // 우측 여백
      top: 0,        // 상단 여백 추가 가능
      left: 25,
      ),
      padding: EdgeInsets.only(right: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Semantics(
            label: '사용자 모드 전환. 현재 사용자 모드입니다.',
            child: GestureDetector(
              onTap: () => _speak('��재 사용자 모드입니다.'),
              child: Container(
                width: 88,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: _buttonColor,
                  border: Border.all(
                    color: Color.fromRGBO(0, 0, 0, 1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 1.0,
                          color: Colors.black.withOpacity(1.0),
                        ),
                      ],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '사용자',
                          style: snapshot.data,
                        );
                      }
                      return Text('사용자');
                    },
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 100),
          Semantics(
            label: '보호자 모드로 전환. 탭하여 보호자 모드로 이동합니다.',
            child: GestureDetector(
              onTap: () {
                _speak('보호자 모드로 전환합니다.');
                GuardianPage.checkAndVibrate();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GuardianPage()),
                );
              },
              child: Container(
                width: 88,
                height: 43,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: _buttonColor,
                  border: Border.all(
                    color: Color.fromRGBO(0, 0, 0, 1),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 1.0,
                          color: Colors.black.withOpacity(1.0),
                        ),
                      ],
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '보호자',
                          style: snapshot.data,
                        );
                      }
                      return Text('보호자');
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CameraPreview를 포함하는 위젯 수정
  Widget _buildCameraPreview() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 카메라 프리뷰와 검은 테두리
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 3.0,
            ),
            borderRadius: BorderRadius.circular(23),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CameraPreview(_controller),
          ),
        ),
        
        // 촬영 중일 때 표시되는 UI 요소들
        if (_isStreaming) ...[
          // 촬영 중 표시
          Positioned(
            top: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '촬영 중',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 메시지 UI를 하단에 배치
          if (_resultText.isNotEmpty && _showMessage)
            Positioned(
              bottom: 32,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _resultText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}