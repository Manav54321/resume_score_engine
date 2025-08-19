#!/bin/bash

# This script creates the complete, corrected Resume Score Engine application from scratch.

set -euo pipefail

echo "--- Creating Project Directory: resume-score-engine ---"
mkdir -p resume-score-engine
cd resume-score-engine

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
    "http://192.168.1.18:5173", # Your specific network IP for mobile testing
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

# frontend/package.json - WITH THE CORRECTED BUILD SCRIPT
cat <<'EOF' > frontend/package.json
{
  "name": "frontend",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
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
    "@types/react": "^18.2.66",
    "@types/react-dom": "^18.2.22",
    "@typescript-eslint/eslint-plugin": "^7.2.0",
    "@typescript-eslint/parser": "^7.2.0",
    "@vitejs/plugin-react": "^4.2.1",
    "autoprefixer": "^10.4.19",
    "eslint": "^8.57.0",
    "eslint-plugin-react-hooks": "^4.6.0",
    "eslint-plugin-react-refresh": "^0.4.6",
    "postcss": "^8.4.38",
    "tailwindcss": "^3.4.3",
    "typescript": "^5.2.2",
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
    <title>Resume Score Engine</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  </head>
  <body>
    <div class="background-overlay"></div>
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
    host: true,
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
      colors: {
        'brand-dark': '#111111',
        'brand-light': '#EAEAEA',
        'brand-secondary': '#A1A1A1',
        'brand-border': '#333333',
        'brand-input': '#1C1C1C',
        'brand-card': '#1A1A1A',
        'brand-green-light': '#A7F3D0',
        'brand-green-dark': '#065F46',
        'brand-yellow-light': '#FDE68A',
        'brand-yellow-dark': '#92400E',
        'brand-red-light': '#FECACA',
        'brand-red-dark': '#991B1B',
      }
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

# frontend/src/index.css
cat <<'EOF' > frontend/src/index.css
@tailwind base;
@tailwind components;
@tailwind utilities;

.background-overlay {
    position: fixed;
    inset: 0;
    width: 100%;
    height: 100%;
    background-image: url('https://lovable.dev/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fdark-login-background.d5ea9915.png&w=3840&q=75');
    background-size: cover;
    background-position: center;
    z-index: -1;
    opacity: 0.5;
}
.card {
  background: linear-gradient(180deg, rgba(255,255,255,0.02), rgba(255,255,255,0.01));
  border: 1px solid rgba(255,255,255,0.04);
  backdrop-filter: blur(6px) saturate(120%);
}

.btn {
  @apply inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ease-in-out;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 4px 30px rgba(0, 0, 0, 0.1);
}

.btn-primary {
  @apply text-white;
  background: rgba(255, 107, 107, 0.1);
  border: 1px solid rgba(255, 107, 107, 0.2);
}

.btn:not(:disabled):hover {
  transform: scale(1.03);
  border-color: rgba(255, 255, 255, 0.25);
}

.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.small { font-size: 0.85rem; color: #9aa0a6; }
EOF

# frontend/src/main.tsx
cat <<'EOF' > frontend/src/main.tsx
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

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
      
      const resp = await axios.post("http://192.168.1.18:8000/analyze-resume/", form, { 
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

  return (
    <div className="min-h-screen relative">
      <div className="background-overlay" />
      <div className="max-w-5xl mx-auto px-6 py-14 relative z-10">
        <header className="flex items-center justify-between mb-10">
          <div>
            <div className="text-2xl font-bold">Resume Score Engine</div>
            <div className="small">See how your resume scores against a job description.</div>
          </div>
          <div className="flex items-center gap-3">
            <button className="btn small hidden md:inline-flex" onClick={() => window.location.reload()}>New Analysis</button>
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

        <footer className="text-center small mt-12 text-white/50">Copyright © 2025 Seventeen. All rights reserved. Powered by Groq Cloud and OpenAI and gpt-oss-120b</footer>
      </div>
    </div>
  );
};

export default App;
EOF

# frontend/src/components/FileUpload.tsx, JobDetails.tsx, Results.tsx, Spinner.tsx
# (These files are created below, matching the imports in App.tsx)

mkdir -p frontend/src/components

cat > "frontend/src/components/FileUpload.tsx" <<'TSX'
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

  const { getRootProps, getInputProps, isDragActive } = useDropzone({ onDrop, multiple: false, accept: { "application/pdf": [".pdf"], "application/vnd.openxmlformats-officedocument.wordprocessingml.document": [".docx"], "application/msword": [".doc"] } });

  return (
    <div
      {...getRootProps()}
      className={`p-10 rounded-2xl cursor-pointer transition-all duration-300 bg-white/5 backdrop-blur-lg border border-white/10 hover:border-white/20 hover:bg-white/10 ${isDragActive ? "border-brand-accent" : ""}`}
    >
      <input {...getInputProps()} />
      <div className="text-center">
        <div className="font-semibold text-brand-light">
          {file ? file.name : isDragActive ? "Drop your resume here" : "Upload Resume"}
        </div>
        <div className="small mt-1">
          {file ? "Click or drop another file to replace" : "Drag & drop or click to select a file"}
        </div>
      </div>
    </div>
  );
};
TSX

cat > "frontend/src/components/JobDetails.tsx" <<'TSX'
import React from "react";

interface Props {
  jobTitle: string;
  jobDescription: string;
  setJobTitle: (s: string) => void;
  setJobDescription: (s: string) => void;
}

export const JobDetails: React.FC<Props> = ({ jobTitle, jobDescription, setJobTitle, setJobDescription }) => {
  return (
    <div className="card p-6 rounded-2xl border-gray-800 space-y-4">
      <label className="block">
        <div className="small mb-1">Job Title</div>
        <input value={jobTitle} onChange={(e)=>setJobTitle(e.target.value)} placeholder="e.g. Senior Backend Engineer" className="w-full p-3 rounded-lg bg-transparent border border-white/10 outline-none focus:border-white/30 transition-colors" />
      </label>
      <label className="block">
        <div className="small mb-1">Job Description (Optional)</div>
        <textarea value={jobDescription} onChange={(e)=>setJobDescription(e.target.value)} placeholder="Paste the job description here for a more accurate score." rows={8} className="w-full p-3 rounded-lg bg-transparent border border-white/10 outline-none resize-y focus:border-white/30 transition-colors"></textarea>
      </label>
    </div>
  );
};
TSX

cat > "frontend/src/components/Results.tsx" <<'TSX'
import React from "react";

interface Props { data: any; }

export const Results: React.FC<Props> = ({ data }) => {
  if (!data) return null;

  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-green-400';
    if (score >= 60) return 'text-yellow-400';
    return 'text-red-400';
  };

  return (
    <div className="card p-6 rounded-2xl border-gray-800 space-y-5 h-full overflow-y-auto">
      <div className="text-center">
        <div className="small">Overall Match Score</div>
        <div className={`text-6xl font-bold mt-1 ${getScoreColor(data.score)}`}>{data.score}%</div>
      </div>

      <div className="border-t border-white/10 pt-4">
        <h4 className="font-semibold mb-2">Summary</h4>
        <p className="small leading-relaxed whitespace-pre-wrap">{data.summary}</p>
      </div>

      {data.keywords_match && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Keyword Analysis</h4>
          <div className="flex flex-wrap gap-2">
            {Object.entries(data.keywords_match).map(([key, val]) => (
              <span key={key} className={`px-2 py-1 text-xs rounded ${val ? 'bg-green-500/20 text-green-300' : 'bg-red-500/20 text-red-300'}`}>{key}</span>
            ))}
          </div>
        </div>
      )}

      {data.missing_technical_skills?.length > 0 && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Missing Technical Skills</h4>
          <div className="flex flex-wrap gap-2">
            {data.missing_technical_skills.map((skill:string, i:number) => (
              <span key={i} className="px-2 py-1 text-xs rounded bg-yellow-500/20 text-yellow-300">{skill}</span>
            ))}
          </div>
        </div>
      )}
      
      {data.missing_other_skills?.length > 0 && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Missing Other Skills</h4>
          <div className="flex flex-wrap gap-2">
            {data.missing_other_skills.map((skill:string, i:number) => (
              <span key={i} className="px-2 py-1 text-xs rounded bg-gray-500/20 text-gray-300">{skill}</span>
            ))}
          </div>
        </div>
      )}

      {data.improvements && (
        <div className="border-t border-white/10 pt-4">
          <h4 className="font-semibold mb-2">Suggested Improvements</h4>
          <ul className="list-disc list-inside mt-2 small space-y-1">
            {data.improvements.map((it:string, i:number)=> <li key={i}>{it}</li>)}
          </ul>
        </div>
      )}
    </div>
  );
};
TSX

cat > "frontend/src/components/Spinner.tsx" <<'TSX'
import React from "react";

export const Spinner: React.FC = () => (
    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mx-auto"></div>
);
TSX

# --- README ---
cat <<'EOF' > README.md
# Resume Score Engine

A sleek, modern, and fast resume analyzer that scores your resume against a job description using the power of AI.

## Tech Stack

-   **Frontend:** React, TypeScript, Tailwind CSS, Vite
-   **Backend:** FastAPI, Python
-   **AI/LLM:** LangChain, Groq (with meta-llama/llama-4-maverick-17b-128e-instruct)

## Getting Started

### Prerequisites

-   Node.js and npm (or yarn)
-   Python 3.8+ and pip
-   Your Groq API Key

### Installation

1.  **Run the `setup_project.sh` script** in your desired directory.
2.  **Navigate to the project root:** `cd resume-score-engine`
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
    - Navigate to `resume-score-engine/backend`.
    - Activate the virtual environment: `source venv/bin/activate`
    - Run: `uvicorn app.main:app --reload`
    - The backend will run on `http://127.0.0.1:8000`.

2.  **Start the frontend server:**
    - Open a **new, separate** terminal.
    - Navigate to `resume-score-engine/frontend`.
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
echo "1. cd resume-score-engine"
echo "2. Follow the instructions in the README.md to install dependencies and run the servers."
echo ""
