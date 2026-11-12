# -*- coding: utf-8 -*-
"""
智菇小站 · 慢病种植方案推荐引擎 V2
====================================
输入：慢病类型 + 患者检查指标（血糖 / 血压 / 血脂 / 症状自评）
输出：指标分层 → 专业种植方案（种植位分配、播种日历、食用方案、监测计划、禁忌）

临床参考区间来源（公开指南通用切点）：
- 《中国 2 型糖尿病防治指南》：FPG / 2hPBG / HbA1c 诊断切点
- 《中国高血压防治指南》：血压分级（正常高值 / 1 级 / 2 级 / 3 级）
- 《中国成人血脂异常防治指南》：TC / TG / LDL-C / HDL-C 分层切点

⚠️ 免责声明：本引擎输出仅为饮食与种植辅助建议，不构成医疗诊断或治疗方案；
   任何药物调整必须遵医嘱。出现警报症状（黑便、胸痛、剧烈头痛等）请立即就医。
"""

from .crop_catalog import JIu_ZHEN_18_PIN

INF = float("inf")

# =====================================================================
# 一、检查指标参考区间与分层规则
#    tiers: [(下限含, 上限不含, tier_id, 标签)]；落在 normal 区间 → 不给 tier
# =====================================================================
INDICATORS = {
    "diabetes": [
        {"key": "fpg", "name": "空腹血糖", "unit": "mmol/L",
         "normal": (-INF, 6.1),
         "tiers": [(6.1, 7.0, "pre", "糖耐量异常（糖尿病前期）"),
                   (7.0, INF, "t2dm", "达到糖尿病诊断切点")]},
        {"key": "ppg", "name": "餐后 2 小时血糖", "unit": "mmol/L",
         "normal": (-INF, 7.8),
         "tiers": [(7.8, 11.1, "pre", "糖耐量异常（糖尿病前期）"),
                   (11.1, INF, "t2dm", "达到糖尿病诊断切点")]},
        {"key": "hba1c", "name": "糖化血红蛋白", "unit": "%",
         "normal": (-INF, 5.7),
         "tiers": [(5.7, 6.4, "pre", "糖尿病前期"),
                   (6.5, INF, "t2dm", "达到糖尿病诊断切点")]},
    ],
    "hypertension": [
        {"key": "sbp", "name": "收缩压", "unit": "mmHg",
         "normal": (90, 120),
         "tiers": [(120, 140, "high_normal", "正常高值"),
                   (140, 160, "htn1", "1 级高血压"),
                   (160, INF, "htn2", "2 级及以上高血压")]},
        {"key": "dbp", "name": "舒张压", "unit": "mmHg",
         "normal": (60, 80),
         "tiers": [(80, 90, "high_normal", "正常高值"),
                   (90, 100, "htn1", "1 级高血压"),
                   (100, INF, "htn2", "2 级及以上高血压")]},
    ],
    "hyperlipidemia": [
        {"key": "tc", "name": "总胆固醇", "unit": "mmol/L",
         "normal": (-INF, 5.18),
         "tiers": [(5.18, 6.19, "borderline", "边缘升高"),
                   (6.22, INF, "high", "升高")]},
        {"key": "tg", "name": "甘油三酯", "unit": "mmol/L",
         "normal": (-INF, 1.70),
         "tiers": [(1.70, 2.25, "borderline", "边缘升高"),
                   (2.26, INF, "high", "升高")]},
        {"key": "ldl", "name": "低密度脂蛋白胆固醇", "unit": "mmol/L",
         "normal": (-INF, 3.37),
         "tiers": [(3.37, 4.12, "borderline", "边缘升高"),
                   (4.14, INF, "high", "升高")]},
    ],
    "gastritis": [
        {"key": "symptom_score", "name": "胃部症状自评（0–5 分）", "unit": "分",
         "normal": (0, 1),
         "tiers": [(2, 3, "mild", "轻度不适（偶发）"),
                   (4, 5, "active", "反复发作（每周 ≥2 次）")]},
    ],
    "insomnia": [
        {"key": "sleep_latency", "name": "平均入睡时长", "unit": "分钟",
         "normal": (0, 30),
         "tiers": [(30, 60, "moderate", "入睡困难"),
                   (60, INF, "severe", "严重睡眠障碍")]},
    ],
    "immunity": [
        {"key": "cold_freq", "name": "年均感冒次数", "unit": "次/年",
         "normal": (0, 2),
         "tiers": [(3, INF, "general", "免疫力偏低信号")]},
    ],
}

# 分层严重度顺序（索引越大越重）
TIER_ORDER = {
    "diabetes": ["pre", "t2dm"],
    "hypertension": ["high_normal", "htn1", "htn2"],
    "hyperlipidemia": ["borderline", "high"],
    "gastritis": ["mild", "active", "alarm"],
    "insomnia": ["mild", "moderate", "severe"],
    "immunity": ["general"],
}

# 已确诊病种的兜底层（指标正常/未提供时，按已确诊层级管理）
DIAGNOSED_FLOOR = {
    "diabetes": "t2dm",
    "hypertension": "htn1",
    "hyperlipidemia": "high",
    "gastritis": "mild",
    "insomnia": "moderate",
    "immunity": "general",
}

# 作物功效说明（用于方案卡片，语气克制、可溯源）
CROP_BENEFIT = {
    "ku_gua": "苦瓜皂苷与多肽-P，研究提示可抑制 α-糖苷酶，辅助平稳餐后血糖",
    "bocai": "钾约 558mg/100g、镁与膳食纤维，拮抗钠、辅助降压",
    "qincai": "芹菜素与苯酞类挥发成分，研究提示舒张血管、辅助降压",
    "dasuanmiao": "大蒜素（切碎静置 10 分钟后生成），辅助改善血管弹性与胰岛素敏感性",
    "huanggua": "丙醇二酸抑制糖类转化，低糖高水分，生食友好",
    "hulu": "低热量高水分、利水消肿，糖尿病餐盘填充型蔬菜",
    "wosun": "菊粉低 GI，膳食纤维延缓糖吸收；传统安神食材",
    "mucai": "黏液蛋白与果胶，润滑肠道、辅助控糖降脂",
    "doujiao": "可溶性膳食纤维（半乳甘露聚糖），辅助减少胆固醇吸收",
    "tonghao": "挥发油与钾，开胃消食、辅助脂代谢",
    "pugongying": "蒲公英甾醇与钾，辅助利尿降脂、清热解毒（药食同源）",
    "nangua": "果胶保护胃黏膜，绵软易消化、低刺激",
    "huluobo": "β-胡萝卜素修复黏膜、抗氧化，熟食更友好",
    "xiaobaicai": "温和纤维、低刺激，胃病期主力绿叶菜",
    "ganlan": "维生素 U 样因子，胃黏膜修复传统食材",
    "juhua": "菊苷与挥发油，清肝安神（茶饮，3–5 朵/杯）",
    "bohe": "薄荷醇舒缓情绪、助消化（建议下午饮用，睡前不宜过量）",
    "luobo": "萝卜硫素与维C，抗氧化、免疫方案主力",
    "fanqie": "番茄红素（脂溶性，熟食吸收更好），抗氧化",
    "hongcaitai": "花青素与维C，紫红色蔬菜抗氧化",
    "shengcai": "28 天速生绿叶菜，保证每日绿色摄入与连续性",
    "shengcai2": "速生彩叶生菜，沙拉与轻食主力",
    "yangcong": "前列腺素A 与槲皮素，高血脂方案（生长期长，建议社区站种植）",
}

# =====================================================================
# 二、分层种植方案（slots = 种植位分配；设备 6–8 位，社区站可扩展）
# =====================================================================
PLAN_TIERS = {
    "diabetes": {
        "name": "糖尿病辅助管理",
        "tiers": {
            "pre": {
                "label": "糖耐量异常（前期）",
                "goal": "稳住餐后血糖波动，控制体重，争取逆转前期状态",
                "slots": [("ku_gua", 1), ("huanggua", 1), ("bocai", 1),
                          ("dasuanmiao", 1), ("shengcai", 2)],
                "sowing": [
                    ("第 1 周", "直播快菜、菠菜", "28–40 天速生，先建立每日采摘习惯"),
                    ("第 2–3 周", "直播大蒜苗；苦瓜/黄瓜育苗", "果菜类 60–70 天，光照位优先"),
                    ("第 4 周起", "每 2 周补播一批叶菜", "保证持续供应，避免集中成熟"),
                ],
                "consumption": [
                    "进餐顺序：先菜 → 再蛋白 → 后主食，平稳餐后血糖",
                    "苦瓜每日约 100g（凉拌/清炒），脾胃虚寒者减半",
                    "黄瓜生食每日 150–200g，替代部分零食",
                    "每日蔬菜合计 500g 以上，深色占一半",
                ],
                "monitor": ["空腹血糖 + 餐后 2h 血糖：每周 3 次",
                            "糖化血红蛋白：每 3 个月 1 次",
                            "体重/BMI：每月 1 次"],
                "cautions": [
                    "不种植高糖水果类作物，马铃薯/山药等高淀粉作物限量",
                    "苦瓜性寒，孕妇与脾胃虚寒者慎食",
                    "食疗为辅助，前期人群应优先生活方式干预并定期复查",
                ],
            },
            "t2dm": {
                "label": "糖尿病期",
                "goal": "辅助减少餐后血糖峰值，配合药物治疗与运动",
                "slots": [("ku_gua", 2), ("wosun", 1), ("huanggua", 1),
                          ("dasuanmiao", 1), ("shengcai2", 1), ("shengcai", 1)],
                "sowing": [
                    ("第 1 周", "直播紫叶生菜、快菜", "速生菜先行，2 周即可首收"),
                    ("第 2 周", "直播莴笋、大蒜苗", "低 GI 组合，莴笋约 50 天"),
                    ("第 3 周", "苦瓜育苗上盆 2 位", "全设备光照最优位，70 天连续采收"),
                    ("持续", "每 2 周补播速生菜", "采收一批、补播一批，不断茬"),
                ],
                "consumption": [
                    "苦瓜每日 100–150g，分 2 次食用；苦瓜汁建议餐前饮用（勿空腹）",
                    "莴笋、生菜作每日基础菜，生食前流水冲洗 30 秒以上",
                    "大蒜苗切碎静置 10 分钟后食用，大蒜素更充分",
                    "主食粗细搭配，餐盘蔬菜占比 ≥1/2",
                ],
                "monitor": ["空腹 + 餐后 2h 血糖：每周 3 次并记录",
                            "糖化血红蛋白：每 3 个月 1 次（目标值遵医嘱）",
                            "每年 1 次并发症筛查（眼底、肾功能、足部）"],
                "cautions": [
                    "严禁以种植食疗替代降糖药物；出现低血糖立即处理并复诊",
                    "苦瓜与降糖药存在协同效应，食用期加强血糖监测",
                    "肾功能不全者的高钾蔬菜（菠菜等）摄入需遵医嘱",
                ],
            },
        },
    },
    "hypertension": {
        "name": "高血压辅助管理",
        "tiers": {
            "high_normal": {
                "label": "正常高值",
                "goal": "通过高钾低钠饮食结构，延缓进展为高血压",
                "slots": [("qincai", 1), ("bocai", 2), ("dasuanmiao", 1),
                          ("shengcai", 1), ("shengcai2", 1)],
                "sowing": [
                    ("第 1 周", "直播菠菜、生菜、快菜", "30–40 天，快速收获建立信心"),
                    ("第 2–3 周", "直播大蒜苗；西芹育苗", "西芹约 60 天，需水量大"),
                    ("第 4 周起", "每 2 周补播叶菜", "保持每日可采"),
                ],
                "consumption": [
                    "高钾低钠：每日盐 <5g，用大蒜苗、薄荷、紫苏提味替代部分盐",
                    "芹菜每日 100–200g（焯水凉拌或快炒，保留钾）",
                    "大蒜切碎静置 10 分钟后生食或半生食",
                    "每日蔬菜 500g，深色蔬菜占 1/2 以上",
                ],
                "monitor": ["家庭血压测量：每周 2–3 次（晨起、睡前）",
                            "每 6 个月体检 1 次"],
                "cautions": [
                    "芹菜含钠量中等，「吃芹菜降压」不成立，不可替代药物",
                    "限盐是核心，种植端无法解决钠摄入，需配合饮食习惯调整",
                ],
            },
            "htn1": {
                "label": "1 级高血压",
                "goal": "辅助降压、保护血管，配合医嘱用药与限盐",
                "slots": [("qincai", 2), ("bocai", 2), ("dasuanmiao", 1),
                          ("shengcai", 1)],
                "sowing": [
                    ("第 1 周", "直播菠菜、快菜", "速生叶菜 30–40 天"),
                    ("第 2 周", "直播大蒜苗", "30 天可割，多次收割"),
                    ("第 2–3 周", "西芹育苗 2 位", "60 天，保持基质湿润"),
                    ("持续", "每 2 周补播", "菠菜畏热，夏季选耐热位"),
                ],
                "consumption": [
                    "芹菜每日 200g（分 2 餐），连茎叶一起利用",
                    "菠菜焯水后凉拌（草酸焯水去除，钾保留更佳）",
                    "每日盐 <5g，警惕酱油、腌制品中的隐性钠",
                    "适量食用富硒功能土种出的蔬菜，硒与钾协同",
                ],
                "monitor": ["晨起 + 晚间血压：每周 3 次并记录",
                            "每 3 个月复诊评估"],
                "cautions": [
                    "饮食为辅助手段，不可自行调整降压药",
                    "血压 ≥160/100mmHg 或出现头晕胸闷，及时就医",
                ],
            },
            "htn2": {
                "label": "2 级及以上高血压",
                "goal": "辅助管理 + 情绪舒缓，严格遵医嘱治疗",
                "slots": [("qincai", 2), ("bocai", 2), ("dasuanmiao", 1),
                          ("juhua", 1)],
                "sowing": [
                    ("第 1 周", "直播菠菜", "30–40 天"),
                    ("第 2 周", "直播大蒜苗、杭白菊上盆", "菊花为多年生盆栽，花叶均可利用"),
                    ("第 2–3 周", "西芹育苗 2 位", "60 天连续采收"),
                ],
                "consumption": [
                    "芹菜 200g/日 + 菠菜 200g/日，高钾主体",
                    "菊花茶每日 1 杯（3–5 朵，80℃ 水冲泡），辅助清肝安神",
                    "严格限盐 <5g/日，禁食腌制蔬菜",
                ],
                "monitor": ["血压：每周 4–5 次（早晚）",
                            "每 3 个月复诊；年度心肾功能评估"],
                "cautions": [
                    "2 级及以上高血压应立即就医评估，饮食仅作辅助",
                    "菊花茶不替代降压药物；合并肾病人群的钾摄入需遵医嘱",
                ],
            },
        },
    },
    "hyperlipidemia": {
        "name": "高血脂辅助管理",
        "tiers": {
            "borderline": {
                "label": "边缘升高",
                "goal": "以膳食纤维为杠杆，把指标拉回参考范围",
                "slots": [("mucai", 2), ("doujiao", 1), ("tonghao", 1),
                          ("pugongying", 1), ("shengcai", 1)],
                "sowing": [
                    ("第 1 周", "直播木耳菜、茼蒿、快菜", "35–40 天速生"),
                    ("第 2 周", "蒲公英直播", "40 天采嫩叶，多年生可续"),
                    ("第 3 周", "架豆角育苗", "60 天，需搭架（社区站/光照位）"),
                ],
                "consumption": [
                    "每日膳食纤维 ≥25g：豆角熟食、木耳菜清炒",
                    "蒲公英嫩叶凉拌，每周 3 次（每次约 100g）",
                    "烹饪以蒸煮凉拌为主，控制烹调油",
                ],
                "monitor": ["血脂四项：每 6 个月 1 次",
                            "体重与腰围：每月 1 次"],
                "cautions": [
                    "蒲公英性寒，脾胃虚寒者减量或焯水后食用",
                    "不依赖单一「降脂菜」，整体饮食结构才是关键",
                ],
            },
            "high": {
                "label": "升高",
                "goal": "辅助降低 LDL-C 与 TG，配合降脂药物治疗",
                "slots": [("mucai", 2), ("doujiao", 2), ("pugongying", 2)],
                "sowing": [
                    ("第 1 周", "直播木耳菜 2 位", "35 天起采收，可连续割 2 个月"),
                    ("第 2 周", "蒲公英 2 位直播", "嫩叶凉拌、老叶制茶"),
                    ("第 3 周", "架豆角 2 位育苗", "60 天，豆荚富含可溶性纤维"),
                    ("持续", "木耳菜每 2 周补播", "保证黏滑蔬菜不间断"),
                ],
                "consumption": [
                    "每日膳食纤维 ≥30g，豆角 + 木耳菜为主力",
                    "蒲公英每周 3–4 次（凉拌或蛋汤）",
                    "绝对避免动物内脏、油炸食品（饮食端配合）",
                ],
                "monitor": ["血脂四项：每 3 个月 1 次",
                            "肝功能（降脂药相关）：遵医嘱复查"],
                "cautions": [
                    "他汀类药物不可自行停用或减量",
                    "合并糖尿病者需同时参考糖尿病分层的控糖要求",
                ],
            },
        },
    },
    "gastritis": {
        "name": "胃病/消化不良调理",
        "tiers": {
            "mild": {
                "label": "轻度不适",
                "goal": "以温和、易消化、低刺激蔬菜养胃黏膜",
                "slots": [("nangua", 1), ("huluobo", 1), ("xiaobaicai", 2),
                          ("mucai", 1), ("shengcai", 1)],
                "sowing": [
                    ("第 1 周", "直播小白菜、快菜", "30 天，做熟食用"),
                    ("第 2 周", "胡萝卜、南瓜育苗", "南瓜 85 天、胡萝卜 70 天，社区站或长周期位"),
                    ("第 3 周", "木耳菜直播", "35 天，黏液蛋白润滑肠道"),
                ],
                "consumption": [
                    "全部做熟为主：小白菜清炒、南瓜蒸食，避免生冷",
                    "南瓜小米粥作为早餐主食，果胶保护胃黏膜",
                    "少食多餐，细嚼慢咽，每餐七分饱",
                ],
                "monitor": ["胃部症状自评：每周 1 次（0–5 分）",
                            "体重变化：每月 1 次"],
                "cautions": [
                    "不空腹食用苦瓜、薄荷等寒凉作物",
                    "记录并规避个人诱发食物（常见：浓茶、咖啡、辛辣）",
                ],
            },
            "active": {
                "label": "反复发作",
                "goal": "温和饮食 + 症状日记，必要时就医检查",
                "slots": [("nangua", 2), ("huluobo", 1), ("xiaobaicai", 2),
                          ("mucai", 1)],
                "sowing": [
                    ("第 1 周", "直播小白菜 2 位", "30 天，主力做熟菜"),
                    ("第 2 周", "胡萝卜、木耳菜", "熟食友好组合"),
                    ("第 2–3 周", "贝贝南瓜 2 位", "85 天，蒸食为主"),
                ],
                "consumption": [
                    "南瓜每日 100–200g（蒸/煮），胡萝卜每周 3–4 次做熟",
                    "小白菜做熟，避免凉拌生食",
                    "晚餐清淡少量，睡前 3 小时不进食",
                ],
                "monitor": ["症状自评 + 饮食日记：每日记录",
                            "每 2 周回顾 1 次，必要时消化科就诊"],
                "cautions": [
                    "反复发作建议胃镜检查明确诊断（如幽门螺杆菌）",
                    "忌辛辣、酒精、浓咖啡；紫苏、薄荷等辛香作物本期少用",
                ],
            },
            "alarm": {
                "label": "警报症状",
                "goal": "立即就医，本方案不提供食疗建议",
                "slots": [],
                "sowing": [],
                "consumption": ["出现黑便/呕血/持续剧痛/体重下降：立即就医"],
                "monitor": ["以消化科诊疗方案为准"],
                "cautions": [
                    "警报期不自行食疗；设备可暂不种植或仅种小白菜/南瓜做熟食用",
                ],
            },
        },
    },
    "insomnia": {
        "name": "睡眠障碍调理",
        "tiers": {
            "mild": {
                "label": "轻度",
                "goal": "以安神茶饮 + 睡眠卫生建立节律",
                "slots": [("juhua", 1), ("bohe", 1), ("wosun", 1),
                          ("shengcai2", 1), ("shengcai", 1), ("hulu", 1)],
                "sowing": [
                    ("第 1 周", "直播生菜、快菜", "30–40 天"),
                    ("第 2 周", "杭白菊、薄荷上盆", "多年生，可长期采摘"),
                    ("第 2–3 周", "莴笋、瓠瓜育苗", "莴笋约 50 天"),
                ],
                "consumption": [
                    "菊花茶：睡前 1 小时 1 杯（3–5 朵）",
                    "薄荷茶：下午饮用，提神舒缓；睡前不宜过量",
                    "莴笋作晚餐蔬菜，清淡少量",
                ],
                "monitor": ["入睡时长：每周记录 3 晚",
                            "晨起精神评分（1–10）：每周 1 次"],
                "cautions": [
                    "下午 4 点后避免浓茶与咖啡因",
                    "长期失眠（>3 个月）建议睡眠专科评估",
                ],
            },
            "moderate": {
                "label": "中度",
                "goal": "安神食材 + 严格睡眠卫生，2 周无改善就医",
                "slots": [("juhua", 2), ("bohe", 1), ("wosun", 2),
                          ("shengcai2", 1)],
                "sowing": [
                    ("第 1 周", "直播紫叶生菜", "40 天"),
                    ("第 2 周", "杭白菊 2 位上盆", "花量稳定后可每日 1 杯"),
                    ("第 2–3 周", "莴笋 2 位育苗", "50 天，晚餐主力"),
                ],
                "consumption": [
                    "菊花茶每日 1–2 杯，睡前 1 小时饮用",
                    "晚餐七分饱，以莴笋、生菜等清淡蔬菜为主",
                    "固定就寝与起床时间，周末不补觉超过 1 小时",
                ],
                "monitor": ["睡眠日记：每日记录入睡时长与夜醒次数",
                            "每 2 周评估一次，必要时睡眠专科就诊"],
                "cautions": [
                    "避免自行长期服用安眠类药物",
                    "菊花茶不替代失眠认知行为治疗（CBT-I）",
                ],
            },
            "severe": {
                "label": "重度",
                "goal": "睡眠专科就诊，种植仅作生活方式辅助",
                "slots": [("juhua", 2), ("bohe", 1), ("wosun", 2)],
                "sowing": [("第 2 周", "杭白菊 2 位 + 莴笋 2 位", "辅助食材供应")],
                "consumption": ["菊花茶睡前 1 小时 1 杯", "晚餐清淡少量"],
                "monitor": ["以睡眠专科诊疗方案为准"],
                "cautions": ["重度睡眠障碍需专业评估（排查焦虑、呼吸暂停等）"],
            },
        },
    },
    "immunity": {
        "name": "免疫力提升/抗衰老",
        "tiers": {
            "general": {
                "label": "日常保健",
                "goal": "彩虹饮食 + 富硒抗氧化，巩固免疫基线",
                "slots": [("luobo", 1), ("huluobo", 1), ("fanqie", 1),
                          ("doujiao", 1), ("shengcai2", 1), ("pugongying", 1)],
                "sowing": [
                    ("第 1 周", "直播樱桃萝卜、生菜", "30–40 天"),
                    ("第 2 周", "胡萝卜、蒲公英", "70 天 / 40 天"),
                    ("第 3 周", "樱桃番茄、架豆角育苗", "70 / 60 天，光照位"),
                    ("持续", "每 2 周补播速生菜", "彩虹配餐不断档"),
                ],
                "consumption": [
                    "彩虹饮食法：每日 ≥5 种颜色蔬菜（红/橙/紫/深绿/白）",
                    "番茄红素脂溶性，熟食加油脂吸收更好",
                    "富硒功能土种出的蔬菜每日 300–500g，硒助力抗氧化",
                ],
                "monitor": ["自评：感冒频率、伤口愈合速度、疲劳感（每月 1 次）"],
                "cautions": [
                    "保健方案不针对特定疾病；已病患者应叠加对应慢病方案",
                    "免疫力低下反复感染需就医排查原因",
                ],
            },
        },
    },
}

# 方案输出总免责声明
GLOBAL_DISCLAIMER = (
    "本方案由规则引擎基于公开指南切点生成，仅为饮食与种植辅助建议，"
    "不构成医疗诊断或治疗方案；任何药物调整必须遵医嘱。"
)

# 疾病合并优先级（多病共患时按此顺序分配种植位）
DISEASE_PRIORITY = ["gastritis", "hypertension", "diabetes",
                    "hyperlipidemia", "insomnia", "immunity"]


# =====================================================================
# 三、推荐引擎
# =====================================================================
class TieredRecommender:
    """检查指标 → 病情分层 → 专业种植方案"""

    def __init__(self):
        self.crops = JIu_ZHEN_18_PIN
        self.indicators = INDICATORS
        self.plans = PLAN_TIERS

    # ---------- 指标评估 ----------
    def evaluate(self, disease_id: str, labs: dict, diagnosed: bool = False) -> dict:
        rules = self.indicators.get(disease_id, [])
        order = TIER_ORDER[disease_id]
        evaluated, worst = [], None
        for rule in rules:
            v = labs.get(rule["key"])
            if v is None:
                continue
            tier_id, label = None, "参考范围内"
            for lo, hi, tid, tlabel in rule["tiers"]:
                if v >= lo and v < hi:
                    tier_id, label = tid, tlabel
                    break
            evaluated.append({
                "key": rule["key"], "name": rule["name"],
                "value": v, "unit": rule["unit"],
                "tier": tier_id, "tier_label": label,
            })
            if tier_id and (worst is None or order.index(tier_id) > order.index(worst)):
                worst = tier_id

        if worst is None:
            if diagnosed:
                worst = DIAGNOSED_FLOOR[disease_id]
                trigger = "指标在参考范围内或未提供，按已确诊层级管理"
            else:
                worst = order[0]
                trigger = "指标在参考范围内，按预防层管理"
        else:
            hits = [e for e in evaluated if e["tier"] == worst]
            trigger = "、".join(f"{e['name']} {e['value']}{e['unit']}" for e in hits)

        return {"disease": disease_id, "tier_id": worst,
                "trigger": trigger, "evaluated": evaluated}

    # ---------- 单病种方案 ----------
    def build_scheme(self, disease_id: str, evaluation: dict) -> dict:
        plan = self.plans[disease_id]
        tier = plan["tiers"][evaluation["tier_id"]]
        crops = []
        for cid, n in tier["slots"]:
            c = self.crops[cid]
            crops.append({
                "id": cid, "name": c["name"], "slots": n,
                "days": c["days"], "difficulty": c["difficulty"],
                "benefit": CROP_BENEFIT.get(cid, c["desc"]),
                "soil_moisture": c["soil_moisture"], "temp": c["temp"],
            })
        return {
            "disease": disease_id,
            "disease_name": plan["name"],
            "tier_id": evaluation["tier_id"],
            "tier_name": tier["label"],
            "trigger": evaluation["trigger"],
            "evaluated": evaluation["evaluated"],
            "goal": tier["goal"],
            "crops": crops,
            "total_slots": sum(n for _, n in tier["slots"]),
            "sowing": [{"time": t, "action": a, "note": n} for t, a, n in tier["sowing"]],
            "consumption": tier["consumption"],
            "monitor": tier["monitor"],
            "cautions": tier["cautions"],
            "disclaimer": GLOBAL_DISCLAIMER,
        }

    # ---------- 多病共患合并 ----------
    def merge_slots(self, schemes: list) -> dict:
        """按疾病优先级合并种植位，设备总容量 8 位，单品种 ≤2 位"""
        merged, overflow = {}, []
        for sch in sorted(schemes, key=lambda s: DISEASE_PRIORITY.index(s["disease"])
                          if s["disease"] in DISEASE_PRIORITY else 99):
            for c in sch["crops"]:
                if sum(merged.values()) >= 8:
                    overflow.append({"crop": c["name"], "from": sch["disease_name"]})
                    continue
                if merged.get(c["id"], 0) >= 2:
                    overflow.append({"crop": c["name"], "from": sch["disease_name"]})
                    continue
                merged[c["id"]] = merged.get(c["id"], 0) + c["slots"]
        return {"slots": [{"id": k, "name": self.crops[k]["name"], "slots": v}
                          for k, v in merged.items()],
                "total_slots": sum(merged.values()),
                "overflow": overflow}

    # ---------- 主入口 ----------
    def recommend(self, profile: dict) -> dict:
        conditions = profile.get("conditions", []) or []
        diagnosed = set(profile.get("diagnosed_conditions", []) or [])
        labs = dict(profile.get("labs", {}) or {})
        # 兼容旧档案字段
        if "fasting_glucose" in profile:
            labs.setdefault("fpg", profile["fasting_glucose"])
        if "blood_pressure" in profile and "sbp" not in labs:
            bp = profile["blood_pressure"]
            try:
                if isinstance(bp, (list, tuple)) and len(bp) >= 2:
                    labs.setdefault("sbp", float(bp[0]))
                    labs.setdefault("dbp", float(bp[1]))
                else:
                    sbp, dbp = str(bp).split("/")
                    labs.setdefault("sbp", float(sbp))
                    labs.setdefault("dbp", float(dbp))
            except Exception:
                pass

        schemes = []
        for cond in conditions:
            if cond not in self.plans:
                continue
            ev = self.evaluate(cond, labs, diagnosed=cond in diagnosed)
            schemes.append(self.build_scheme(cond, ev))

        if not schemes:
            ev = self.evaluate("immunity", labs)
            schemes.append(self.build_scheme("immunity", ev))

        return {
            "engine": "chronic-plans-v2",
            "conditions": conditions,
            "schemes": schemes,
            "merged_plan": self.merge_slots(schemes),
            "disclaimer": GLOBAL_DISCLAIMER,
        }
