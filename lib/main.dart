import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pixabay/const.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PixabayPage(),
    );
  }
}

class PixabayPage extends StatefulWidget {
  const PixabayPage({super.key});

  @override
  State<PixabayPage> createState() => _PixabayPageState();
}

class _PixabayPageState extends State<PixabayPage> {
  List<PixabayImage> pixabayImages = [];

  // APIを使用して画像を取得する
  // 非同期の関数になったため返り値の型にFutureがつき、さらに async キーワードが追加されました。
  Future<void> fetchImages(String text) async {
    // await で待つことで Future が外れ Response 型のデータを受け取ることができました。
    // 変数に再代入ががない場合は極力finalをつけるようにする
    // finalをつけることで型を省略できる
    final response = await Dio().get(
      'https://pixabay.com/api/',
      queryParameters: {
        'key': Const.apiKey,
        'q': text,
        'image_type': 'photo',
        'per_page': 100,
      },
    );
    print(response.data);
    final List hits = response.data['hits'];
    setState(() {});
    pixabayImages = hits.map((e) => PixabayImage.fromMap(e)).toList();
    pixabayImages.sort(((a, b) => b.likes.compareTo(a.likes)));
  }

  // 画像を共有する
  Future<void> shareImage(String url) async {
    // URLからダウンロード
    final response = await Dio().get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    // 一時ファイルに保存
    final dir = await getTemporaryDirectory();
    print(dir.path);
    final file =
        await File('${dir.path}/tmp_image.png').writeAsBytes(response.data);

    // FileをXFileに変換
    XFile xFile = XFile(file.path);
    // SHEREパッケージで共有
    Share.shareXFiles([xFile]);
  }

  @override
  void initState() {
    super.initState();
    fetchImages('moon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          decoration: const InputDecoration(
            fillColor: Colors.white70,
            filled: true,
          ),
          onFieldSubmitted: (text) {
            print(text);
            fetchImages(text);
          },
        ),
      ),
      body: GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: pixabayImages.length,
        itemBuilder: (context, index) {
          final pixabayImage = pixabayImages[index];
          return InkWell(
            onTap: () async {
              shareImage(pixabayImage.webformatURL);
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  pixabayImage.previewURL,
                  // 中心から拡大して画面いっぱいになるまで広がる
                  fit: BoxFit.cover,
                ),
                // fit: StackFit.expand,でこちらの要素も広がってしまうのでAlignで囲う
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    color: Colors.black54,
                    // 横に広げたい時はROW
                    child: Row(
                      // 要素が最小になる
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thumb_up_off_alt_outlined,
                          color: Colors.amber,
                        ),
                        Text(
                          pixabayImage.likes.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// APIから取得した情報のうち使用するものを定義する
class PixabayImage {
  final String webformatURL;
  final String previewURL;
  final int likes;

  PixabayImage(
      {required this.webformatURL,
      required this.previewURL,
      required this.likes});

  factory PixabayImage.fromMap(Map<String, dynamic> map) {
    return PixabayImage(
        webformatURL: map['webformatURL'],
        previewURL: map['previewURL'],
        likes: map['likes']);
  }
}
