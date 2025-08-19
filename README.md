# 🔥 Resume Score Engine 🔥

Stop guessing if your resume is good enough. The **Resume Score Engine** uses powerful AI to instantly score your resume against any job description. See your match score, find missing keywords, and get the feedback you need to beat the hiring bots and get noticed.

### [**🚀 Live Demo**](https://resume-score-engine.vercel.app/)

*(It's recommended to replace this with a screenshot of your app!)*

---

## 🛠️ Tech Stack

* **Frontend:** React, TypeScript, Vite, Tailwind CSS
* **Backend:** Python, FastAPI
* **AI / LLM:** LangChain, Groq Cloud (`meta-llama/llama-4-maverick-17b-128e-instruct`)
    * *Note: While the project was initially developed with more powerful models like `gpt-oss-120b`, it now uses the Maverick model to ensure maximum speed and responsiveness.*
* **Deployment:** Vercel (Frontend) & Render (Backend)

---

## 💻 Local Setup

Get this running on your own machine in a few steps.

### **1. Prerequisites**

* [Node.js](https://nodejs.org/en/) (v18 or later)
* [Python](https://www.python.org/downloads/) (v3.9 or later)
* A Groq Cloud API Key

### **2. Clone the Repository**

```bash
git clone [https://github.com/Manav54321/resume_score_engine.git](https://github.com/Manav54321/resume_score_engine.git)
cd resume_score_engine/resume-ats-checker
````

### **3. Backend Setup**

Navigate to the backend folder, create a virtual environment, and install the Python packages.

```bash
# From the resume-ats-checker directory
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### **4. Frontend Setup**

In a new terminal, navigate to the frontend folder and install the Node packages.

```bash
# From the resume-ats-checker directory
cd frontend

# Install dependencies
npm install
```

-----

## 🚀 Running Locally

You need two separate terminals to run the application.

### **Terminal 1: Start the Backend**

```bash
# Make sure you are in the backend directory
cd backend

# (If your venv isn't active)
# source venv/bin/activate

# Set your API key (IMPORTANT for local testing)
export GROQ_API_KEY="YOUR_GROQ_API_KEY_HERE"

# Run the server
uvicorn app.main:app --reload
```

Your backend is now running at `http://localhost:8000`.

### **Terminal 2: Start the Frontend**

```bash
# Make sure you are in the frontend directory
cd frontend

# Run the dev server
npm run dev
```

Your frontend is now live at `http://localhost:5173`. Open this URL in your browser.

-----

## ☁️ Deployment

This project is deployed with a split backend/frontend architecture.

### **Backend (Render)**

1.  Push your code to GitHub.
2.  Create a new **Web Service** on Render and connect your GitHub repo.
3.  Use the following settings:
      * **Root Directory:** `resume-ats-checker/backend`
      * **Build Command:** `pip install -r requirements.txt`
      * **Start Command:** `python run.py`
4.  Go to the **Environment** tab and add your `GROQ_API_KEY`.
5.  In `backend/app/main.py`, add your live Vercel URL to the `origins` list to fix CORS.

### **Frontend (Vercel)**

1.  In `frontend/src/App.tsx`, update the `axios.post` URL to point to your live Render backend URL.
2.  Push the change to GitHub.
3.  Create a new project on Vercel and import your GitHub repo.
4.  Use the following settings:
      * **Framework Preset:** `Vite`
      * **Root Directory:** `resume-ats-checker/frontend`
5.  Deploy\!
