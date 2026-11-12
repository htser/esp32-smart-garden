import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/api_service.dart';

/// 慢病类型定义（与后端 chronic_plans_v2.py 对齐）
const _kDiseases = <Map<String, String>>[
  {'id': 'diabetes', 'name': '糖尿病', 'icon': '🩸'},
  {'id': 'hypertension', 'name': '高血压', 'icon': '❤️'},
  {'id': 'hyperlipidemia', 'name': '高血脂', 'icon': '🧈'},
  {'id': 'gastritis', 'name': '胃病/消化不良', 'icon': '🍵'},
  {'id': 'insomnia', 'name': '睡眠障碍', 'icon': '🌙'},
  {'id': 'immunity', 'name': '免疫力调理', 'icon': '🛡️'},
];

/// 各病种检查指标定义（key 与后端 INDICATORS 一致）
const _kIndicators = <String, List<Map<String, String>>>{
  'diabetes': [
    {'key': 'fpg', 'name': '空腹血糖', 'unit': 'mmol/L'},
    {'key': 'ppg', 'name': '餐后 2 小时血糖', 'unit': 'mmol/L'},
    {'key': 'hba1c', 'name': '糖化血红蛋白', 'unit': '%'},
  ],
  'hypertension': [
    {'key': 'sbp', 'name': '收缩压(高压)', 'unit': 'mmHg'},
    {'key': 'dbp', 'name': '舒张压(低压)', 'unit': 'mmHg'},
  ],
  'hyperlipidemia': [
    {'key': 'tc', 'name': '总胆固醇', 'unit': 'mmol/L'},
    {'key': 'tg', 'name': '甘油三酯', 'unit': 'mmol/L'},
    {'key': 'ldl', 'name': '低密度脂蛋白', 'unit': 'mmol/L'},
  ],
  'gastritis': [
    {'key': 'symptom_score', 'name': '胃部症状自评', 'unit': '分 (0-5)'},
  ],
  'insomnia': [
    {'key': 'sleep_latency', 'name': '平均入睡时长', 'unit': '分钟'},
  ],
  'immunity': [
    {'key': 'cold_freq', 'name': '年均感冒次数', 'unit': '次/年'},
  ],
};

const _kDiseaseColor = <String, Color>{
  'diabetes': Color(0xFF185FA5),
  'hypertension': Color(0xFFC0392B),
  'hyperlipidemia': Color(0xFFBA7517),
  'gastritis': Color(0xFF2E7D32),
  'insomnia': Color(0xFF6C4FB0),
  'immunity': Color(0xFF0E7C7B),
};

/// 慢病种植定制 - 「慢病类型 + 患者检查信息 → 专业种植方案」完整链路
class ChronicAssessmentScreen extends StatefulWidget {
  /// 从健康页方案列表进入时可预选病种
  final List<String> initialConditions;

  const ChronicAssessmentScreen({super.key, this.initialConditions = const []});

  @override
  State<ChronicAssessmentScreen> createState() => _ChronicAssessmentScreenState();
}

class _ChronicAssessmentScreenState extends State<ChronicAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // 基本信息
  final _ageCtrl = TextEditingController(text: '55');
  String _gender = 'unknown';
  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '70');

  // 病种与指标
  late final Set<String> _conditions;
  bool _diagnosed = false;
  final Map<String, TextEditingController> _labCtrls = {};
  double _gastritisScore = 2;

  bool _submitting = false;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _conditions = {...widget.initialConditions};
    for (final d in _kDiseases) {
      for (final ind in _kIndicators[d['id']]!) {
        _labCtrls[ind['key']!] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    for (final c in _labCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(String key) {
    final t = _labCtrls[key]!.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Map<String, dynamic> _buildProfile() {
    final labs = <String, dynamic>{};
    for (final entry in _labCtrls.entries) {
      final v = _num(entry.key);
      if (v != null) labs[entry.key] = v;
    }
    labs['symptom_score'] = _gastritisScore.toInt();
    return {
      'age': int.tryParse(_ageCtrl.text) ?? 55,
      'gender': _gender,
      'height_cm': double.tryParse(_heightCtrl.text) ?? 170,
      'weight_kg': double.tryParse(_weightCtrl.text) ?? 70,
      'conditions': _conditions.toList(),
      'diagnosed_conditions': _diagnosed ? _conditions.toList() : <String>[],
      'labs': labs,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      final res = await api.recommendCrops(_buildProfile());
      if (!mounted) return;
      if (res['code'] == 0) {
        setState(() => _result = res['data'] as Map<String, dynamic>);
      } else {
        setState(() => _error = res['message']?.toString() ?? '生成失败，请稍后重试');
      }
    } catch (e) {
      if (mounted) setState(() => _error = '网络异常：$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      appBar: AppBar(
        title: const Text('慢病种植定制'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _result != null ? _buildResult() : _buildForm(),
    );
  }

  // ==================== 第一步：评估表单 ====================
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('① 基本信息'),
          _card(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _numField(_ageCtrl, '年龄', '岁')),
                    const SizedBox(width: 12),
                    Expanded(child: _numField(_heightCtrl, '身高', 'cm')),
                    const SizedBox(width: 12),
                    Expanded(child: _numField(_weightCtrl, '体重', 'kg')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('性别', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    const SizedBox(width: 12),
                    ...['male', 'female', 'unknown'].map((g) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text({'male': '男', 'female': '女', 'unknown': '不便告知'}[g]!),
                            selected: _gender == g,
                            selectedColor: const Color(0xFFDCEDC8),
                            onSelected: (_) => setState(() => _gender = g),
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('② 健康情况'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _kDiseases.map((d) {
                    final selected = _conditions.contains(d['id']);
                    return FilterChip(
                      avatar: Text(d['icon']!, style: const TextStyle(fontSize: 15)),
                      label: Text(d['name']!),
                      selected: selected,
                      selectedColor: const Color(0xFFDCEDC8),
                      checkmarkColor: const Color(0xFF2E7D32),
                      onSelected: (v) => setState(() {
                        v ? _conditions.add(d['id']!) : _conditions.remove(d['id']);
                      }),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('以上疾病已确诊', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('已确诊的病种将按确诊层级管理，而非预防层',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: _diagnosed,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _diagnosed = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('③ 检查信息（未填写的指标按参考范围内处理）'),
          if (_conditions.isEmpty)
            _card(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('请先在上方选择健康情况，这里会显示对应的检查指标输入项。',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ),
            ),
          ..._conditions.map((cid) {
            final d = _kDiseases.firstWhere((e) => e['id'] == cid);
            final color = _kDiseaseColor[cid]!;
            final indicators = _kIndicators[cid]!;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d['icon']} ${d['name']}检查',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 10),
                  if (cid == 'gastritis')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('胃部症状自评：${_gastritisScore.toInt()} 分（0 无症状 – 5 持续疼痛）',
                            style: const TextStyle(fontSize: 13)),
                        Slider(
                          value: _gastritisScore,
                          min: 0,
                          max: 5,
                          divisions: 5,
                          activeColor: color,
                          label: '${_gastritisScore.toInt()} 分',
                          onChanged: (v) => setState(() => _gastritisScore = v),
                        ),
                      ],
                    )
                  else
                    ...indicators.map((ind) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TextFormField(
                            controller: _labCtrls[ind['key']!],
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: ind['name'],
                              suffixText: ind['unit'],
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        )),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('生成专业种植方案', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(height: 10),
          const Text(
            '提示：不填写任何指标直接生成，将按对应病种的预防层/已确诊层给出方案。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== 第二步：分层方案结果 ====================
  Widget _buildResult() {
    final tiered = _result!['tiered_plan'] as Map<String, dynamic>;
    final slotPlan = _result!['slot_plan'] as Map<String, dynamic>;
    final schemes = (tiered['schemes'] as List).cast<Map<String, dynamic>>();
    final slots = (slotPlan['slots'] as List).cast<Map<String, dynamic>>();
    final overflow = (slotPlan['overflow'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 汇总条
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF43A047)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('已按 ${schemes.length} 个病种完成指标分层',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('合并后共占用 ${slotPlan['total_slots']} 个种植位（设备容量 8 位）',
                        style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 合并种植位
        _sectionTitle('合并种植位方案'),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((s) {
                  return Chip(
                    avatar: const Icon(Icons.grass, size: 16, color: Color(0xFF2E7D32)),
                    label: Text('${s['name']} ×${s['slots']}'),
                    backgroundColor: const Color(0xFFE8F5E9),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              if (overflow.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('种植位不足，以下品种移至社区站或下批种植：'
                    '${overflow.map((o) => o['crop']).join('、')}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFFBA7517))),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 分层方案卡片
        _sectionTitle('分层方案详情'),
        ...schemes.map((s) => _schemeCard(s)),
        const SizedBox(height: 8),

        // 免责声明
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0E0B0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: Color(0xFFBA7517)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(tiered['disclaimer']?.toString() ?? '',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF6B5A2E), height: 1.6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 应用与重评
        Consumer<DeviceProvider>(
          builder: (context, device, _) {
            final hasDevice = device.activeDeviceId.isNotEmpty;
            return Column(
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE8862E),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.eco_outlined),
                  label: Text(hasDevice ? '应用到我的菜园（${slots.length} 个品种）' : '暂无绑定设备'),
                  onPressed: hasDevice ? () => _applyToGarden(slots) : null,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _result = null),
                  child: const Text('重新评估', style: TextStyle(color: Color(0xFF2E7D32))),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _schemeCard(Map<String, dynamic> s) {
    final color = _kDiseaseColor[s['disease']] ?? const Color(0xFF2E7D32);
    final crops = (s['crops'] as List).cast<Map<String, dynamic>>();
    final sowing = (s['sowing'] as List).cast<Map<String, dynamic>>();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(s['disease_name'],
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(s['tier_name'],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2A2E26))),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('分层依据：${s['trigger']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        children: [
          // 目标
          _kvLine('管理目标', s['goal'], bold: true, color: color),
          const SizedBox(height: 12),
          // 种植位
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('种植位分配', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          ...crops.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('×${c['slots']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c['name']} · 约 ${c['days']} 天',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500)),
                          Text(c['benefit'],
                              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // 播种日历
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('播种日历', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 4),
          ...sowing.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(w['time'],
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32))),
                    ),
                    Expanded(
                      child: Text('${w['action']}\n${w['note']}',
                          style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          // 食用方案
          _bulletList('食用方案', (s['consumption'] as List).cast<String>()),
          const SizedBox(height: 8),
          // 监测计划
          _bulletList('监测计划', (s['monitor'] as List).cast<String>()),
          const SizedBox(height: 8),
          // 禁忌
          _bulletList('注意事项', (s['cautions'] as List).cast<String>(), warn: true),
        ],
      ),
    );
  }

  Future<void> _applyToGarden(List<Map<String, dynamic>> slots) async {
    final device = context.read<DeviceProvider>();
    final api = context.read<ApiService>();
    final deviceId = device.activeDeviceId;
    var slotNo = 1;
    var ok = 0;
    for (final s in slots) {
      final n = (s['slots'] as num).toInt();
      for (var i = 0; i < n; i++) {
        final res = await api.setCrop(deviceId, s['id'] as String, slot: slotNo);
        if (res['code'] == 0) ok++;
        slotNo++;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok == slotNo - 1
            ? '已下发 $ok 个种植位到菜园，去看看你的菜园吧'
            : '已下发 $ok 个种植位，部分槽位失败请重试'),
        backgroundColor: ok > 0 ? const Color(0xFF2E7D32) : Colors.red,
      ),
    );
  }

  // ==================== 小组件 ====================
  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2A2E26))),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: child,
      );

  Widget _numField(TextEditingController c, String label, String unit) => TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _kvLine(String k, String v, {bool bold = false, Color? color}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              child: Text(k,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
            ),
            Expanded(
              child: Text(v,
                  style: TextStyle(
                      fontSize: bold ? 13 : 12,
                      fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                      color: bold ? (color ?? Colors.black87) : Colors.black54,
                      height: 1.5)),
            ),
          ],
        ),
      );

  Widget _bulletList(String title, List<String> items, {bool warn = false}) {
    final color = warn ? const Color(0xFFC0392B) : const Color(0xFF2A2E26);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: warn ? const Color(0xFFC0392B) : const Color(0xFF2A2E26))),
        ),
        const SizedBox(height: 4),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(warn ? '⚠ ' : '· ',
                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Text(t, style: TextStyle(fontSize: 12, color: color, height: 1.5)),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
