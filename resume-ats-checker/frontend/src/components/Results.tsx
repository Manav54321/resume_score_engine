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
    if (score >= 90) return 'text-green-400';
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
