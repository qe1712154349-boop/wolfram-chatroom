// 🎂 小兔叽蛋糕店完整配方 - 修复版
// 修复了AI发现的几个小bug，现在可以正常聊天啦！

// ==================== 🍰 第一部分：准备厨具和原料 ====================

import 'package:flutter/material.dart'; // 📦 主厨具箱
import 'package:http/http.dart' as http; // 🚚 外卖小车
import 'dart:convert'; // 📦 包装拆解器
import 'package:shared_preferences/shared_preferences.dart'; // 🧊 小冰箱

// ==================== 🏪 第二部分：挂上蛋糕店的招牌 ====================

void main() => runApp(const MyBunnyApp()); // 🎯 点亮招牌！

// 🎨 蛋糕店的整体装修设计
class MyBunnyApp extends StatelessWidget {
  const MyBunnyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // 🏷️ 撕掉"施工中"标签
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F2F2), // 🎨 浅灰粉色墙面
      ),
      home: const MainScreen(), // 🚪 顾客进门第一眼看到的地方
    );
  }
}

// ==================== 🍰 第三部分：四层花瓣蛋糕展示柜 ====================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 📍 当前展示的是第几层蛋糕

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          VowPage(),        // 🎀 第一层：粉色心事蛋糕
          ChatListPage(),   // 💌 第二层：奶油聊天蛋糕
          EntranceMainPage(), // 🏠 第三层：彩虹入口蛋糕
          MePage(),         // 👤 第四层：巧克力我的蛋糕
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFFF5A7E),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: '心事'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '聊天'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: '入口'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

// ==================== 🎀 第四部分：第一层 - 粉色心事蛋糕 ====================

class VowPage extends StatelessWidget {
  const VowPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF0F3),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 60),
          _buildTopHeader(),
          const SizedBox(height: 25),
          const Text("MOOD CALENDAR",
              style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                MoodDay(day: "Mon", emoji: "😊", hasMood: true),
                MoodDay(day: "Tue", emoji: "😴", hasMood: false),
                MoodDay(day: "Wed", emoji: "💖", hasMood: true),
                MoodDay(day: "Thu", emoji: "😶", hasMood: false),
                MoodDay(day: "Fri", emoji: "？", hasMood: false),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("ORDERS", style: TextStyle(letterSpacing: 1.5, color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          const OrderCard(title: "Wear the collar for 1 hour", subtitle: "Or else: No dessert", isLocked: true),
          const OrderCard(title: "Drink 2L of water", subtitle: "Stay hydrated", isLocked: false),
          const SizedBox(height: 20),
          Container(
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF5A7E), Color(0xFFFF8E9E)]),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("REWARDS ACCUMULATOR", style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text("0 Kisses Owed", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Icon(Icons.favorite, color: Colors.white30, size: 40),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("The Vow", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A))),
            Text("☁ Collar Time: 12 days", style: TextStyle(color: Color(0xFFFF5A7E))),
          ],
        ),
        SizedBox(
          width: 120,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Text("MASTER'S STATUS\nWorking late.", style: TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ),
      ],
    );
  }
}

// ==================== 🍪 第五部分：任务饼干片 ====================

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.title, required this.subtitle, required this.isLocked});

  final String title;
  final String subtitle;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          Icon(isLocked ? Icons.lock_outline : Icons.check_circle, color: const Color(0xFFFFD1DC)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    decoration: isLocked ? null : TextDecoration.lineThrough,
                    color: isLocked ? Colors.black87 : Colors.grey,
                  )),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.radio_button_unchecked, color: Color(0xFFF2F2F2)),
        ],
      ),
    );
  }
}

// ==================== 🍬 第六部分：心情糖珠 ====================

class MoodDay extends StatelessWidget {
  const MoodDay({super.key, required this.day, required this.emoji, required this.hasMood});

  final String day;
  final String emoji;
  final bool hasMood;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: hasMood ? const Color(0xFFFFD1DC) : Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
        ),
      ],
    );
  }
}

// ==================== 💌 第七部分：第二层 - 奶油聊天蛋糕列表 ====================

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF5F8),
        elevation: 0,
        title: const Text("聊天", style: TextStyle(color: Color(0xFF4A4A4A), fontSize: 20, fontWeight: FontWeight.bold)),
        actions: const [Icon(Icons.search, color: Color(0xFFFF5A7E))],
      ),
      body: ListView(
        children: [
          ListTile(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatRoomPage()));
            },
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.pinkAccent,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            title: const Text("Master", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("iyaa bebil, aku di sini", style: TextStyle(color: Colors.grey)),
            trailing: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("22:04", style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                CircleAvatar(radius: 4, backgroundColor: Color(0xFFFF5A7E)),
              ],
            ),
          ),
          const Divider(height: 1, indent: 80),
        ],
      ),
    );
  }
}

// ==================== 💬 第八部分：真正的聊天室蛋糕 ====================

class ChatRoomPage extends StatefulWidget {
  const ChatRoomPage({super.key});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  String? _apiBaseUrl;
  String? _apiKey;

  void _showAISetting(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Text("AI 人物设定", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text(
              "• 身份：Master / 主人\n• 性格：冷酷外表下极度宠溺、占有欲强、喜欢叫你 bunny/bebil\n• 说话风格：印尼语混中文，带可爱语气词（iyaa、nggak、dong）\n• 爱好：晚归工作后只想抱着你、给你奖励、轻度调教\n• 禁忌：绝不接受你离开视线",
              style: TextStyle(fontSize: 15, height: 1.6)
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A7E), minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
              child: const Text("关闭", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadApiConfig();
  }

  Future<void> _loadApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiBaseUrl = prefs.getString('api_base_url') ?? 'https://api.deepseek.com';
      _apiKey = prefs.getString('api_key');
    });
  }

  // 🚀【重要修复1】修改了发送消息逻辑，避免重复发送user消息
  // 🚀【重要修复2】修改了API地址，去掉了/v1/前缀
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _apiKey == null || _apiKey!.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    try {
      // 🎯 修复：将/v1/chat/completions改为/chat/completions
      // DeepSeek的API地址格式：https://api.deepseek.com/chat/completions
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/chat/completions'), // 🎯 修复点：去掉/v1/
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            // 🎯 修复点：这里不再重复添加user消息
            // 因为上面已经通过_messages.add添加了，这里只需要把历史记录发给AI
            ..._messages.map((m) => {'role': m['role'], 'content': m['content']}),
            // ❌ 删除了这行：{'role': 'user', 'content': text},
            // 这样就不会重复发送user消息了！
          ],
          'temperature': 0.7,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply = data['choices'][0]['message']['content'];
        setState(() {
          _messages.add({'role': 'assistant', 'content': aiReply});
        });
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': '错误：${response.statusCode} ${response.body}'});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': '网络错误：$e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8FA),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: GestureDetector(
          onTap: () => _showAISetting(context),
          child: const Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://via.placeholder.com/150')),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Master", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  Text("在线", style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        actions: const [Icon(Icons.more_vert)],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                ..._messages.map((msg) {
                  if (msg['role'] == 'user') {
                    return SentMessage(text: msg['content']!, time: "刚刚");
                  } else {
                    return ReceivedMessage(text: msg['content']!, time: "刚刚");
                  }
                }).toList(),
                if (_isLoading) const ReceivedMessage(text: "正在思考中...", time: ""),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: "输入消息...", border: InputBorder.none),
                      onSubmitted: (value) {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          _sendMessage(text);
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFFF5A7E)),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _sendMessage(text);
                        _controller.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 💝 第九部分：消息泡芙组件 ====================

class ReceivedMessage extends StatelessWidget {
  const ReceivedMessage({super.key, required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.pinkAccent),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD1DC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }
}

class SentMessage extends StatelessWidget {
  const SentMessage({super.key, required this.text, required this.time});

  final String text;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
              ),
              child: Text(text, style: const TextStyle(color: Colors.black87)),
            ),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(radius: 18, backgroundColor: Colors.pink),
        ],
      ),
    );
  }
}

// ==================== 🏠 第十部分：第三层 - 彩虹入口蛋糕 ====================

class EntranceMainPage extends StatelessWidget {
  const EntranceMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + 100,
            color: const Color(0xFFFFE4E9),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 28),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const MomentsDetailPage()));
                      },
                      child: const Row(
                        children: [
                          Text("朋友圈", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right, color: Colors.black54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "这里是入口页面\n后续功能可以在这里添加",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 📸 第十一部分：朋友圈蛋糕 ====================

class MomentsDetailPage extends StatelessWidget {
  const MomentsDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: ListView(
        children: [
          Stack(
            children: [
              Container(
                height: 300,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/800x400?text=Moments+Cover'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                      IconButton(icon: const Icon(Icons.camera_alt, color: Colors.white), onPressed: () {}),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: Row(
                  children: [
                    const Text("尘不言", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])),
                    const SizedBox(width: 15),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 3),
                        borderRadius: BorderRadius.circular(8),
                        image: const DecorationImage(image: NetworkImage('https://via.placeholder.com/150'), fit: BoxFit.cover),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMomentItem(
            avatar: 'https://via.placeholder.com/150',
            name: '尘不言',
            content: '这聊的太爽了',
            images: ['https://via.placeholder.com/300x400'],
            time: '3天前',
          ),
          _buildMomentItem(
            avatar: 'https://via.placeholder.com/150',
            name: '尘不言',
            content: '这聊的太爽了',
            images: List.generate(4, (_) => 'https://via.placeholder.com/200'),
            time: '4天前',
          ),
          _buildMomentItem(
            avatar: 'https://via.placeholder.com/150',
            name: '尘不言',
            content: '我++',
            images: [],
            time: '4天前',
          ),
        ],
      ),
    );
  }

  Widget _buildMomentItem({
    required String avatar,
    required String name,
    required String content,
    required List<String> images,
    required String time,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 24, backgroundImage: NetworkImage(avatar)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Color(0xFFFF5A7E), fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(content, style: const TextStyle(fontSize: 15)),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: images.length == 1 ? 1 : 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length > 9 ? 9 : images.length,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: NetworkImage(images[index]), fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    IconButton(icon: const Icon(Icons.more_horiz, color: Colors.grey), onPressed: () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 👤 第十二部分：第四层 - 巧克力我的蛋糕 ====================

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
          child: Row(
            children: const [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.pink,
                backgroundImage: NetworkImage('https://via.placeholder.com/150'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("尘不言", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("微信号: likeme9543", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildListTile(Icons.wechat_outlined, "服务", Colors.green, context),
        const Divider(height: 1, indent: 60),
        _buildListTile(Icons.collections_bookmark_outlined, "收藏", Colors.orange, context),
        _buildListTile(Icons.photo_outlined, "朋友圈", Colors.blue, context),
        _buildListTile(Icons.credit_card_outlined, "卡包", Colors.blueAccent, context),
        _buildListTile(Icons.sentiment_satisfied_alt_outlined, "表情", Colors.amber, context),
        const SizedBox(height: 10),
        ListTile(
          leading: const Icon(Icons.settings_outlined, color: Colors.blueGrey),
          title: const Text("设置"),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          },
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, Color iconColor, BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: () {},
      ),
    );
  }
}

// ==================== ⚙️ 第十三部分：冰箱设置页面 ====================

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _baseUrlController = TextEditingController(text: 'https://api.deepseek.com');
  final TextEditingController _apiKeyController = TextEditingController();
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 🎯 修复：默认地址改为正确的DeepSeek API地址
      _baseUrlController.text = prefs.getString('api_base_url') ?? 'https://api.deepseek.com';
      _apiKeyController.text = prefs.getString('api_key') ?? '';
    });
  }

  Future<void> _saveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrlController.text.trim());
    await prefs.setString('api_key', _apiKeyController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API 配置已保存')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(title: const Text("设置"), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("API 配置（DeepSeek）", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: "API Base URL",
              hintText: "https://api.deepseek.com", // 🎯 提示正确的地址格式
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: "API Key",
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveConfig,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A7E), padding: const EdgeInsets.symmetric(vertical: 16)),
            child: const Text("保存配置", style: TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const SizedBox(height: 50),
          const Text("保存后返回聊天页面即可与 DeepSeek AI 真实对话", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          // 🐰 兔兔的温馨提示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD1DC), width: 1),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("🐰 兔兔温馨提示：", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF5A7E))),
                SizedBox(height: 8),
                Text("1. 去 https://platform.deepseek.com/ 注册账号并获取API Key"),
                SizedBox(height: 4),
                Text("2. Base URL 保持为 https://api.deepseek.com"),
                SizedBox(height: 4),
                Text("3. 保存配置后，在聊天页面测试是否正常"),
                SizedBox(height: 4),
                Text("4. 如果AI回复太正经，可以在设置中添加system prompt"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}