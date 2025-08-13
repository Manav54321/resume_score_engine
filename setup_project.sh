#!/bin/bash

# --- Start of Project Setup ---

echo "--- Creating Project Directory: resume-ats-checker ---"
mkdir -p resume-ats-checker
cd resume-ats-checker

# --- Backend Setup (FastAPI) ---
echo "--- Setting up Backend ---"
mkdir -p backend/app
touch backend/app/__init__.py

# backend/app/main.py
cat <<'EOF' > backend/app/main.py
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
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
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
    """
    Analyzes a resume against a job description and returns an ATS score.
    """
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
            # Find the start and end of the JSON object in the response string
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
EOF

# backend/app/services.py
cat <<'EOF' > backend/app/services.py
import os
from langchain_groq import ChatGroq
from langchain.prompts import ChatPromptTemplate
from langchain.schema.output_parser import StrOutputParser
import pypdf
from docx import Document
from typing import Optional

# --- Configuration ---
# IMPORTANT: It's better to use environment variables for API keys in production
GROQ_API_KEY = "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"
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
2.  **Summary:** Provide a detailed, multi-paragraph summary. Cover the candidate's strengths, weaknesses, and overall alignment with the role based on the provided documents. Be specific.
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
    """Extracts text from a PDF file."""
    with open(file_path, "rb") as f:
        reader = pypdf.PdfReader(f)
        text = ""
        for page in reader.pages:
            text += page.extract_text() or ""
    return text

def extract_text_from_docx(file_path: str) -> str:
    """Extracts text from a .docx file."""
    doc = Document(file_path)
    text = ""
    for para in doc.paragraphs:
        text += para.text + "\n"
    return text

def extract_text_from_file(file_path: str, content_type: str) -> str:
    """Extracts text from a file based on its content type."""
    if content_type == "application/pdf":
        return extract_text_from_pdf(file_path)
    elif content_type in ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", "application/msword"]:
        return extract_text_from_docx(file_path)
    else:
        raise ValueError(f"Unsupported file type: {content_type}")

async def get_ats_score(resume_text: str, job_title: str, job_description: Optional[str]) -> str:
    """
    Gets the ATS score and feedback from the LangChain service.
    """
    if not job_description:
        job_description = f"A typical job description for a {job_title} role."

    response = await chain.ainvoke({
        "resume_text": resume_text,
        "job_title": job_title,
        "job_description": job_description,
    })
    return response
EOF

# backend/requirements.txt
cat <<EOF > backend/requirements.txt
fastapi
uvicorn
python-multipart
langchain
langchain-groq
pypdf
python-docx
EOF

# --- Frontend Setup (React with Vite) ---
echo "--- Setting up Frontend ---"
mkdir -p frontend/public frontend/src/components

# frontend/package.json
cat <<'EOF' > frontend/package.json
{
  "name": "frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "dependencies": {
    "axios": "^1.7.2",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-dropzone": "^14.2.3"
  },
  "devDependencies": {
    "@types/react": "^18.2.15",
    "@types/react-dom": "^18.2.7",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "@vitejs/plugin-react": "^4.0.3",
    "autoprefixer": "^10.4.19",
    "eslint": "^8.45.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.3",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.0.2",
    "vite": "^5.2.0"
  }
}
EOF

# frontend/index.html
cat <<'EOF' > frontend/index.html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>ResuMate ATS Analyzer</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
  </head>
  <body class="antialiased">
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

# frontend/vite.config.ts
cat <<'EOF' > frontend/vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // This makes it accessible on the network
    port: 5173
  }
})
EOF

# frontend/tsconfig.json
cat <<'EOF' > frontend/tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
EOF

# frontend/tsconfig.node.json
cat <<'EOF' > frontend/tsconfig.node.json
{
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true
  },
  "include": ["vite.config.ts"]
}
EOF

# frontend/tailwind.config.js
cat <<'EOF' > frontend/tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
EOF

# frontend/postcss.config.js
cat <<'EOF' > frontend/postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

# frontend/src/main.tsx
cat <<'EOF' > frontend/src/main.tsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# frontend/src/index.css
cat <<'CSS' > frontend/src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root{
  --bg:#070707;
  --card:#0e0e10;
  --muted:#9aa0a6;
  --accent:#ff6b6b;
}

body{
  font-family: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
  background: radial-gradient(1200px 600px at 10% 10%, rgba(255,255,255,0.02), transparent),
              radial-gradient(800px 400px at 90% 90%, rgba(255,255,255,0.01), transparent),
              var(--bg);
  color: #e6eef3;
  -webkit-font-smoothing:antialiased;
}

.grain-overlay{
  position:fixed;
  inset:0;
  pointer-events:none;
  background-image: url("data:image/svg+xml;utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1600' height='900'%3E%3Cfilter id='g'%3E%3CfeTurbulence baseFrequency='0.8' numOctaves='1' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%' height='100%' filter='url(%23g)' opacity='0.02'/%3E%3C/svg%3E");
  mix-blend-mode:overlay;
  z-index:0;
}

.card {
  background: linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0.01));
  border: 1px solid rgba(255,255,255,0.04);
  backdrop-filter: blur(6px) saturate(120%);
}

.btn {
  @apply inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-transform duration-200 ease-in-out;
  background: linear-gradient(90deg, rgba(255,255,255,0.02), rgba(255,255,255,0.01));
  border: 1px solid rgba(255,255,255,0.06);
}
.btn-primary {
  color: white;
  background: linear-gradient(90deg, rgba(255,107,107,0.16), rgba(255,107,107,0.08));
  border: 1px solid rgba(255,107,107,0.18);
}
.btn:not(:disabled):hover {
    transform: scale(1.03);
}
.btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.mono { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, "Roboto Mono", monospace; }
.small { font-size: 0.85rem; color: var(--muted); }
CSS

# frontend/src/App.tsx
cat <<'EOF' > frontend/src/App.tsx
import React, { useState } from "react";
import axios from "axios";
import { FileUpload } from "./components/FileUpload";
import { JobDetails } from "./components/JobDetails";
import { Results } from "./components/Results";
import { Spinner } from "./components/Spinner";

const App: React.FC = () => {
  const [file, setFile] = useState<File | null>(null);
  const [jobTitle, setJobTitle] = useState("");
  const [jobDescription, setJobDescription] = useState("");
  const [results, setResults] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    setError(null);
    if (!file || !jobTitle) { 
      setError("Please upload a resume and provide a job title."); 
      return; 
    }
    setLoading(true);
    setResults(null);
    try {
      const form = new FormData();
      form.append("file", file);
      form.append("job_title", jobTitle);
      form.append("job_description", jobDescription);
      
      const resp = await axios.post("http://localhost:8000/analyze-resume/", form, { 
        headers: { "Content-Type": "multipart/form-data" } 
      });
      setResults(resp.data);
    } catch (err:any) {
      console.error(err);
      setError(err?.response?.data?.detail || err.message || "An unknown error occurred.");
    } finally {
      setLoading(false);
    }
  };

  const handleReset = () => {
    setFile(null);
    setJobTitle("");
    setJobDescription("");
    setResults(null);
    setError(null);
  }

  return (
    <div className="min-h-screen relative">
      <div className="grain-overlay"></div>
      <div className="max-w-5xl mx-auto px-6 py-14 relative z-10">
        <header className="flex items-center justify-between mb-10">
          <div>
            <div className="text-2xl font-bold">ResuMate</div>
            <div className="small">ATS score & suggestions — powered by Maverick.</div>
          </div>
          <div className="flex items-center gap-3">
            <button className="btn small" onClick={handleReset}>New Analysis</button>
          </div>
        </header>

        <main className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="flex flex-col gap-4">
            <FileUpload setFile={setFile} file={file} />
            <JobDetails 
              jobTitle={jobTitle} 
              jobDescription={jobDescription} 
              setJobTitle={setJobTitle} 
              setJobDescription={setJobDescription} 
            />
            <div className="flex items-center gap-3 mt-2">
              <button onClick={handleSubmit} disabled={loading || !file || !jobTitle} className="btn btn-primary flex-grow">
                {loading ? <Spinner /> : 'Analyze'}
              </button>
            </div>
            {error && <div className="mt-2 text-red-400 small text-center">{error}</div>}
          </div>

          <aside>
            {loading && (
              <div className="card p-6 rounded-2xl h-full flex flex-col items-center justify-center">
                <Spinner />
                <p className="small mt-4">Analyzing your resume...</p>
              </div>
            )}
            {results && !loading && <Results data={results} />}
            {!results && !loading && (
              <div className="card p-6 rounded-2xl border-gray-800 h-full">
                <div className="text-lg font-semibold">Your results will appear here</div>
                <div className="small mt-2">Upload your resume, add a job title, and click 'Analyze' to see your ATS match score, keyword analysis, and suggested improvements.</div>
              </div>
            )}
          </aside>
        </main>

        <footer className="text-center small mt-12 text-white/50">© 2024 ResuMate. All rights reserved.</footer>
      </div>
    </div>
  );
};

export default App;
EOF

# src/components/FileUpload.tsx
cat <<'EOF' > frontend/src/components/FileUpload.tsx
import React, { useCallback } from "react";
import { useDropzone } from "react-dropzone";

interface FileUploadProps {
  setFile: (f: File | null) => void;
  file: File | null;
}

export const FileUpload: React.FC<FileUploadProps> = ({ setFile, file }) => {
  const onDrop = useCallback((acceptedFiles: File[]) => {
    if (acceptedFiles.length > 0) setFile(acceptedFiles[0]);
  }, [setFile]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({ 
    onDrop, 
    multiple: false, 
    accept: { 
      "application/pdf": [".pdf"], 
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document": [".docx"],
      "application/msword": [".doc"]
    } 
  });

  return (
    <div {...getRootProps()} className="card p-6 rounded-2xl cursor-pointer transition-all duration-200 hover:border-white/10">
      <input {...getInputProps()} />
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 rounded-lg bg-white/5 flex items-center justify-center mono text-2xl">
          {file ? "📄" : "📤"}
        </div>
        <div>
          <div className="text-lg font-semibold">{file ? file.name : (isDragActive ? "Drop to upload" : "Upload Resume")}</div>
          <div className="small mt-1">Supports PDF & DOCX. Drag & drop or click.</div>
        </div>
      </div>
    </div>
  );
};
EOF

# src/components/JobDetails.tsx
cat <<'EOF' > frontend/src/components/JobDetails.tsx
import React from "react";

interface Props {
  jobTitle: string;
  jobDescription: string;
  setJobTitle: (s: string) => void;
  setJobDescription: (s: string) => void;
}

export const JobDetails: React.FC<Props> = ({ jobTitle, jobDescription, setJobTitle, setJobDescription }) => {
  return (
    <div className="card p-6 rounded-2xl flex-grow">
      <label className="block mb-3">
        <div className="small mb-1 font-semibold">Job Title</div>
        <input value={jobTitle} onChange={(e)=>setJobTitle(e.target.value)} placeholder="e.g. Senior Backend Engineer" className="w-full p-3 rounded-lg bg-transparent border border-white/10 outline-none focus:border-white/30 transition-colors" />
      </label>
      <label className="block">
        <div className="small mb-1 font-semibold">Job Description (Optional)</div>
        <textarea value={jobDescription} onChange={(e)=>setJobDescription(e.target.value)} placeholder="Paste the job description here for a more accurate analysis." rows={8} className="w-full p-3 rounded-lg bg-transparent border border-white/10 outline-none resize-y focus:border-white/30 transition-colors"></textarea>
      </label>
    </div>
  );
};
EOF

# src/components/Results.tsx
cat <<'EOF' > frontend/src/components/Results.tsx
import React from "react";

interface ResultsProps {
    data: {
        score: number;
        summary: string;
        keywords_match: Record<string, boolean>;
        missing_technical_skills: string[];
        missing_other_skills: string[];
        improvements: string[];
    };
}

export const Results: React.FC<ResultsProps> = ({ data }) => {
  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-green-400';
    if (score >= 60) return 'text-yellow-400';
    return 'text-red-400';
  };

  return (
    <div className="card p-6 rounded-2xl space-y-5 h-full">
      <div className="text-center">
        <div className="small">Overall Match Score</div>
        <div className={`text-7xl font-bold ${getScoreColor(data.score)}`}>{data.score}<span className="text-4xl">%</span></div>
      </div>

      <div className="border-t border-white/10 pt-4">
        <h4 className="font-semibold mb-2">Summary</h4>
        <p className="small leading-relaxed">{data.summary}</p>
      </div>
      
      <div className="border-t border-white/10 pt-4">
        <h4 className="font-semibold mb-2">Keyword Analysis</h4>
        <div className="flex flex-wrap gap-2">
          {Object.entries(data.keywords_match).map(([keyword, matched]) => (
            <span key={keyword} className={`text-xs px-2 py-1 rounded ${matched ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'}`}>{keyword}</span>
          ))}
        </div>
      </div>

      {data.missing_technical_skills?.length > 0 && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Missing Technical Skills</h4>
          <div className="flex flex-wrap gap-2">
            {data.missing_technical_skills.map((skill, i) => (
              <span key={i} className="text-xs px-2 py-1 rounded bg-yellow-500/20 text-yellow-300">{skill}</span>
            ))}
          </div>
        </div>
      )}

      {data.missing_other_skills?.length > 0 && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Missing Domain & Other Skills</h4>
          <div className="flex flex-wrap gap-2">
            {data.missing_other_skills.map((skill, i) => (
              <span key={i} className="text-xs px-2 py-1 rounded bg-gray-700 text-gray-300">{skill}</span>
            ))}
          </div>
        </div>
      )}

      <div className="border-t border-white/10 pt-4">
        <h4 className="font-semibold mb-2">Suggested Improvements</h4>
        <ul className="list-disc list-inside mt-2 small space-y-1">
          {data.improvements.map((it:string, i:number)=> <li key={i}>{it}</li>)}
        </ul>
      </div>
    </div>
  );
};
EOF

# src/components/Spinner.tsx
cat <<'EOF' > frontend/src/components/Spinner.tsx
import React from "react";

export const Spinner: React.FC = () => (
  <div className="w-5 h-5 rounded-full border-t-2 border-b-2 border-black animate-spin" />
);
EOF


cd ..

# --- README ---
cat <<'EOF' > README.md
# ResuMate: ATS Score Calculator

This project is a full-stack application that allows users to upload their resume and get a detailed ATS (Applicant Tracking System) score and analysis against a job description.

## Tech Stack

-   **Frontend:** React, TypeScript, Tailwind CSS, Axios, Vite
-   **Backend:** FastAPI, Python
-   **AI/LLM:** LangChain, Groq (with Llama 4 Maverick)

## Getting Started

### Prerequisites

-   Node.js and npm (or yarn)
-   Python 3.8+ and pip
-   A Groq API Key

### Installation

1.  **Run the setup script** (if you have it) or clone the repository.
2.  **Navigate to the project root:** `cd resume-ats-checker`
3.  **Install backend dependencies:**
    ```bash
    cd backend
    python3 -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    pip install -r requirements.txt
    cd ..
    ```
4.  **Install frontend dependencies:**
    ```bash
    cd frontend
    npm install
    cd ..
    ```

### Running the Application

1.  **Start the backend server:**
    - Open a terminal.
    - Navigate to `resume-ats-checker/backend`.
    - Activate the virtual environment: `source venv/bin/activate`
    - Run: `uvicorn app.main:app --reload`
    - The backend will run on `http://127.0.0.1:8000`.

2.  **Start the frontend server:**
    - Open a **new, separate** terminal.
    - Navigate to `resume-ats-checker/frontend`.
    - Run: `npm run dev`
    - The frontend will run on `http://localhost:5173`.

3.  **Open your browser** and navigate to `http://localhost:5173` to use the application.
EOF

echo ""
echo "--------------------------------------------------"
echo "✅ Project setup complete!"
echo "--------------------------------------------------"
echo ""
echo "To run your application:"
echo "1. cd resume-ats-checker"
echo "2. Follow the instructions in the README.md to install dependencies and run the servers."
echo ""
