import json
import random
from google.cloud import bigquery

client = bigquery.Client(project="northeastgroup4t")

# ── Configuration ───────────────────────────────────────────────────
DOMAINS = ["nutrition", "obesity", "sleep", "depression",
           "wellness", "anti_stress", "anti_smoke", "movement"]

FEATURE_NAMES = [
    "dif_nutrition_mid", "dif_obesity_mid", "dif_sleep_mid",
    "dif_depression_mid", "dif_wellness_mid", "dif_anti_stress_mid",
    "dif_anti_smoke_mid", "dif_movement_mid",
    "c_val_nutrition_mid", "c_val_obesity_mid", "c_val_sleep_mid",
    "c_val_depression_mid", "c_val_wellness_mid", "c_val_anti_stress_mid",
    "c_val_anti_smoke_mid", "c_val_movement_mid",
]

MODEL_NAMES = [
    "model_anti_smoke_state", "model_anti_smoke_tips",
    "model_anti_stress_state", "model_anti_stress_tips",
    "model_depression_state", "model_depression_tips",
    "model_dont_spend_too_much", "model_movement_state",
    "model_movement_tips", "model_nutrition_state",
    "model_nutrition_tips", "model_obesity_state",
    "model_obesity_tips", "model_set_attainable_goals",
    "model_sleep_state", "model_sleep_tips",
    "model_wellness_state", "model_wellness_tips",
]

REC = {
    1:  "Set attainable goals and reward yourself when you achieve them",
    2:  "Tell your family and friends that you plan to quit smoking. They can keep you accountable",
    3:  "Avoid harmful behaviors, such as smoking and excessive drinking",
    4:  "Do things that make you happy",
    5:  "Avoid who stress you out: If someone is constantly causing stress in your life and you cannot break the relationship, limit the time you spend with it, or break the relationship completely if possible",
    6:  "Get a journal and write your thoughts out",
    7:  "When facing great challenges, try to look at them as opportunities for personal growth",
    8:  "Anticipate and plan for the challenges that may arise",
    9:  "Take a post-meal walk",
    10: "If you're lacking certain nutrients, take supplements",
    11: "Share your feelings with a trusted friend in person or talk to a psychologist",
    12: "Change your mindset. Try to look at problems from a positive perspective. For example, when you are stuck in traffic, look at it as an opportunity to pause and listen to your favorite radio station",
    13: "Drink plenty of water",
    14: "Read about the harmful effects of smoking on the human body",
    15: "Restrict the intake of sugars-sweetened soft drinks",
    16: "Making a schedule and following it can help you feel less overwhelmed",
    17: "Get at least seven hours of sleep per night",
    18: "Develop habits, or a regular schedule",
    19: "Chew gum or eat mints when you feel the urge to smoke",
    20: "You must engage in at least 30 minutes of moderate physical activity such as brisk walking or aerobic exercise every day",
    21: "Play a sport you enjoy or go for a walk or run",
    22: "Keep your hands busy with a pen or toothpick",
    23: "Refrain from using electronics or looking at bright lights at least an hour before you sleep",
    24: "Eat a balanced meal. It should be composed of 25% proteins, 25% carbohydrates and 50% vegetables",
    25: "Realize that your situation is temporary and time will eventually heal your situation",
    26: "Try to exercise at least 3 times a week",
    27: "Learn to say no",
    28: "Increase your intake of NSP (dietary fibre) as it will promote weight loss",
    29: "Don't spend too much time in one place, take breaks often to walk around or stretch",
    30: "Try to increase the consumption of fruits, vegetables, and fish, and adjust the types of fats and oils consumed, as well as the amount of sugars and starch in the diet",
    31: "Pick up a nice plushy to help you sleep",
    32: "Increasing levels of physical activity: engaging in one hour of moderate physical activity per day (ex. walking)",
    33: "Try to pick up some hobbies that make you happy",
}

TIPS_RECS = {
    "model_nutrition_tips":   [REC[10], REC[24], REC[30]],
    "model_obesity_tips":     [REC[15], REC[28], REC[32]],
    "model_sleep_tips":       [REC[17], REC[23], REC[31]],
    "model_depression_tips":  [REC[11], REC[18], REC[25], REC[33], REC[6]],
    "model_wellness_tips":    [REC[12], REC[13], REC[4]],
    "model_anti_stress_tips": [REC[16], REC[26], REC[27], REC[5], REC[7]],
    "model_anti_smoke_tips":  [REC[14], REC[19], REC[2], REC[22], REC[3], REC[8]],
    "model_movement_tips":    [REC[20], REC[21], REC[9]],
}

TYPE_C_RECS = {
    "model_set_attainable_goals": REC[1],
    "model_dont_spend_too_much":  REC[29],
}

DIMENSION_DISPLAY = {
    "anti_smoke":  "Anti-Smoke",
    "anti_stress": "Anti-Stress",
    "depression":  "Depression",
    "movement":    "Movement",
    "nutrition":   "Nutrition",
    "obesity":     "Obesity",
    "sleep":       "Sleep",
    "wellness":    "Wellness",
}

# ── Preprocessing ───────────────────────────────────────────────────
def dif_to_mid(val):
    if val >= 250:    return 625.0
    elif val >= 0:    return 125.0
    elif val >= -250: return -125.0
    else:             return -625.0

def c_val_to_mid(val):
    if val < 400:    return 200.0
    elif val <= 600: return 500.0
    else:            return 800.0

def preprocess(raw):
    mid_dict = {}
    for domain in DOMAINS:
        mid_dict[f"dif_{domain}_mid"]   = dif_to_mid(raw[f"dif_{domain}"])
        mid_dict[f"c_val_{domain}_mid"] = c_val_to_mid(raw[f"c_val_{domain}"])
    return {f: mid_dict[f] for f in FEATURE_NAMES}

# ── Inference ───────────────────────────────────────────────────────
def build_query(model_name, features):
    col_defs = ", ".join([f"{v} AS {k}" for k, v in features.items()])
    return f"""
    SELECT * FROM ML.PREDICT(
        MODEL `northeastgroup4t.health_models.{model_name}`,
        (SELECT {col_defs})
    )
    """

def run_inference(features):
    results = {}
    for model_name in MODEL_NAMES:
        df = client.query(build_query(model_name, features)).to_dataframe()
        predicted_col = [c for c in df.columns if c.startswith("predicted_")][0]
        results[model_name] = df[predicted_col].iloc[0]
    return results

# ── Decoding ────────────────────────────────────────────────────────
def english_list(items):
    if not items:       return ""
    if len(items) == 1: return items[0]
    return ", ".join(items[:-1]) + " and " + items[-1]

def build_status_assessment(results):
    imp_dims, acc_dims = [], []
    for domain, display in DIMENSION_DISPLAY.items():
        state = results.get(f"model_{domain}_state")
        if state == "imp":   imp_dims.append(display)
        elif state == "acc": acc_dims.append(display)
    parts = []
    if imp_dims:
        parts.append(f"You need to start improving with respect to your {english_list(imp_dims)}.")
    if acc_dims:
        parts.append(f"In the long term, you may still be at the risk of {english_list(acc_dims)}.")
    if not parts:
        return "Great job! All your health dimensions are currently on track."
    return "Be careful! " + " ".join(parts)

def build_recommendations(results):
    selected = []
    for model_name, rec_pool in TIPS_RECS.items():
        if str(results.get(model_name)) == "1":
            selected.extend(random.sample(rec_pool, min(2, len(rec_pool))))
    for model_name, sentence in TYPE_C_RECS.items():
        if str(results.get(model_name)) == "1":
            selected.append(sentence)
    if not selected:
        return "Keep up the great work!"
    return ". ".join(selected) + "."

# ── Main ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    # Load input
    with open("input.json", "r") as f:
        raw = json.load(f)

    user_id = raw.get("id")

    # Run pipeline
    features  = preprocess(raw)
    results   = run_inference(features)
    status    = build_status_assessment(results)
    recommend = build_recommendations(results)

    # Build output (preserves original input alongside predictions)
    output = {
        "id": user_id,
        "input": raw,
        "status_assessment": status,
        "recommendations": recommend
    }

    # Write output
    with open("output.json", "w") as f:
        json.dump(output, f, indent=2)

    print("Done. Results written to output.json")
    print(json.dumps(output, indent=2))