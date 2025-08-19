import React, { useState } from 'react';
import axios from 'axios';
import { FileUpload } from './components/FileUpload';
import { JobDetails } from './components/JobDetails';
import { Results } from './components/Results';
import { Spinner } from './components/Spinner';

const App: React.FC = () => {
    const [file, setFile] = useState<File | null>(null);
    const [jobTitle, setJobTitle] = useState('');
    const [jobDescription, setJobDescription] = useState('');
    const [results, setResults] = useState<any>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async () => {
        if (!file || !jobTitle) {
            setError('Please upload a resume and enter a job title.');
            return;
        }

        setLoading(true);
        setError(null);
        setResults(null);

        const formData = new FormData();
        formData.append('file', file);
        formData.append('job_title', jobTitle);
        if (jobDescription) {
            formData.append('job_description', jobDescription);
        }

        try {
            // NOTE: Ensure this URL is correct for your setup (localhost or network IP)
            const response = await axios.post('http://192.168.1.18:8000/analyze-resume/', formData, {
                headers: {
                    'Content-Type': 'multipart/form-data',
                },
            });
            setResults(response.data);
        } catch (err: any) {
            console.error("Analysis failed with error:", err);
            const errorMessage = err.response?.data?.detail || 'An error occurred. Check the browser console for details.';
            setError(errorMessage);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="min-h-screen w-full flex flex-col items-center p-4 sm:p-6 lg:p-8">
            <div className="w-full max-w-2xl mx-auto space-y-10">
                <header className="text-center">
                    <h1 className="text-4xl sm:text-5xl font-bold text-brand-light">ATS Resume Analyzer</h1>
                    <p className="text-brand-secondary mt-2">
                        See how your resume scores against a job description.
                    </p>
                </header>

                <main className="space-y-8">
                    <div className="space-y-6 p-6 bg-brand-card border border-brand-border rounded-lg">
                        <FileUpload setFile={setFile} file={file} />
                        <JobDetails
                            jobTitle={jobTitle}
                            setJobTitle={setJobTitle}
                            jobDescription={jobDescription}
                            setJobDescription={setJobDescription}
                        />
                    </div>

                    <div className="text-center">
                        <button
                            onClick={handleSubmit}
                            disabled={loading || !file || !jobTitle}
                            className="w-full sm:w-auto bg-brand-light text-brand-dark font-semibold py-3 px-8 rounded-lg transition-transform duration-200 ease-in-out hover:scale-105 disabled:bg-brand-secondary disabled:cursor-not-allowed disabled:scale-100"
                        >
                            {loading ? <Spinner /> : 'Analyze Resume'}
                        </button>
                    </div>

                    {error && <p className="text-red-400 text-center mt-4">{error}</p>}
                    
                    {results && <Results data={results} />}
                </main>
                 <footer className="text-center text-brand-secondary text-sm mt-12">
                    <p>Powered by Groq & Llama 4 Maverick</p>
                </footer>
            </div>
        </div>
    );
};

export default App;
