import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:vibration/vibration.dart';
import '../main.dart';  // ButtonPage를 import하기 위해
import '../utils/text_styles.dart';
import '../utils/font_manager.dart';

class LoadingPage extends StatefulWidget {
  final CameraDescription camera;
  
  const LoadingPage({Key? key, required this.camera}) : super(key: key);
  
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSettings();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    
    /*// 진동 기능 추가
    Vibration.vibrate(duration: 500);
*/
    // 3초 후 ButtonPage로 이동
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ButtonPage(camera: widget.camera)),
      );
    });
  }

  Future<void> _loadSettings() async {
    final currentFont = await FontManager.getCurrentFont();
    setState(() {
      // 폰트 관련 상태 업데이트
    });
  }

  Widget _buildLegoBlock() {
    return Container(
      width: 120,  // 크기는 조정 가능
      height: 80,  // 크기는 조정 가능
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 183, 2, 1),  // 노란색
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 돌기 부분 (3x2 그리드)
          for (int i = 0; i < 3; i++)
            for (int j = 0; j < 2; j++)
              Positioned(
                top: 10 + (j * 30),
                left: 10 + (i * 40),
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 183, 2, 1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 412,
        height: 917,
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 183, 2, 1),
        ),
        child: Stack(
          children: <Widget>[
            // 하단 회색 영역
            Positioned(
              top: 586,
              left: 0,
              child: Container(
                width: 412,
                height: 333,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(91, 91, 91, 1),
                ),
              ),
            ),
            
            // 기존 "눈맞춤" 텍스트
            Positioned(
              top: 230,
              left: 170,
              child: Row(
                children: [
                  FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 60,
                      color: Color.fromRGBO(93, 95, 239, 1),
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '눈',
                          style: snapshot.data,
                        );
                      }
                      return Text('눈');
                    },
                  ),
                  FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 75,
                      color: Color.fromRGBO(93, 95, 239, 1),
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '맞',
                          style: snapshot.data,
                        );
                      }
                      return Text('맞');
                    },
                  ),
                  FutureBuilder<TextStyle>(
                    future: AppTextStyles.getTextStyle(
                      fontSize: 90,
                      color: Color.fromRGBO(93, 95, 239, 1),
                      letterSpacing: 0,
                      fontWeight: FontWeight.normal,
                      height: 1,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                          '춤',
                          style: snapshot.data,
                        );
                      }
                      return Text('춤');
                    },
                  ),
                ],
              ),
            ),

            // 레고 블록들 (먼저 배치하여 아래에 깔리도록)
            Positioned(
              top: 755,
              right: 90,
              child: _buildLegoBlock(),
            ),
            Positioned(
              top: 840,
              right: 90,
              child: _buildLegoBlock(),
            ),
            Positioned(
              bottom: 115,
              left: 200,
              child: _buildLegoBlock(),
            ),
            Positioned(
              bottom: 200,
              left: 200,
              child: _buildLegoBlock(),
            ),

            // walkingman.png를 나중에 배치하여 레고 블록들 위에 표시되도록 함
            Positioned(
              top: 151,
              left: -109,
              child: Container(
                width: 574,
                height: 686,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/walkingman.png'),
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),

            // 로딩 인디케이터
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromRGBO(93, 95, 239, 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 