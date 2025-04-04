import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'faq_page.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../utils/text_styles.dart';
import '../utils/font_manager.dart';

class GuardianPage extends StatefulWidget {
  // 진동 설정을 확인하고 실행하는 static 메서드
  static Future<void> checkAndVibrate() async {
    final prefs = await SharedPreferences.getInstance();
    bool isVibrationOn = prefs.getBool('isVibrationOn') ?? false;
    
    if (isVibrationOn) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {
        Vibration.vibrate(duration: 100);
      }
    }
  }

  @override
  _GuardianPageState createState() => _GuardianPageState();
}

class _GuardianPageState extends State<GuardianPage> with WidgetsBindingObserver {
  bool _isDarkMode = false;
  bool _isVibrationOn = false;
  bool _isFontLarge = false;
  double _buttonSize = 152.5;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  Color _buttonColor = Color.fromRGBO(72, 59, 25, 1);  // 기본 색상
  String _selectedFontFamily = 'Roboto'; // 기본 폰트
  List<Map<String, String>> _fontOptions = [
    {'name': 'Roboto', 'displayName': '기본'},
    {'name': 'SunBatang-Bold', 'displayName': '선명체 굵게'},
    {'name': 'SunBatang-Medium', 'displayName': '선명체 중간'},
    {'name': 'SunBatang-Light', 'displayName': '선명체 얇게'},
    {'name': 'KoddiUDOnGothic-Regular', 'displayName': '고딕체 기본'},
    {'name': 'KoddiUDOnGothic-ExtraBold', 'displayName': '고딕체 굵게'},
    {'name': 'KoddiUDOnGothic-Bold', 'displayName': '고딕체 중간'},
  ];
  
  // backgroundColor getter로 경
  Color get backgroundColor => _isDarkMode 
      ? Color.fromRGBO(50, 50, 50, 1)
      : Color.fromRGBO(255, 183, 2, 1);
  
  // 버튼 크기 관련 상수 추가
  static const double _minButtonSize = 142.5;
  static const double _maxButtonSize = 162.5;
  static const double _buttonSizeStep = 10.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _initializeAudio();
    _initTts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage('ko-KR');
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await flutterTts.stop();
    await flutterTts.speak(text);
  }

  // 설정 불러오기 메서드 수정
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentFont = await FontManager.getCurrentFont();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _isVibrationOn = prefs.getBool('isVibrationOn') ?? false;
      _buttonSize = prefs.getDouble('buttonSize') ?? 162.5;
      _isFontLarge = prefs.getBool('isFontLarge') ?? false;
      _selectedFontFamily = currentFont;
      
      _buttonColor = _isDarkMode
          ? Color.fromRGBO(255, 183, 2, 1)
          : Color.fromRGBO(72, 59, 25, 1);
    });
  }

  // 설정 저장하기 메서드 수정
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    await prefs.setBool('isVibrationOn', _isVibrationOn);
    await prefs.setDouble('buttonSize', _buttonSize);
    await prefs.setBool('isFontLarge', _isFontLarge);
    await prefs.setString('fontFamily', _selectedFontFamily); // 폰트 패밀리 저장
  }

// 진동 설정 토글 스위치
Widget _buildVibrationToggleSwitch() {
  return Semantics(
    label: '진동 설정 토글 버튼. 현재 ${_isVibrationOn ? "켜짐" : "꺼짐"} 상태입니다.',
    child: GestureDetector(
      onTap: () {
        setState(() {
          _isVibrationOn = !_isVibrationOn;
          _saveSettings();
        });
        _speak('진동 설정 토글 버튼. 현재 ${_isVibrationOn ? "켜짐" : "꺼짐"} 상태입니다.');
      },
      child: Container(
        width: 100,    // 여기서 토글 버튼의 너비 수정
        height: 50,   // 여기서 토글 버튼의 높이 수정
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),  // 버튼 모서리 둥글기 (높이의 절반 값 추천)
          color: _isVibrationOn 
            ? Color.fromRGBO(100, 142, 60, 1)
            : Color.fromRGBO(138, 137, 137, 1),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _isVibrationOn ? 50 : 10,  // 토글 원의 위치 (너비의 절반 값)
              top: 0,
              child: Container(
                width: 40,   // 토글 원의 너비 (높이와 동일하게)
                height: 50,  // 토글 원의 높이 (버튼 높이와 동일하게)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// 명도 설정 토글 스위치도 동일한 구조
Widget _buildToggleSwitch() {
  return Semantics(
    label: '명도 설정 토글 버튼. 현재 ${_isDarkMode ? "어두운 모드" : "밝은 모드"} 상태입니다.',
    child: GestureDetector(
      onTap: () {
        setState(() {
          _isDarkMode = !_isDarkMode;
          _buttonColor = _isDarkMode
              ? Color.fromRGBO(255, 183, 2, 1)  // 어두운 모드 색상
              : Color.fromRGBO(72, 59, 25, 1 ); // 밝은 모드 색상
          _saveSettings();
        });
        _speak('명도 설정 토글 버튼. 현재 ${_isDarkMode ? "어두운 모드" : "밝은 모드"} 상태입니다.');
      },
      child: Container(
        width: 100,    // 여기서 토글 버튼의 너비 수정
        height: 50,   // 여기서 토글 버튼의 높이 수정
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),  // 버튼 모서리 둥글기 (높이의 절반 값 추천)
          color: _isDarkMode 
            ? Color.fromRGBO(56, 142, 60, 1)
            : Color.fromRGBO(138, 137, 137, 1),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: _isDarkMode ? 50 : 10,  // 토글 원의 위치 (너비의 절반 값)
              top: 0,
              child: Container(
                width: 40,   // 토글 원의 너비 (높이��� 동일하게)
                height: 50,  // 토글 원의 높이 (버튼 높이와 동일하게)
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  // 페이지 이동 시 진동 실행 메서드
  void _vibrateIfEnabled() async {
    if (_isVibrationOn) {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator ?? false) {  // null일 경우 false를 사용
        Vibration.vibrate(duration: 100);  // 0.1초 동안 진동
      }
    }
  }

  // 버튼 크기 증가
  void _increaseButtonSize() {
    setState(() {
      if (_buttonSize < _maxButtonSize) {
        _buttonSize += _buttonSizeStep;
        _saveSettings();
      }
    });
  }

  // 버튼 크기 감소
  void _decreaseButtonSize() {
    setState(() {
      if (_buttonSize > _minButtonSize) {
        _buttonSize -= _buttonSizeStep;
        _saveSettings();
      }
    });
  }

  // 오디오 초기화 메서드
  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/main_camera.wav'));
      print('Audio initialized successfully');
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  // 오디오 재생 메서드 추가
  Future<void> _playAudio() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.resume();
      print('Audio playing');
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    flutterTts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
  toolbarHeight: 50,
  leading: Padding(  // leading에 Padding 추가
    padding: EdgeInsets.only(top: 18),  // 위에서부터의 여백 추가
    child: Semantics(
      label: '뒤로 가기. 탭하면 이전 모드로 돌아갑니다.',
      child: IconButton(
        icon: Icon(Icons.arrow_back),
        color: Color.fromRGBO(255,255,255,1),
        onPressed: () {
          _vibrateIfEnabled();
          Navigator.pop(context);
        },
      ),
    ),
  ),
      title: Padding(  // Padding을 추가하여 미세 조정 가능
        padding: EdgeInsets.only(top: 25),  // 위에서부터의 여백 추가
        child: Text(
          '보호자 페이지',
          style: _getTextStyle(
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
        ),
      ),
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: true,
    ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Stack(
          children: [
            // 메인 흰색 컨테이너
            Positioned(
              top: 25,
              left: 0,
              child: Container(
                width: 412,
                height: MediaQuery.of(context).size.height - 155,  // 상단바와 하단 네비게이션 고려
                decoration: BoxDecoration(
                  color: Color.fromRGBO(255, 255, 255, 1),
                  border: Border.all(
                    color: Colors.black,
                    width: 1,
                  ),
                ),
              ),
            ),
            // 스크롤 가능한 설정 ���목들
            Positioned(
              top: 25,
              left: 0,
              right: 0,
              bottom: 100,  // 하단 네비게이션을 위한 공간
              child: SingleChildScrollView(  // ListView 대신 SingleChildScrollView 사용
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Column(  // Stack 대신 Column 사용
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 진동 설정
                      Container(
                        padding: EdgeInsets.only(top: 25, left: 50),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 35,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '진동 설정',
                                style: snapshot.data,
                              );
                            }
                            return Text('진동 설정');
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 50, left: 150),
                        child: _buildVibrationToggleSwitch(),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 150),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 24,
                            letterSpacing: 0,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                'OFF/ON',
                                style: snapshot.data,
                              );
                            }
                            return Text('OFF/ON');
                          },
                        ),
                      ),

                      // 명도 설정
                      Container(
                        padding: EdgeInsets.only(top: 40, left: 50),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 35,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '명도 설정',
                                style: snapshot.data,
                              );
                            }
                            return Text('명도 설정');
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 50, left: 150),
                        child: _buildToggleSwitch(),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 150),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 24,
                            letterSpacing: 0,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                'OFF/ON',
                                style: snapshot.data,
                              );
                            }
                            return Text('OFF/ON');
                          },
                        ),
                      ),

                      // 폰트 크기
                      Container(
                        padding: EdgeInsets.only(top: 40, left: 50),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 35,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '폰트 크기',
                                style: snapshot.data,
                              );
                            }
                            return Text('폰트 크기');
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 50, left: 150),
                        child: _buildFontSizeToggleSwitch(),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 10, left: 150),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 24,
                            letterSpacing: 0,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                'OFF/ON',
                                style: snapshot.data,
                              );
                            }
                            return Text('OFF/ON');
                          },
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.only(top: 40, left: 50),
                        child: FutureBuilder<TextStyle>(
                          future: AppTextStyles.getTextStyle(
                            fontSize: 35,
                            height: 1,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Text(
                                '폰트 설정',
                                style: snapshot.data,
                              );
                            }
                            return Text('폰트 설정');
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.only(top: 25, left: 100),
                        child: _buildFontStyleSelector(),
                      ),

                      // FAQ 구분선
                      Container(
                        margin: EdgeInsets.only(top: 40),
                        width: 450,
                        height: 1,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                      ),

                      // FAQ 버튼
                      Container(
                        padding: EdgeInsets.only(top: 15, left: 18),
                        child: GestureDetector(
                          onTap: () async {
                            _speak("FAQ 페이지로 넘어갑니다");
                            await GuardianPage.checkAndVibrate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => FAQPage()),
                            );
                          },
                          child: Container(
                            width: 380,
                            height: 40,
                            color: Colors.transparent,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'faq',
                              style: _getTextStyle(
                                fontSize: 25,
                                height: 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 비게이션 (고정)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border(
                    top: BorderSide(
                      color: Colors.black,  // 테두리 색상
                      width: 1,            // 테두리 두께
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Semantics(
                      label: '사용자 모드로 전환. 탭하면 사용자 페이지로 돌아갑니다.',
                      child: GestureDetector(
                        onTap: () {
                          _speak('사용자 모드로 전환합니다.');
                          _vibrateIfEnabled();
                          Navigator.pop(context);
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
                            child: Text(
                              '사용자',
                              style: _getTextStyle(
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
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 100),
                    Semantics(
                      label: '보호자 모드 전환. 현재 보호자 모드입니다.',
                      child: GestureDetector(
                        onTap: () {
                          _speak('현재 보호자 모드입니다.');
                        },
                        child: Container
                        (
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
                            child: Text(
                              '보호자',
                              style: _getTextStyle(
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
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
  );
}

  // 원형 버튼 위젯
  Widget _buildCircularButton(String symbol) {
    String label = symbol == '-' 
        ? '버튼 크기 줄이기. 현재 크기: ${_buttonSize.toInt()}'
        : '버튼 크기 늘이기. 현재 크기: ${_buttonSize.toInt()}';
    
    return Semantics(
      label: label,
      child: GestureDetector(
        onTap: () {
          if (symbol == '-') {
            _decreaseButtonSize();
          } else {
            _increaseButtonSize();
          }
          _speak(label);
        },
        child: Container(
          width: 33,
          height: 33,
          decoration: BoxDecoration(
            color: Color.fromRGBO(217, 217, 217, 1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: symbol == '-'
                ? Divider(
                    color: Colors.black,
                    thickness: 2,
                    indent: 8,
                    endIndent: 8,
                  )
                : Text(
                    '+',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 토글 스위치 위젯
  Widget _buildFontSizeToggleSwitch() {
    return Semantics(
      label: '폰트 크기 설정 토글 버튼. 현재 ${_isFontLarge ? "ON" : "OFF"} 상태입니다.',
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _isFontLarge = !_isFontLarge;
          });
          await _saveSettings();  // 설정 변경 시 저장
          _speak('폰트 크기 설정 토글 버튼. 현재 ${_isFontLarge ? "ON" : "OFF"} 상태입니다.');
        },
        child: Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: _isFontLarge 
              ? Color.fromRGBO(100, 142, 60, 1)
              : Color.fromRGBO(138, 137, 137, 1),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                left: _isFontLarge ? 50 : 10,
                top: 0,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.black,
                          width: 1,
                        ),
                      ),
                    ),
                    Text(
                      "가",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'Roboto',
                        fontSize: _isFontLarge ? 30 : 15,  // 토글 상태에 따라 폰트 크기 변경
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 폰트 스타일 선택 위젯 수정
  Widget _buildFontStyleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _fontOptions.map((font) {
        bool isSelected = _selectedFontFamily == font['name'];
        return Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () async {
              setState(() {
                _selectedFontFamily = font['name']!;
              });
              await FontManager.setFont(font['name']!);
              _speak('${font['displayName']} 폰트가 선택되었습니다.');
              
              // 페이지 새로고침을 위해 setState 호출
              setState(() {});
            },
            child: Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? Color.fromRGBO(100, 142, 60, 1) : Color.fromRGBO(138, 137, 137, 1),
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '${font['displayName']} 샘플',
                  style: TextStyle(
                    fontFamily: font['name'],
                    fontSize: 18,
                    color: isSelected ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 페이지의 모든 Text 위젯에 fontFamily 적용
  TextStyle _getTextStyle({
    required double fontSize,
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
    double? letterSpacing,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: _selectedFontFamily,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }
} 