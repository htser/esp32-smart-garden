"""
智菇小站品种库 - 九真十八品 + 慢病定制化种植方案
数据来源: 项目计划书 + 农业科普资料整理
"""

# ==================== 九真十八品 ====================
JIu_ZHEN_18_PIN = {
    "dami": {
        "name": "五常大米", "zhen": "亢真",
        "sci_name": "Oryza sativa", "days": 120,
        "light": {"on": 6, "off": 22, "rb": 70},
        "soil_moisture": [55, 70], "temp": [20, 30],
        "nutrition": {"kcal": 346, "se": 0.02, "protein": 7.2},
        "desc": "东北黑土黄金稻, 需水较多, 建议社区站大规模种植",
        "difficulty": 3,
    },
    "huanggua": {
        "name": "德惠老黄瓜", "zhen": "子真",
        "sci_name": "Cucumis sativus", "days": 55,
        "light": {"on": 6, "off": 20, "rb": 60},
        "soil_moisture": [60, 80], "temp": [18, 28],
        "nutrition": {"kcal": 15, "se": 0.01, "protein": 0.8},
        "desc": "皮薄肉厚, 生食口感佳, 适合家庭阳台",
        "difficulty": 2,
    },
    "tudou": {
        "name": "黄心土豆", "zhen": "厍真",
        "sci_name": "Solanum tuberosum", "days": 90,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [50, 65], "temp": [15, 24],
        "nutrition": {"kcal": 77, "se": 0.01, "protein": 2.0},
        "desc": "高产易种, 儿童科普热门品种",
        "difficulty": 1,
    },
    "pugongying": {
        "name": "蒲公英", "zhen": "水真",
        "sci_name": "Taraxacum mongolicum", "days": 40,
        "light": {"on": 5, "off": 20, "rb": 45},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 35, "se": 0.03, "protein": 1.6},
        "desc": "药食同源, 清热解毒, 慢病方案常用",
        "difficulty": 1,
    },
    "lianou": {
        "name": "白莲藕", "zhen": "水真",
        "sci_name": "Nelumbo nucifera", "days": 150,
        "light": {"on": 6, "off": 22, "rb": 65},
        "soil_moisture": [75, 90], "temp": [20, 32],
        "nutrition": {"kcal": 70, "se": 0.02, "protein": 1.9},
        "desc": "需深水箱培转基质种植, 社区站特色品种",
        "difficulty": 4,
    },
    "zicao": {
        "name": "紫苏", "zhen": "花真",
        "sci_name": "Perilla frutescens", "days": 45,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [18, 28],
        "nutrition": {"kcal": 37, "se": 0.02, "protein": 3.8},
        "desc": "去腥提香, 烧烤季刚需香料",
        "difficulty": 1,
    },
    "jiaopanmo": {
        "name": "椒盘蘑", "zhen": "蘑真",
        "sci_name": "Agaricus campestris", "days": 35,
        "light": {"on": 4, "off": 20, "rb": 30},
        "soil_moisture": [65, 80], "temp": [16, 24],
        "nutrition": {"kcal": 22, "se": 0.05, "protein": 3.1},
        "desc": "富硒含量高, 鲜香浓郁",
        "difficulty": 3,
    },
    "dasuanmiao": {
        "name": "大蒜苗", "zhen": "菜真",
        "sci_name": "Allium sativum", "days": 30,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [50, 65], "temp": [15, 25],
        "nutrition": {"kcal": 40, "se": 0.02, "protein": 2.4},
        "desc": "高血压推荐品种, 生长极快",
        "difficulty": 1,
    },
    "shengcai": {
        "name": "快菜", "zhen": "菜真",
        "sci_name": "Brassica rapa", "days": 28,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 13, "se": 0.01, "protein": 1.1},
        "desc": "28天收获, 新手信心之选",
        "difficulty": 1,
    },
    "xihulu": {
        "name": "西葫芦", "zhen": "果真",
        "sci_name": "Cucurbita pepo", "days": 50,
        "light": {"on": 6, "off": 20, "rb": 60},
        "soil_moisture": [55, 70], "temp": [18, 28],
        "nutrition": {"kcal": 18, "se": 0.01, "protein": 0.8},
        "desc": "连续结果型, 单株可收2个月",
        "difficulty": 2,
    },
    "ku_gua": {
        "name": "苦瓜", "zhen": "季子苦",
        "sci_name": "Momordica charantia", "days": 70,
        "light": {"on": 6, "off": 21, "rb": 65},
        "soil_moisture": [55, 70], "temp": [20, 30],
        "nutrition": {"kcal": 17, "se": 0.01, "protein": 1.0},
        "desc": "糖尿病推荐品种, 含苦瓜皂苷",
        "difficulty": 2,
    },
    "shengcai2": {
        "name": "紫叶生菜", "zhen": "季子紫",
        "sci_name": "Lactuca sativa", "days": 40,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 24],
        "nutrition": {"kcal": 15, "se": 0.01, "protein": 1.4},
        "desc": "颜值与营养兼得, 沙拉首选",
        "difficulty": 1,
    },

    # ==================== 慢病方案扩展品种 ====================
    "bocai": {
        "name": "菠菜", "zhen": "菜真",
        "sci_name": "Spinacia oleracea", "days": 40,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 28, "se": 0.01, "protein": 2.6, "k_mg": 558, "mg_mg": 58},
        "desc": "高钾高镁, 高血压与糖尿病方案常用",
        "difficulty": 1,
    },
    "hulu": {
        "name": "瓠瓜", "zhen": "季子绿",
        "sci_name": "Lagenaria siceraria", "days": 55,
        "light": {"on": 6, "off": 20, "rb": 60},
        "soil_moisture": [60, 80], "temp": [18, 28],
        "nutrition": {"kcal": 12, "se": 0.01, "protein": 0.7},
        "desc": "低热量高水分, 利水消肿, 糖尿病方案常用",
        "difficulty": 2,
    },
    "nangua": {
        "name": "贝贝南瓜", "zhen": "季子黄",
        "sci_name": "Cucurbita moschata", "days": 85,
        "light": {"on": 6, "off": 20, "rb": 60},
        "soil_moisture": [55, 70], "temp": [18, 28],
        "nutrition": {"kcal": 45, "se": 0.01, "protein": 1.0},
        "desc": "果胶丰富保护胃黏膜, 胃病调理方案常用",
        "difficulty": 3,
    },
    "qincai": {
        "name": "西芹", "zhen": "水真",
        "sci_name": "Apium graveolens", "days": 60,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [60, 80], "temp": [15, 25],
        "nutrition": {"kcal": 16, "se": 0.01, "protein": 0.7, "k_mg": 260},
        "desc": "芹菜素与苯酞类, 高血压方案核心品种",
        "difficulty": 2,
    },
    "doujiao": {
        "name": "架豆角", "zhen": "子真",
        "sci_name": "Vigna unguiculata", "days": 60,
        "light": {"on": 6, "off": 20, "rb": 60},
        "soil_moisture": [55, 70], "temp": [18, 28],
        "nutrition": {"kcal": 33, "se": 0.01, "protein": 2.7},
        "desc": "可溶性膳食纤维丰富, 高血脂方案常用",
        "difficulty": 2,
    },
    "tonghao": {
        "name": "茼蒿", "zhen": "花真",
        "sci_name": "Glebionis coronaria", "days": 40,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 24, "se": 0.01, "protein": 1.9, "k_mg": 220},
        "desc": "挥发油开胃, 高血脂与胃病方案搭配品种",
        "difficulty": 1,
    },
    "xiaobaicai": {
        "name": "小白菜", "zhen": "菜真",
        "sci_name": "Brassica rapa var. chinensis", "days": 30,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 13, "se": 0.01, "protein": 1.5, "k_mg": 178},
        "desc": "温和低刺激, 胃病调理与新手首选",
        "difficulty": 1,
    },
    "wosun": {
        "name": "莴笋", "zhen": "季子白",
        "sci_name": "Lactuca sativa var. angustana", "days": 50,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 15, "se": 0.01, "protein": 1.0},
        "desc": "菊粉低GI, 糖尿病与睡眠方案搭配品种",
        "difficulty": 2,
    },
    "juhua": {
        "name": "杭白菊", "zhen": "花真",
        "sci_name": "Chrysanthemum morifolium", "days": 90,
        "light": {"on": 6, "off": 20, "rb": 45},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 30, "se": 0.01, "protein": 3.2},
        "desc": "菊苷挥发油, 清肝安神茶饮, 高血压与睡眠方案",
        "difficulty": 2,
    },
    "bohe": {
        "name": "薄荷", "zhen": "调料真",
        "sci_name": "Mentha haplocalyx", "days": 40,
        "light": {"on": 6, "off": 20, "rb": 45},
        "soil_moisture": [55, 70], "temp": [15, 28],
        "nutrition": {"kcal": 44, "se": 0.01, "protein": 3.3},
        "desc": "薄荷醇舒缓, 睡眠方案茶饮与调味",
        "difficulty": 1,
    },
    "luobo": {
        "name": "樱桃萝卜", "zhen": "季子红",
        "sci_name": "Raphanus sativus", "days": 30,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 16, "se": 0.01, "protein": 0.7},
        "desc": "萝卜硫素与维C, 免疫力方案抗氧化核心",
        "difficulty": 1,
    },
    "huluobo": {
        "name": "水果胡萝卜", "zhen": "季子橙",
        "sci_name": "Daucus carota", "days": 70,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 41, "se": 0.01, "protein": 0.9},
        "desc": "β-胡萝卜素修复黏膜, 胃病与免疫方案常用",
        "difficulty": 2,
    },
    "fanqie": {
        "name": "樱桃番茄", "zhen": "果真",
        "sci_name": "Solanum lycopersicum", "days": 70,
        "light": {"on": 6, "off": 20, "rb": 65},
        "soil_moisture": [55, 70], "temp": [18, 28],
        "nutrition": {"kcal": 18, "se": 0.01, "protein": 0.9},
        "desc": "番茄红素抗氧化, 免疫力方案常用",
        "difficulty": 2,
    },
    "hongcaitai": {
        "name": "红菜苔", "zhen": "季子紫",
        "sci_name": "Brassica rapa var. purpuraria", "days": 60,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 20, "se": 0.01, "protein": 1.8},
        "desc": "花青素与维C, 免疫力方案抗氧化搭配",
        "difficulty": 2,
    },
    "ganlan": {
        "name": "甘蓝", "zhen": "菜真",
        "sci_name": "Brassica oleracea", "days": 75,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [55, 70], "temp": [15, 25],
        "nutrition": {"kcal": 25, "se": 0.01, "protein": 1.3},
        "desc": "维生素U样因子, 胃病调理与睡眠搭配",
        "difficulty": 2,
    },
    "mucai": {
        "name": "木耳菜", "zhen": "季子绿",
        "sci_name": "Basella alba", "days": 35,
        "light": {"on": 6, "off": 20, "rb": 50},
        "soil_moisture": [60, 80], "temp": [20, 30],
        "nutrition": {"kcal": 20, "se": 0.01, "protein": 1.6},
        "desc": "黏液蛋白与果胶, 控糖降脂双方案常用",
        "difficulty": 1,
    },
    "yangcong": {
        "name": "紫皮洋葱", "zhen": "调料真",
        "sci_name": "Allium cepa", "days": 110,
        "light": {"on": 6, "off": 20, "rb": 55},
        "soil_moisture": [50, 65], "temp": [15, 25],
        "nutrition": {"kcal": 40, "se": 0.02, "protein": 1.1},
        "desc": "前列腺素A与槲皮素, 高血脂方案(建议社区站)",
        "difficulty": 2,
    },
}

# ==================== 慢病定制化种植方案 ====================
CHRONIC_PLANS = {
    "diabetes": {
        "name": "糖尿病辅助管理",
        "crops": ["ku_gua", "hulu", "wosun", "shengcai", "dasuanmiao"],
        "diet_rules": [
            "低升糖指数优先, 搭配粗粮主食",
            "苦瓜皂苷辅助控糖, 建议每日100g",
            "避免高糖水果与精制碳水",
        ],
        "monitor": ["餐前血糖", "餐后2小时血糖", "糖化血红蛋白(每3月)"],
        "forbidden": ["甘蔗", "龙眼", "荔枝", "榴莲"],
        "disclaimer": "本方案仅为饮食辅助, 不替代降糖药物治疗",
    },
    "hypertension": {
        "name": "高血压辅助管理",
        "crops": ["dasuanmiao", "qincai", "bocai", "xihulu", "huanggua"],
        "diet_rules": [
            "每日钠摄入<5g盐, 香料替代盐调味",
            "大蒜素辅助降压, 生食效果更佳",
            "高钾低钠饮食结构",
        ],
        "monitor": ["晨起血压", "晚间血压", "尿钠(每周)"],
        "forbidden": ["腌制食品", "咸菜", "加工肉类"],
        "disclaimer": "血压异常请遵医嘱用药, 饮食仅作辅助",
    },
    "hyperlipidemia": {
        "name": "高血脂辅助管理",
        "crops": ["pugongying", "mucai", "doujiao", "tonghao"],
        "diet_rules": [
            "控制饱和脂肪, 多用蒸煮凉拌",
            "膳食纤维每日25g以上",
            "蒲公英辅助降脂",
        ],
        "monitor": ["总胆固醇", "低密度脂蛋白", "甘油三酯(每3月)"],
        "forbidden": ["动物内脏", "油炸食品", "奶油"],
        "disclaimer": "他汀类药物不可自行停用",
    },
    "gastritis": {
        "name": "胃病/消化不良调理",
        "crops": ["nangua", "ganlan", "xiaobaicai", "huluobo"],
        "diet_rules": [
            "少食多餐, 温和易消化",
            "南瓜山药养胃, 小米粥最佳主食",
            "避免生冷辛辣刺激性食物",
        ],
        "monitor": ["胃痛频率", "反酸症状", "食欲变化"],
        "forbidden": ["冰镇饮品", "烈酒", "浓咖啡", "朝天椒"],
        "disclaimer": "持续胃痛/黑便请立即就医",
    },
    "insomnia": {
        "name": "睡眠障碍调理",
        "crops": ["juhua", "bohe", "wosun", "shengcai2"],
        "diet_rules": [
            "晚餐清淡少量, 睡前3小时禁食",
            "菊花茶安神, 睡前1小时饮用",
            "避免咖啡因与尼古丁",
        ],
        "monitor": ["入睡时长", "深睡比例", "晨起精神评分"],
        "forbidden": ["咖啡", "浓茶", "巧克力", "能量饮料"],
        "disclaimer": "长期失眠请咨询睡眠专科",
    },
    "immunity": {
        "name": "免疫力提升/抗衰老",
        "crops": ["luobo", "huluobo", "fanqie", "doujiao", "hongcaitai", "pugongying"],
        "diet_rules": [
            "彩虹饮食法, 每日5种颜色蔬果",
            "优质蛋白+维生素协同",
            "补充富硒食材提升抗氧化",
        ],
        "monitor": ["感冒频率", "伤口愈合速度", "疲劳感评分"],
        "forbidden": [],
        "disclaimer": "本方案用于日常保健",
    },
}


def get_crop(crop_id: str):
    return JIu_ZHEN_18_PIN.get(crop_id)


def get_plan(plan_id: str):
    return CHRONIC_PLANS.get(plan_id)


def all_crops():
    return [
        {"id": k, **{kk: vv for kk, vv in v.items() if kk != "desc"}}
        for k, v in JIu_ZHEN_18_PIN.items()
    ]


def crops_by_plan(plan_id: str):
    plan = CHRONIC_PLANS.get(plan_id)
    if not plan:
        return []
    return [JIu_ZHEN_18_PIN[c] for c in plan["crops"] if c in JIu_ZHEN_18_PIN]
