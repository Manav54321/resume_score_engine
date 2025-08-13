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
