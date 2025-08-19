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
