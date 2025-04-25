import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://sevdrykubdoynryfahjm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNldmRyeWt1YmRveW5yeWZhaGptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM4MzE1NzEsImV4cCI6MjA1OTQwNzU3MX0.TBYdyW6krJu6NP2Yhr6E8-CoDy6_bcc48hY1oEDguxY',
  );
  runApp(const LuckyTenCommandmentsApp());
}

class LuckyTenCommandmentsApp extends StatelessWidget {
  const LuckyTenCommandmentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '행운의 십계명 카드',
      theme: ThemeData(primarySwatch: Colors.deepPurple, fontFamily: 'Roboto'),
      home: const CommandmentCardPage(),
    );
  }
}

class CommandmentCardPage extends StatefulWidget {
  const CommandmentCardPage({super.key});

  @override
  State<CommandmentCardPage> createState() => _CommandmentCardPageState();
}

class _CommandmentCardPageState extends State<CommandmentCardPage> {
  int currentCardIndex = 0;
  List<Map<String, dynamic>> cards = [];
  TextEditingController memoController = TextEditingController();
  List<Map<String, dynamic>> memos = [];

  @override
  void initState() {
    super.initState();
    fetchCardsFromSupabase();
    loadMemos();
  }

  Future<void> fetchCardsFromSupabase() async {
    final response = await Supabase.instance.client.from('cards').select();
    final fetchedCards = List<Map<String, dynamic>>.from(response);

    if (fetchedCards.isNotEmpty) {
      final random = Random();
      final randomIndex = random.nextInt(fetchedCards.length);
      setState(() {
        cards = fetchedCards;
        currentCardIndex = randomIndex;
      });
    }
  }

  Future<void> saveMemo() async {
    final prefs = await SharedPreferences.getInstance();
    final memo = memoController.text.trim();
    if (memo.isNotEmpty && cards.isNotEmpty) {
      final card = cards[currentCardIndex];
      final newMemo = {'id': card['id'], 'title': card['title'], 'memo': memo};
      memos.add(newMemo);
      await prefs.setString('memos', jsonEncode(memos));
      memoController.clear();
      setState(() {});
    }
  }

  Future<void> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    final memoString = prefs.getString('memos');
    if (memoString != null) {
      try {
        final decodedData = jsonDecode(memoString);
        if (decodedData is List) {
          setState(() {
            memos = List<Map<String, dynamic>>.from(
              decodedData.whereType<Map<String, dynamic>>(),
            );
          });
        }
      } catch (e) {
        print('Error decoding memo data: $e');
      }
    }
  }

  void showAllMemos() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('📚 전체 메모 보기'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children:
                    memos.reversed.map((memo) {
                      return ListTile(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '📝',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                memo['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(memo['memo']),
                      );
                    }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '닫기',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xffdcd0f7),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final card = cards[currentCardIndex];
    final questions =
        card['questions'].map<String>((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: const Color(0xfffdf8ff),
      appBar: AppBar(
        title: const Text(
          '행운의 십계명 카드',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xffdcd0f7),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                '🎯 오늘의 실천 제목',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card['title'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '📖 오늘의 스토리',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(card['story'], style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              const Text(
                '❓ 실천을 위한 질문',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ...questions.map((q) => Text('• $q')).toList(),
              const SizedBox(height: 16),
              const Text(
                '✍️ 메모하기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              TextField(
                controller: memoController,
                decoration: const InputDecoration(
                  hintText: '오늘의 실천을 기록해보세요',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: saveMemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('📂 메모 저장'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        final random = Random();
                        currentCardIndex = random.nextInt(cards.length);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade100,
                    ),
                    child: const Text('🔄 새 카드 뽑기'),
                  ),
                  ElevatedButton(
                    onPressed: showAllMemos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade100,
                    ),
                    child: const Text('📁 내 메모 보기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
