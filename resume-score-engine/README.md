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
