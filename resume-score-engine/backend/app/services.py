import os
from langchain_groq import ChatGroq
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
import pypdf
from docx import Document
from typing import Optional

# --- Configuration ---
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
MODEL_NAME = "meta-llama/llama-4-maverick-17b-128e-instruct"

# --- LangChain Setup ---
llm = ChatGroq(
    temperature=0,
    groq_api_key=GROQ_API_KEY,
    model_name=MODEL_NAME,
)

prompt_template = """
You are an expert ATS (Applicant Tracking System) scanner and career coach.
Your task is to provide a highly detailed evaluation of a resume against a job description.

**Resume Text:**
{resume_text}

**Job Title:**
{job_title}

**Job Description:**
{job_description}

**Instructions for your analysis:**

1.  **Score:** Provide a percentage score representing the match.
2.  **Summary:** Provide a detailed, multi-paragraph summary (as detailed as possible). Cover the candidate's strengths, weaknesses, and overall alignment with the role based on the provided documents. Be specific.
3.  **Keywords Match:** Identify all relevant keywords from the job description and indicate their presence in the resume.
4.  **Missing Technical Skills:** Scrutinize the job description and identify **every specific technical skill or technology** mentioned that is **not present** in the resume. This includes programming languages, frameworks (like LangChain, FastAPI), databases (like Vector DBs), libraries, and tools. List all of them.
5.  **Missing Other Skills:** Identify all non-technical skills or qualifications mentioned in the job description that are missing. This includes domain knowledge (e.g., 'experience in finance'), cloud platforms (e.g., 'Azure'), and specific methodologies (e.g., 'Agile').
6.  **Improvements:** Suggest specific, actionable improvements. Instead of generic advice, give concrete examples like, "Rephrase 'worked on project' to 'Led the development of a user authentication module, resulting in a 20% reduction in login errors'."

**IMPORTANT: Your final output must be a single, valid JSON object and nothing else. Do not include any text, explanations, or markdown formatting before or after the JSON object.**

**Output Format (JSON):**
{{
  "score": <percentage_score_as_integer>,
  "summary": "<detailed_summary_text>",
  "keywords_match": {{
    "<keyword1>": <true_or_false>,
    "<keyword2>": <true_or_false>
  }},
  "missing_technical_skills": [
    "<LangChain>",
    "<FastAPI>",
    "<Vector DBs>"
  ],
  "missing_other_skills": [
    "<Experience with Azure>",
    "<Specific industry domain knowledge>"
  ],
  "improvements": [
    "<detailed_suggestion_1>",
    "<detailed_suggestion_2>"
  ]
}}
"""

prompt = ChatPromptTemplate.from_template(prompt_template)
output_parser = StrOutputParser()
chain = prompt | llm | output_parser

# --- Helper Functions ---

def extract_text_from_pdf(file_path: str) -> str:
    with open(file_path, "rb") as f:
        reader = pypdf.PdfReader(f)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""
    return text

def extract_text_from_docx(file_path: str) -> str:
    doc = Document(file_path)
    text = ""
    for para in doc.paragraphs:
        text += para.text + "\n"
    return text

def extract_text_from_file(file_path: str, content_type: str) -> str:
    if content_type == "application/pdf":
        return extract_text_from_pdf(file_path)
    elif content_type in ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"]:
        return extract_text_from_docx(file_path)
    else:
        raise ValueError(f"Unsupported file type: {content_type}")

async def get_ats_score(resume_text: str, job_title: str, job_description: Optional[str]) -> str:
    if not job_description:
        job_description = f"A typical job description for a {job_title} role."

    response = await chain.ainvoke({
        "resume_text": resume_text,
        "job_title": job_title,
        "job_description": job_description,
    })
    return response
