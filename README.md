🔥 Resume Score Engine 🔥A badass, AI-powered ATS analyzer that scores your resume against a job description in seconds. Get the feedback you need to beat the bots and land the interview.🚀 Live Demo(Replace this with a screenshot of your app!)🛠️ Tech StackFrontend: React, TypeScript, Vite, Tailwind CSSBackend: Python, FastAPIAI / LLM: LangChain, Groq Cloud (meta-llama/llama-4-maverick-17b-128e-instruct)Note: While the project was initially developed with more powerful models like gpt-oss-120b, it now uses the Maverick model to ensure maximum speed and responsiveness.Deployment: Vercel (Frontend) & Render (Backend)本地设置 (Local Setup)Get this running on your own machine in a few steps.1. PrerequisitesNode.js (v18 or later)Python (v3.9 or later)A Groq Cloud API Key2. Clone the Repositorygit clone https://github.com/Manav54321/resume_score_engine.git
cd resume_score_engine/resume-ats-checker
3. Backend SetupNavigate to the backend folder, create a virtual environment, and install the Python packages.# From the resume-ats-checker directory
cd backend

# Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
4. Frontend SetupIn a new terminal, navigate to the frontend folder and install the Node packages.# From the resume-ats-checker directory
cd frontend

# Install dependencies
npm install
🚀 Running LocallyYou need two separate terminals to run the application.Terminal 1: Start the Backend# Make sure you are in the backend directory
cd backend

# (If your venv isn't active)
# source venv/bin/activate

# Set your API key (IMPORTANT for local testing)
export GROQ_API_KEY="YOUR_GROQ_API_KEY_HERE"

# Run the server
uvicorn app.main:app --reload
Your backend is now running at http://localhost:8000.Terminal 2: Start the Frontend# Make sure you are in the frontend directory
cd frontend

# Run the dev server
npm run dev
Your frontend is now live at http://localhost:5173. Open this URL in your browser.☁️ DeploymentThis project is deployed with a split backend/frontend architecture.Backend (Render)Push your code to GitHub.Create a new Web Service on Render and connect your GitHub repo.Use the following settings:Root Directory: resume-ats-checker/backendBuild Command: pip install -r requirements.txtStart Command: python run.pyGo to the Environment tab and add your GROQ_API_KEY.In backend/app/main.py, add your live Vercel URL to the origins list to fix CORS.Frontend (Vercel)In frontend/src/App.tsx, update the axios.post URL to point to your live Render backend URL.Push the change to GitHub.Create a new project on Vercel and import your GitHub repo.Use the following settings:Framework Preset: ViteRoot Directory: resume-ats-checker/frontendDeploy!