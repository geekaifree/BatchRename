import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(const BatchRenameApp());

class BatchRenameApp extends StatelessWidget {
  const BatchRenameApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '批量重命名', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true, brightness: Brightness.light),
    darkTheme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true, brightness: Brightness.dark),
    home: const RenameHomePage(),
  );
}

class FileItem {
  String originalName, newName;
  FileItem({required this.originalName, required this.newName});
}

class RenameHomePage extends StatefulWidget {
  const RenameHomePage({super.key});
  @override
  State<RenameHomePage> createState() => _RenameHomePageState();
}

class _RenameHomePageState extends State<RenameHomePage> {
  List<FileItem> _files = [];
  String _mode = 'replace'; // replace, prefix, suffix, sequence, regex
  final _findCtrl = TextEditingController();
  final _replaceCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _suffixCtrl = TextEditingController();
  int _startNum = 1;
  int _digits = 3;
  String _caseMode = 'none'; // none, upper, lower, title

  final _modes = {'replace': '查找替换', 'prefix': '添加前缀', 'suffix': '添加后缀', 'sequence': '序列重命名', 'regex': '正则替换'};

  @override
  void initState() {
    super.initState();
    _files = [
      FileItem(originalName: 'IMG_20240101_001.jpg', newName: ''),
      FileItem(originalName: 'IMG_20240101_002.jpg', newName: ''),
      FileItem(originalName: 'IMG_20240101_003.jpg', newName: ''),
      FileItem(originalName: 'IMG_20240102_001.jpg', newName: ''),
      FileItem(originalName: '文档_报告_v1.docx', newName: ''),
      FileItem(originalName: '文档_报告_v2.docx', newName: ''),
      FileItem(originalName: '音乐_01.mp3', newName: ''),
      FileItem(originalName: '音乐_02.mp3', newName: ''),
    ];
    _applyRename();
  }

  void _applyRename() {
    setState(() {
      for (var f in _files) {
        String name = f.originalName;
        final ext = name.contains('.') ? '.${name.split('.').last}' : '';
        final base = ext.isNotEmpty ? name.substring(0, name.length - ext.length) : name;

        switch (_mode) {
          case 'replace':
            if (_findCtrl.text.isNotEmpty) name = base.replaceAll(_findCtrl.text, _replaceCtrl.text) + ext;
            else name = base + ext;
            break;
          case 'prefix':
            name = _prefixCtrl.text + base + ext;
            break;
          case 'suffix':
            name = base + _suffixCtrl.text + ext;
            break;
          case 'sequence':
            final idx = _files.indexOf(f) + _startNum;
            name = '${_prefixCtrl.text}${idx.toString().padLeft(_digits, '0')}${_suffixCtrl.text}$ext';
            break;
          case 'regex':
            try {
              if (_findCtrl.text.isNotEmpty) name = base.replaceAll(RegExp(_findCtrl.text), _replaceCtrl.text) + ext;
            } catch (_) {}
            break;
        }

        switch (_caseMode) {
          case 'upper': name = name.toUpperCase(); break;
          case 'lower': name = name.toLowerCase(); break;
          case 'title': name = name.splitMapJoin(RegExp(r'[\s_-]'), onMatch: (m) => m.group(0)!, onNonMatch: (n) => n.isNotEmpty ? '${n[0].toUpperCase()}${n.substring(1).toLowerCase()}' : n); break;
        }

        f.newName = name;
      }
    });
  }

  void _addFiles() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('添加文件'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '每行一个文件名', border: OutlineInputBorder()), maxLines: 8),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () {
          final names = ctrl.text.split('\n').where((n) => n.trim().isNotEmpty).map((n) => FileItem(originalName: n.trim(), newName: '')).toList();
          setState(() => _files.addAll(names));
          _applyRename();
          Navigator.pop(ctx);
        }, child: const Text('添加')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📝 批量重命名'), centerTitle: true, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addFiles, tooltip: '添加文件'),
        IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () => setState(() => _files.clear()), tooltip: '清空'),
      ]),
      body: Column(children: [
        // 重命名模式
        Container(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _modes.entries.map((e) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _mode == e.key, onSelected: (_) { setState(() => _mode = e.key); _applyRename(); }))).toList())),
          const SizedBox(height: 12),
          if (_mode == 'replace' || _mode == 'regex') ...[
            TextField(controller: _findCtrl, decoration: InputDecoration(hintText: _mode == 'regex' ? '正则表达式' : '查找文本', border: const OutlineInputBorder(), isDense: true), onChanged: (_) => _applyRename()),
            const SizedBox(height: 8),
            TextField(controller: _replaceCtrl, decoration: const InputDecoration(hintText: '替换为', border: OutlineInputBorder(), isDense: true), onChanged: (_) => _applyRename()),
          ],
          if (_mode == 'prefix') TextField(controller: _prefixCtrl, decoration: const InputDecoration(hintText: '前缀文本', border: OutlineInputBorder(), isDense: true), onChanged: (_) => _applyRename()),
          if (_mode == 'suffix') TextField(controller: _suffixCtrl, decoration: const InputDecoration(hintText: '后缀文本', border: OutlineInputBorder(), isDense: true), onChanged: (_) => _applyRename()),
          if (_mode == 'sequence') Row(children: [
            SizedBox(width: 80, child: TextField(controller: TextEditingController(text: _prefixCtrl.text), decoration: const InputDecoration(hintText: '前缀', border: OutlineInputBorder(), isDense: true), onChanged: (v) { _prefixCtrl.text = v; _applyRename(); })),
            const SizedBox(width: 8),
            SizedBox(width: 60, child: TextField(controller: TextEditingController(text: _startNum.toString()), decoration: const InputDecoration(hintText: '起始', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) { _startNum = int.tryParse(v) ?? 1; _applyRename(); })),
            const SizedBox(width: 8),
            SizedBox(width: 60, child: TextField(controller: TextEditingController(text: _digits.toString()), decoration: const InputDecoration(hintText: '位数', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, onChanged: (v) { _digits = int.tryParse(v) ?? 3; _applyRename(); })),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _suffixCtrl, decoration: const InputDecoration(hintText: '后缀', border: OutlineInputBorder(), isDense: true), onChanged: (v) { _suffixCtrl.text = v; _applyRename(); })),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Text('大小写: '),
            ChoiceChip(label: const Text('不变'), selected: _caseMode == 'none', onSelected: (_) { setState(() => _caseMode = 'none'); _applyRename(); }),
            const SizedBox(width: 4),
            ChoiceChip(label: const Text('大写'), selected: _caseMode == 'upper', onSelected: (_) { setState(() => _caseMode = 'upper'); _applyRename(); }),
            const SizedBox(width: 4),
            ChoiceChip(label: const Text('小写'), selected: _caseMode == 'lower', onSelected: (_) { setState(() => _caseMode = 'lower'); _applyRename(); }),
            const SizedBox(width: 4),
            ChoiceChip(label: const Text('首字母'), selected: _caseMode == 'title', onSelected: (_) { setState(() => _caseMode = 'title'); _applyRename(); }),
          ]),
        ])),
        const Divider(height: 1),
        // 文件列表
        Expanded(child: _files.isEmpty ? const Center(child: Text('点击 + 添加文件', style: TextStyle(color: Colors.grey))) : ListView.builder(itemCount: _files.length, itemBuilder: (ctx, i) {
          final f = _files[i];
          final changed = f.originalName != f.newName;
          return ListTile(dense: true, leading: Text('${i + 1}', style: const TextStyle(color: Colors.grey)), title: Text(f.originalName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)), subtitle: changed ? Text(f.newName, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)) : null, trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _files.removeAt(i))));
        })),
        // 操作按钮
        Container(padding: const EdgeInsets.all(12), child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _files.isEmpty ? null : () => setState(() { for (var f in _files) { f.newName = f.originalName; } }), icon: const Icon(Icons.undo), label: const Text('撤销'))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(onPressed: _files.isEmpty ? null : () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已重命名 ${_files.length} 个文件'), behavior: SnackBarBehavior.floating)); }, icon: const Icon(Icons.check), label: const Text('执行重命名'))),
        ])),
      ]),
    );
  }
}
