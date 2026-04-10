import json
import os
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="NutriLens API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api_key = os.getenv("GEMINI_API_KEY", "")


class AnalysisResult(BaseModel):
    food_name: str
    calories: int
    protein: int
    carbs: int
    fats: int
    fiber: int
    sugar: int
    verdict: str
    health_score: int


@app.get("/")
def read_root():
    return {"message": "NutriLens API is running"}


@app.post("/analyze-food", response_model=AnalysisResult)
async def analyze_food(image: UploadFile = File(...)):
    """Analyze a food image using Gemini Vision and return nutritional breakdown."""
    contents = await image.read()

    if not api_key:
        # Mock response for development
        return AnalysisResult(
            food_name="Grilled Chicken Salad",
            calories=380,
            protein=35,
            carbs=18,
            fats=12,
            fiber=6,
            sugar=4,
            verdict="Great choice! High protein, low carb meal with plenty of greens.",
            health_score=92,
        )

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=api_key)

        prompt = """You are an expert nutritionist. Analyze this food image.
Identify the food items and estimate the nutritional content.
Return ONLY valid JSON with NO markdown formatting, matching this exact schema:
{
  "food_name": "Name of the dish/food",
  "calories": estimated_calories_integer,
  "protein": grams_integer,
  "carbs": grams_integer,
  "fats": grams_integer,
  "fiber": grams_integer,
  "sugar": grams_integer,
  "verdict": "One sentence health verdict about this meal",
  "health_score": score_0_to_100
}"""

        response = client.models.generate_content(
            model="gemini-2.0-flash",
            contents=[
                prompt,
                types.Part.from_bytes(data=contents, mime_type=image.content_type or "image/jpeg"),
            ],
        )

        response_text = response.text.replace("```json", "").replace("```", "").strip()
        data = json.loads(response_text)
        return AnalysisResult(**data)

    except Exception as e:
        print(f"Gemini error: {e}")
        raise HTTPException(status_code=500, detail=f"AI analysis failed: {str(e)}")
