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
