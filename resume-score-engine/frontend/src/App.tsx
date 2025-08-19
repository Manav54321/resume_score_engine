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

      const resp = await axios.post("https://resume-analyzer-backend-0udg.onrender.com/analyze-resume/", form, {
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
