from fastapi import FastAPI, File, UploadFile, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
import os
import json
import logging

from .services import get_ats_score, extract_text_from_file

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Resume ATS Analyzer API")

# CORS Middleware
# IMPORTANT: Add your Vercel URL here after deployment
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "https://resume-score-engine-4ga7wcnuo-manav-desais-projects.vercel.app/", 
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/analyze-resume/")
async def analyze_resume(
    file: UploadFile = File(...),
    job_title: str = Form(...),
    job_description: Optional[str] = Form(None),
):
    temp_dir = "temp_files"
    os.makedirs(temp_dir, exist_ok=True)
    file_path = os.path.join(temp_dir, file.filename)
    
    try:
        with open(file_path, "wb") as buffer:
            buffer.write(await file.read())

        resume_text = extract_text_from_file(file_path, file.content_type)

        logger.info("Requesting ATS score from the model...")
        result_str = await get_ats_score(resume_text, job_title, job_description)
        logger.info(f"Received raw response from model: {result_str}")
        
        try:
            start_index = result_str.find('{')
            end_index = result_str.rfind('}') + 1
            
            if start_index != -1 and end_index != 0:
                json_str = result_str[start_index:end_index]
                result = json.loads(json_str)
                return result
            else:
                raise json.JSONDecodeError("No JSON object found in the response.", result_str, 0)

        except json.JSONDecodeError:
            logger.error(f"Failed to decode JSON from model response: {result_str}")
            raise HTTPException(status_code=500, detail="The AI model returned an invalid format. Please try again.")

    except Exception as e:
        logger.error(f"An unexpected error occurred: {e}")
        if isinstance(e, HTTPException):
            raise e
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(file_path):
            os.remove(file_path)
