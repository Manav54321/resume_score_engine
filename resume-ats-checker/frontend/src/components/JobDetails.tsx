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
