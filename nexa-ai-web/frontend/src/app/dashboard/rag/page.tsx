'use client';

import React, { useState } from 'react';
import { 
  FolderArchive, Upload, File, FileText, 
  Trash2, Sliders, CheckCircle, Clock
} from 'lucide-react';

interface RAGFile {
  id: string;
  name: string;
  sizeKb: number;
  chunkCount: number;
  status: 'PROCESSING' | 'COMPLETED' | 'FAILED';
  uploadedAt: string;
}

export default function RAGPage() {
  const [chunkSize, setChunkSize] = useState(256);
  const [overlapSize, setOverlapSize] = useState(32);
  const [files, setFiles] = useState<RAGFile[]>([
    { id: '1', name: 'NexaAI_Architecture_Whitepaper.pdf', sizeKb: 1420, chunkCount: 340, status: 'COMPLETED', uploadedAt: '2026-06-12' },
    { id: '2', name: 'Privacy_Agreement_Template.docx', sizeKb: 340, chunkCount: 82, status: 'COMPLETED', uploadedAt: '2026-06-12' }
  ]);
  const [isUploading, setIsUploading] = useState(false);

  const handleUploadSimulate = (e: React.FormEvent) => {
    e.preventDefault();
    setIsUploading(true);

    setTimeout(() => {
      const newFile: RAGFile = {
        id: Date.now().toString(),
        name: `User_Doc_${Math.floor(Math.random()*100)}.txt`,
        sizeKb: 24,
        chunkCount: Math.ceil(24 * 1024 / chunkSize),
        status: 'PROCESSING',
        uploadedAt: new Date().toISOString().split('T')[0]
      };

      setFiles(prev => [newFile, ...prev]);
      setIsUploading(false);

      // Simulate vector indexing completion
      setTimeout(() => {
        setFiles(prev => prev.map(f => f.id === newFile.id ? { ...f, status: 'COMPLETED' } : f));
      }, 2000);

    }, 1200);
  };

  const handleDelete = (id: string) => {
    setFiles(files.filter(f => f.id !== id));
  };

  return (
    <div className="flex flex-col gap-6">
      
      <div>
        <h3 className="text-xl font-bold text-white">Local RAG Knowledge Base</h3>
        <p className="text-xs text-muted-foreground mt-1">Upload and index documents to reference during conversations. All vector transformations are performed locally.</p>
      </div>

      <div className="grid md:grid-cols-3 gap-6 items-stretch">
        
        {/* CONFIGURATION COLUMN */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-6 h-fit">
          <div className="flex items-center gap-2 border-b border-white/5 pb-2">
            <Sliders className="w-4 h-4 text-primary" />
            <span className="text-xs font-bold text-white uppercase tracking-wider font-mono">Indexing Parameters</span>
          </div>

          <div className="flex flex-col gap-2">
            <div className="flex justify-between text-xs font-mono text-muted-foreground">
              <span>Chunk Size</span>
              <span className="text-primary font-bold">{chunkSize} tokens</span>
            </div>
            <input 
              type="range" 
              min="64" 
              max="1024" 
              step="64" 
              value={chunkSize}
              onChange={(e) => setChunkSize(parseInt(e.target.value))}
              className="w-full accent-primary"
            />
            <span className="text-[10px] text-muted-foreground leading-normal">Large chunks maintain broader context, while small chunks improve specific match speeds.</span>
          </div>

          <div className="flex flex-col gap-2">
            <div className="flex justify-between text-xs font-mono text-muted-foreground">
              <span>Chunk Overlap</span>
              <span className="text-purple-400 font-bold">{overlapSize} tokens</span>
            </div>
            <input 
              type="range" 
              min="0" 
              max="128" 
              step="8" 
              value={overlapSize}
              onChange={(e) => setOverlapSize(parseInt(e.target.value))}
              className="w-full accent-primary"
            />
            <span className="text-[10px] text-muted-foreground leading-normal">Overlap tokens prevent semantic loss on split text boundaries.</span>
          </div>
        </div>

        {/* UPLOAD & LIST FILE COLUMN */}
        <div className="md:col-span-2 flex flex-col gap-6">
          {/* UPLOAD TRIGGER */}
          <div 
            onClick={handleUploadSimulate}
            className="border-2 border-dashed border-white/10 hover:border-primary/40 rounded-xl p-8 flex flex-col items-center justify-center gap-3 bg-white/[0.01] hover:bg-white/[0.02] cursor-pointer transition-all text-center"
          >
            <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center text-primary">
              <Upload className="w-6 h-6" />
            </div>
            <div>
              <span className="text-sm font-semibold text-white block">Drag and drop file, or click to browse</span>
              <span className="text-[10px] text-muted-foreground mt-1 block">Supports PDF, DOCX, TXT (Max size 15MB)</span>
            </div>
            {isUploading && (
              <span className="text-xs text-primary font-mono animate-pulse">Hashing local vectors...</span>
            )}
          </div>

          {/* INDEXED FILES LIST */}
          <div className="glass-panel rounded-xl border border-white/5 p-6 flex flex-col gap-4">
            <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Indexed Documents</span>
            
            <div className="flex flex-col gap-3">
              {files.map(f => (
                <div key={f.id} className="p-3 bg-white/[0.02] border border-white/5 rounded-lg flex items-center justify-between gap-4">
                  <div className="flex items-center gap-3 overflow-hidden">
                    <div className="w-8 h-8 rounded bg-white/5 flex items-center justify-center text-primary border border-white/5 shrink-0">
                      {f.name.endsWith('.pdf') ? <FileText className="w-4 h-4" /> : <File className="w-4 h-4" />}
                    </div>
                    <div className="flex flex-col overflow-hidden">
                      <span className="text-xs font-semibold text-white truncate">{f.name}</span>
                      <div className="flex gap-3 text-[10px] text-muted-foreground mt-0.5 font-mono">
                        <span>{(f.sizeKb / 1024).toFixed(1)} MB</span>
                        <span>{f.chunkCount} chunks</span>
                        <span>{f.uploadedAt}</span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 shrink-0">
                    {f.status === 'PROCESSING' ? (
                      <span className="flex items-center gap-1.5 text-[10px] text-yellow-500 font-mono"><Clock className="w-3.5 h-3.5 animate-spin" /> Chunking...</span>
                    ) : (
                      <span className="flex items-center gap-1.5 text-[10px] text-green-500 font-mono"><CheckCircle className="w-3.5 h-3.5" /> Completed</span>
                    )}

                    <button 
                      onClick={() => handleDelete(f.id)}
                      className="p-1.5 rounded hover:bg-red-500/10 hover:text-red-400 text-muted-foreground transition-all"
                      title="Remove Vector Index"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}

              {files.length === 0 && (
                <div className="text-center text-xs text-muted-foreground py-8">
                  No local documents indexed. Upload a file above.
                </div>
              )}
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}
