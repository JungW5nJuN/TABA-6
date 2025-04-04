import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'guardian_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dotted_border/dotted_border.dart';
import '../utils/text_styles.dart';
import '../utils/font_manager.dart';

class FAQPage extends StatefulWidget {
  @override
  _FAQPageState createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  List<bool> _isExpanded = [false, false, false, false, false, false];
  bool _isDarkMode = false;
  Color _backgroundColor = Color.fromRGBO(255, 249, 196, 1);
  final FlutterTts flutterTts = FlutterTts();
  double questionFontSize = 20.0;  // 질문 텍스트 크기 변수
  double answerFontSize = 15.0;    // 답변 텍스트 크기 변수

  @override
  void initState() {
    super.initState();
    _loadSettings();
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

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // 설정 불러오기 메서드
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      bool isFontLarge = prefs.getBool('isFontLarge') ?? false;
      
      print('Current font size setting: ${isFontLarge ? "Large" : "Small"}');  // 디버깅용
      
      // 폰트 크기 설정 - 조건 반대로 변경
      if (isFontLarge) {  // isFontLarge가 false일 때 큰 폰트
        questionFontSize = 40.0;
        answerFontSize = 30.0;
      } else {            // isFontLarge가 true일 때 작은 폰트
        questionFontSize = 20.0;
        answerFontSize = 15.0;
      }

      _backgroundColor = _isDarkMode 
          ? Color.fromRGBO(50, 50, 50, 1)
          : Color.fromRGBO(255, 183, 2, 1);
    });
  }

  Widget _buildFAQItem(String text, String detailText, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded[index] = !_isExpanded[index];
          if (_isExpanded[index]) {
            _speak('$text, $detailText');
          } else {
            flutterTts.stop();
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.2)),
            bottom: BorderSide(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: questionFontSize,
                      color: Color.fromRGBO(14, 14, 14, 1),
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          text,
                          style: snapshot.data,
                        );
                      }
                      return Text(text);
                    },
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  _isExpanded[index] ? Icons.expand_less : Icons.expand_more,
                  color: Colors.black,
                ),
              ],
            ),
            if (_isExpanded[index])
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FutureBuilder<TextStyle>(
                  future: AppTextStyles.getTextStyle(
                    fontSize: answerFontSize,
                    color: Colors.black,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Text(
                        detailText,
                        style: snapshot.data,
                      );
                    }
                    return Text(detailText);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      toolbarHeight: 65,
      leading: Padding(  // leading에 Padding 추가
        padding: EdgeInsets.only(top: 18),  // 위에서부터의 여백 추가
        child: Semantics(
          label: '뒤로 가기. 탭하면 이전 모드로 돌아갑니다.',
          child: IconButton(
            icon: Icon(Icons.arrow_back),
            color: Color.fromRGBO(255,255,255,1),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      title: Padding(  // Padding을 추가하여 미세 조정 가능
        padding: EdgeInsets.only(top: 12),  // 위에서부터의 여백 추가
        child: FutureBuilder<TextStyle>(
          future: AppTextStyles.getTextStyle(
            fontSize: 22,
            color: Color.fromRGBO(255,255,255,1),
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
                'FAQ',
                style: snapshot.data,
              );
            }
            return Text('FAQ');
          },
        ),
      ),
      backgroundColor: _backgroundColor,
      elevation: 0,
      centerTitle: true,
    ),
      body: Container(
  width: MediaQuery.of(context).size.width,
  height: MediaQuery.of(context).size.height,
  decoration: BoxDecoration(
    color: Color.fromRGBO(255,255,255,1),
    border: Border(
      top: BorderSide(
        color: Colors.black,  // 테두리 색상
        width: 1.2,          // 테두리 굵기
      ),
    ),
  ),
        child: Stack(
          children: [
            // 메인 흰색 컨테이너
            Positioned(
              top: 0,
              left: 0,
              child: DottedBorder(
                color: Color.fromRGBO(255,255,255,1),  // 점선 색상
                strokeWidth: 1,       // 선 두께
                dashPattern: [3, 3],  // 점선 패턴 [선 길이, 간격]
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 640,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.81),
                  ),
                ),
              ),
            ),
            // FAQ 항목들을 함하는 ListView
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 620,
              child: ListView(
                physics: BouncingScrollPhysics(),
                children: [
                  _buildFAQItem(
                    '이 어플은 어떤 기능을 제공하나요?',
                    '이 어플은 시각장애인을 돕기 위해 설계되었며, 사용자가 대화하고 있는 사람의 얼굴을 분석해 나이대, 성별, 표정 등의 정보를 실시간으로 음성 피드백으로 제공합니다. 이를 통해 시각장애인 사용자들이 사회적 상호작용을 더 쉽게 할 수 있도록 돕습니다.',
                    0,
                  ),
                  _buildFAQItem(
                    '어플은 어떻게 작동하나요?',
                    '기기의 카메라를 사용해 실시간으로 영상을 촬영하고, AI 알고리즘을 이용해 시각 데이터를 분석합니다. 분석된 정보를 통해 상대방의 나이대, 성별, 표정을 추정하고, 이를 사용자에게 음성으로 안내해 줍니다',
                    1,
                  ),
                  _buildFAQItem(
                    '어플이 인식할 수 있는 표정 어떤 것이 있나요?',
                    '상대의 행복, 놀람, 무표정, 혐오, 분노, 슬픔의 감정을 인식할 수 있습니다. 이를 통해 상대방의 표정 상태를 사용자가 이해할 수 있도록 돕습니다.',
                    2,
                  ),
                  _buildFAQItem(
                    '어플이 사진이나 영상을 저장하나요?',
                    '어플은 가능한 한 기기 내에서 데이터를 처리하여 사용자 개인정보를 보호합니다. 사용자의 동의 없이는 이미지나 개인 데이터가 저장되지 않습니다.',
                    3,
                  ),
                  _buildFAQItem(
                    '어플은 어떤 기기에서 사용할 수 있나요?',
                    '이 어플은 Android와 iOS 기기에서 사용할 수 있으며, 최신 스마트폰을 지원합니다. 사용자의 접근성 기본적인 기능은 오프라인에서도 사용할 수 있지만, 고급 AI 분석이나 데이터 업데이트가 필요한 경우 인터넷 연결이 필요할 수 있습니다.',
                    4,
                  ),
                  _buildFAQItem(
                    '어플을 사용하려면 인터넷 연결이 필요한 것인가요?',
                    '기본적인 기능은 오프라인에서도 사용할 수 있지만, 고급 AI 분석이나 데이터 업데이트가 필요한 경우 인터넷 연결이 필요할 수 있습니다.',
                    5,
                  ),
                ],
              ),
            ),
            // 하단 문의하기 버튼
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 13,
                      color: Color.fromRGBO(0, 0, 0, 0.42),
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '궁금한 점은 문의해주세요',
                          textAlign: TextAlign.center,
                          style: snapshot.data,
                        );
                      }
                      return Text('궁금한 점은 문의해주세요');
                    },
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await _speak('메일 보내기, 궁금한 점은 문의해주세요.');
                      await GuardianPage.checkAndVibrate();  // 진동 확인 및 실행
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GuardianPage()),
                      );
                    },
                    child: Container(
                      width: 362,
                      height: 57,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        color: Color.fromRGBO(255, 67, 67, 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '메일 보내기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Roboto',
                          fontSize: 19.333332061767578,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}