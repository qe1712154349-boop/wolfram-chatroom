import 'package:flutter/material.dart';
import 'settings_page.dart';

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