import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const DevSecOpsReader());
}

class DevSecOpsReader extends StatelessWidget {
  const DevSecOpsReader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  Uint8List? _pdfBytes;
  bool _cekmeceAcikMi = false;

  Future<void> _dosyaSec() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pdfBytes = result.files.first.bytes;
      });
    }
  }

  Future<void> _linkeGit(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.inAppWebView)) {
      debugPrint('Link açılamadı: $url');
    }
  }

  void _altCekmeceyiAc(String secilenKelime) {
    if (_cekmeceAcikMi) return;
    _cekmeceAcikMi = true;

    final String cevirIcinSifreli = Uri.encodeComponent(secilenKelime);
    final String aramaIcinSifreli = Uri.encodeQueryComponent(
      "$secilenKelime nedir",
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.blueGrey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        bool renkPaletiAcik = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Seçilen: "$secilenKelime"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!renkPaletiAcik)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _linkeGit(
                              'https://translate.google.com/?sl=en&tl=tr&text=$cevirIcinSifreli&op=translate',
                            );
                          },
                          icon: const Icon(
                            Icons.translate,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Çevir',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _linkeGit(
                              'https://www.google.com/search?q=$aramaIcinSifreli',
                            );
                          },
                          icon: const Icon(Icons.search, color: Colors.white),
                          label: const Text(
                            'Ara',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            setModalState(() {
                              renkPaletiAcik = true;
                            });
                          },
                          icon: const Icon(Icons.palette, color: Colors.black),
                          label: const Text(
                            'İşaretle',
                            style: TextStyle(color: Colors.black),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const Text(
                          'Renk Seç:',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Sarı işaretlendi");
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.yellow,
                            radius: 20,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Yeşil işaretlendi");
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.greenAccent,
                            radius: 20,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Pembe işaretlendi");
                            Navigator.pop(context);
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.pinkAccent,
                            radius: 20,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _cekmeceAcikMi = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DevSecOps Reader',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.white),
            onPressed: _dosyaSec,
          ),
        ],
      ),
      body: _pdfBytes == null
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _dosyaSec,
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  'Bilgisayardan / Telefondan PDF Seç',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            )
          : SfPdfViewer.memory(
              _pdfBytes!,
              enableTextSelection: true,
              onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                if (details.selectedText != null &&
                    details.selectedText!.isNotEmpty) {
                  _altCekmeceyiAc(details.selectedText!);
                }
              },
            ),
    );
  }
}
