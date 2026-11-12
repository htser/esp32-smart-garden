"""
慢病推荐引擎 - 规则引擎 + 营养计算
基于用户健康档案匹配种植方案, 输出种植组合与饮食建议
"""


class HealthRecommender:
    def __init__(self):
        from .crop_catalog import CHRONIC_PLANS, JIu_ZHEN_18_PIN
        from .chronic_plans_v2 import TieredRecommender
        self.plans = CHRONIC_PLANS
        self.crops = JIu_ZHEN_18_PIN
        self.tiered = TieredRecommender()

    def bmi(self, profile: dict) -> float:
        h = profile.get("height_cm", 170) / 100
        w = profile.get("weight_kg", 65)
        return round(w / (h * h), 1) if h > 0 else 0

    def recommend_crops(self, profile: dict) -> dict:
        """输入健康档案 -> 推荐品种组合 + 光照/湿度参数"""
        conditions = profile.get("conditions", [])
        recommended_ids = []
        matched_plans = []

        for cond in conditions:
            plan = self.plans.get(cond)
            if not plan:
                continue
            matched_plans.append({"id": cond, "name": plan["name"]})
            recommended_ids.extend(plan["crops"])

        # 无慢病 -> 通用养生组合
        if not recommended_ids:
            recommended_ids = ["shengcai", "xihulu", "pugongying", "huanggua", "dasuanmiao"]
            matched_plans.append({"id": "general", "name": "通用养生组合"})

        # 去重保序
        seen, ordered = set(), []
        for cid in recommended_ids:
            if cid not in seen:
                seen.add(cid)
                ordered.append(cid)

        crops_detail = [
            {"id": cid, **{k: v for k, v in self.crops[cid].items() if k != "desc"}}
            for cid in ordered if cid in self.crops
        ]

        # V2 分层引擎: 检查指标 -> 病情分层 -> 专业种植方案
        tiered = self.tiered.recommend(profile)

        return {
            "bmi": self.bmi(profile),
            "bmi_status": self._bmi_status(self.bmi(profile)),
            "matched_plans": matched_plans,
            "recommended_crops": crops_detail,
            "daily_nutrition_target": self._nutrition_target(profile),
            "tips": self._tips(profile),
            "tiered_plan": tiered,
            "slot_plan": tiered["merged_plan"],
        }

    def generate_advice(self, context: dict) -> dict:
        """每日健康建议 - 结合种植状态"""
        profile = context.get("profile", {})
        crop_id = context.get("current_crop")
        plant_day = context.get("plant_day", 0)

        advice = {
            "diet": [],
            "activity": [],
            "lifestyle": [],
            "plant_tip": None,
        }

        # 饮食建议
        conditions = profile.get("conditions", [])
        for cond in conditions:
            plan = self.plans.get(cond)
            if plan:
                advice["diet"].extend(plan["diet_rules"][:2])
        if not advice["diet"]:
            advice["diet"] = ["每日保证300-500g蔬菜摄入", "彩虹饮食, 5种颜色以上"]

        # 运动建议
        bmi = self.bmi(profile)
        if bmi > 28:
            advice["activity"].append("每日30分钟中等强度运动, 如快走/游泳")
        elif bmi > 24:
            advice["activity"].append("每日20分钟运动, 维持体重")
        else:
            advice["activity"].append("每日15分钟轻度活动, 保持活力")

        # 生活方式
        advice["lifestyle"].append("保证7-8小时睡眠, 固定作息")
        if "hypertension" in conditions:
            advice["lifestyle"].append("晨起静坐5分钟再测量血压")

        # 种植提示
        if crop_id and crop_id in self.crops:
            crop = self.crops[crop_id]
            days_left = max(crop["days"] - plant_day, 0)
            advice["plant_tip"] = (
                f"您的「{crop['name']}」已种植{plant_day}天, "
                f"预计还有{days_left}天收获, "
                f"当前阶段保持土壤湿度在{crop['soil_moisture'][0]}-{crop['soil_moisture'][1]}%"
            )
        else:
            advice["plant_tip"] = "选择适合您的种植品种开始健康之旅"

        return advice

    def _bmi_status(self, bmi: float) -> str:
        if bmi < 18.5: return "偏瘦"
        if bmi < 24:   return "正常"
        if bmi < 28:   return "超重"
        return "肥胖"

    def _nutrition_target(self, profile: dict) -> dict:
        w = profile.get("weight_kg", 65)
        age = profile.get("age", 30)
        # 简化 Mifflin-St Jeor (性别未知取中间值)
        bmr = 10 * w + 6.25 * profile.get("height_cm", 170) - 5 * age - 78
        tdee = round(bmr * 1.4)
        return {
            "kcal": tdee,
            "protein_g": round(w * 1.2, 1),
            "fiber_g": 25,
            "se_ug": 60,
            "water_ml": round(w * 35),
        }

    def _tips(self, profile: dict) -> list[str]:
        tips = []
        conditions = profile.get("conditions", [])
        if "diabetes" in conditions:
            tips.append("苦瓜/瓠瓜汁可在餐前饮用, 辅助平稳血糖")
        if "hypertension" in conditions:
            tips.append("大蒜苗切碎静置10分钟再生食, 大蒜素更充分")
        if "hyperlipidemia" in conditions:
            tips.append("蒲公英嫩叶凉拌, 每周3次辅助降脂")
        if not tips:
            tips.append("坚持每日采摘新鲜蔬菜, 营养最大化")
        return tips
