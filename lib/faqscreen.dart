import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:webview_flutter/webview_flutter.dart';

// NEW:
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, String>> faqs = [
    {
      "question": "What is digital voting?",
      "answer":
          "Digital voting allows you to vote online securely, using modern technology to ensure privacy and transparency."
    },
    {
      "question": "Is online voting safe?",
      "answer":
          "Yes, online voting systems use encryption and authentication to ensure your vote remains private and tamper-proof."
    },
    {
      "question": "Can I change my vote after submission?",
      "answer":
          "No, once submitted, your vote is final. Please review carefully before submitting."
    },
    {
      "question": "How can I find my polling station?",
      "answer":
          "You can use the 'Find Poll Station' feature in the app to locate your nearest polling booth."
    },
  ];

  final List<Map<String, String>> userQA = [];
  final TextEditingController questionController = TextEditingController();
  bool isLoading = false;

  Future<String> getJotformAIAnswer(String question) async {
    final jotformApiKey = dotenv.env['JOTFORM_API_KEY'];
    if (jotformApiKey == null || jotformApiKey.isEmpty) {
      return "API key not configured.";
    }

    final url = Uri.parse("https://ai-chatbot.jotform.com/api/message");

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $jotformApiKey",
    };

    final body = jsonEncode({
      "message": question,
      // Optionally include your chatbotId here:
      // "chatbotId": "YOUR_CHATBOT_ID"
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      debugPrint("Jotform AI raw response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data["reply"] ?? data["message"] ?? data["answer"];
        if (text == null || text.toString().trim().isEmpty) {
          return "The AI didn't return an answer. Please try again.";
        }
        return text.toString().trim();
      } else {
        debugPrint("Jotform AI error: ${response.body}");
        return "Sorry, I couldn't get an answer from AI right now.";
      }
    } catch (e) {
      debugPrint("Jotform AI exception: $e");
      return "Error connecting to AI service.";
    }
  }

  void handleAskQuestion() async {
    final question = questionController.text.trim();
    if (question.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter your question."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final aiAnswer = await getJotformAIAnswer(question);

    setState(() {
      userQA.insert(0, {
        "question": question,
        "answer": aiAnswer,
      });
      questionController.clear();
      isLoading = false;
    });
  }

  void openChatbotWebView() {
    const chatbotUrl =
        'https://www.jotform.com/agent/0197cb42f59c725681c8515f12255f6da5d8';

    if (kIsWeb) {
      html.window.open(chatbotUrl, '_blank');
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 350,
            height: 500,
            child: WebViewWidget(
              controller: WebViewController()
                ..setJavaScriptMode(JavaScriptMode.unrestricted)
                ..loadRequest(Uri.parse(chatbotUrl)),
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FAQs & Education"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F9FD),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Text(
                  "Empower yourself with knowledge! Learn about digital voting, safety, and how to make your voice count.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              if (userQA.isNotEmpty) ...[
                Text(
                  "Your Questions",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                ...userQA.map(
                  (qa) => Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            qa['question']!,
                            style: TextStyle(
                              color: Colors.deepPurple.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            qa['answer']!,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade700,
                ),
              ),
              const SizedBox(height: 10),
              ...faqs.map(
                (faq) => Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      faq['question']!,
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Text(
                        faq['answer']!,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Floating AI button at the bottom right
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: openChatbotWebView,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.smart_toy, color: Colors.white),
              tooltip: "Ask AI Chatbot",
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
