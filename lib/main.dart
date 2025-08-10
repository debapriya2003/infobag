import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:flutter_html/flutter_html.dart';

void main() {
  runApp(const MyApp());
}

/// Root App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfoBag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Times New Roman'),
          bodyMedium: TextStyle(fontFamily: 'Times New Roman'),
        ),
      ),
      home: const WikiSearchPage(),
    );
  }
}

/// Search Page
class WikiSearchPage extends StatefulWidget {
  const WikiSearchPage({super.key});

  @override
  _WikiSearchPageState createState() => _WikiSearchPageState();
}

class _WikiSearchPageState extends State<WikiSearchPage> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, String>> searchResults = [];
  bool isLoading = false;

  String stripHtml(String htmlText) {
    var document = parse(htmlText);
    return document.body?.text ?? "";
  }

  Future<void> searchWikipedia(String query) async {
    if (query.trim().isEmpty) return;
    final url = Uri.parse(
        'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$query&format=json');

    setState(() => isLoading = true);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final searchResultsData = data['query']['search'] as List;
      setState(() {
        searchResults = searchResultsData.map((item) {
          return {
            'title': item['title'].toString(),
            'snippet': stripHtml(item['snippet'].toString()),
          };
        }).toList();
      });
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: searchResults.isEmpty ? 1 : 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(30)
                  ),
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(
                        fontFamily: 'Times New Roman', fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "Search Your Topic",
                      hintStyle:
                          TextStyle(fontFamily: 'Times New Roman', fontSize: 18),
                      hintTextDirection: TextDirection.ltr,
                      border: InputBorder.none,
                    ),
                    onSubmitted: searchWikipedia,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!isLoading && searchResults.isNotEmpty)
              Expanded(
                flex: 3,
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(30)
                      ),
                      child: ListTile(
                        title: Text(
                          result['title']!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Times New Roman',
                              fontSize: 18),
                        ),
                        subtitle: Text(
                          result['snippet']!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Times New Roman', fontSize: 16),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WikiArticlePage(title: result['title']!),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Article Page with 2D style
class WikiArticlePage extends StatefulWidget {
  final String title;
  const WikiArticlePage({super.key, required this.title});

  @override
  _WikiArticlePageState createState() => _WikiArticlePageState();
}

class _WikiArticlePageState extends State<WikiArticlePage> {
  String articleHtml = "";
  bool isLoading = true;

  Future<void> fetchFullArticle() async {
    final url = Uri.parse(
        "https://en.wikipedia.org/api/rest_v1/page/html/${Uri.encodeComponent(widget.title)}");

    final response = await http.get(url, headers: {
      "User-Agent": "InfoBagApp/1.0 (https://example.com)"
    });

    if (response.statusCode == 200) {
      setState(() {
        articleHtml = response.body;
        isLoading = false;
      });
    } else {
      setState(() {
        articleHtml = "<p>Failed to load article.</p>";
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFullArticle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(fontFamily: 'Times New Roman')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(30)
                ),
                child: Html(
                  data: articleHtml,
                  style: {
                    "body": Style(
                      fontSize: FontSize(16),
                      fontFamily: 'Times New Roman',
                      lineHeight: LineHeight(1.5),
                    ),
                    "img": Style(
                      margin: Margins.symmetric(vertical: 12),
                    )
                  },
                ),
              ),
            ),
    );
  }
}
