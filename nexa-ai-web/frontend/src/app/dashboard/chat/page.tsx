'use client';

import React, { useEffect, useState, useRef } from 'react';
import { 
  Bot, Send, Plus, Trash2, Sliders, ToggleLeft, 
  ToggleRight, Cpu, Zap, LayoutGrid, Layers, FolderPlus
} from 'lucide-react';
import { api } from '../../../lib/api';

interface Session {
  id: string;
  title: string;
  modelId: string;
  temperature: number;
  tokensPerSecond: number;
  timeToFirstTokenMs: number;
  folderName: string | null;
}

interface Message {
  id: string;
  role: 'USER' | 'ASSISTANT' | 'SYSTEM';
  content: string;
  tokensPerSecond?: number;
  inferenceTimeMs?: number;
}

export default function ChatPage() {
  const [mode, setMode] = useState<'standard' | 'compare'>('standard');
  const [sessions, setSessions] = useState<Session[]>([]);
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  
  // Creation configs
  const [newTitle, setNewTitle] = useState('');
  const [selectedModel, setSelectedModel] = useState('llama-3-3b');
  const [temperature, setTemperature] = useState(0.7);
  const [folderName, setFolderName] = useState('');
  
  // Chat input
  const [input, setInput] = useState('');
  const [isStreaming, setIsStreaming] = useState(false);
  
  // Configurations drawer
  const [showConfig, setShowConfig] = useState(false);

  // Compare Mode State
  const [compareModelA, setCompareModelA] = useState('llama-3-3b');
  const [compareModelB, setCompareModelB] = useState('phi-3-mini');
  const [compareInput, setCompareInput] = useState('');
  const [compareOutputA, setCompareOutputA] = useState('');
  const [compareOutputB, setCompareOutputB] = useState('');
  const [compareStatsA, setCompareStatsA] = useState({ speed: 0, latency: 0 });
  const [compareStatsB, setCompareStatsB] = useState({ speed: 0, latency: 0 });
  const [isComparing, setIsComparing] = useState(false);

  const messagesEndRef = useRef<HTMLDivElement>(null);

  const models = [
    { id: "llama-3-3b", name: "Llama 3 (3B)" },
    { id: "llama-3-8b", name: "Llama 3 (8B)" },
    { id: "phi-3-mini", name: "Phi-3 Mini (3.8B)" },
    { id: "gemma-2b-it", name: "Gemma 2B IT" }
  ];

  useEffect(() => {
    loadSessions();
  }, []);

  useEffect(() => {
    if (selectedSessionId) {
      loadMessages(selectedSessionId);
    } else {
      setMessages([]);
    }
  }, [selectedSessionId]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, compareOutputA, compareOutputB]);

  const loadSessions = async () => {
    try {
      const data = await api.getSessions();
      setSessions(data);
      if (data.length > 0 && !selectedSessionId) {
        setSelectedSessionId(data[0].id);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const loadMessages = async (id: string) => {
    try {
      const data = await api.getSessionMessages(id);
      setMessages(data);
    } catch (err) {
      console.error(err);
    }
  };

  const handleCreateSession = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const session = await api.createSession({
        title: newTitle || undefined,
        modelId: selectedModel,
        temperature,
        folderName: folderName || undefined
      });
      setNewTitle('');
      setFolderName('');
      setSessions([session, ...sessions]);
      setSelectedSessionId(session.id);
    } catch (err) {
      console.error(err);
    }
  };

  const handleDeleteSession = async (id: string) => {
    try {
      await api.deleteSession(id);
      const filtered = sessions.filter(s => s.id !== id);
      setSessions(filtered);
      if (selectedSessionId === id) {
        setSelectedSessionId(filtered.length > 0 ? filtered[0].id : null);
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Standard chat sending with SSE streaming
  const handleSendMessage = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim() || !selectedSessionId || isStreaming) return;

    const userText = input;
    setInput('');
    setIsStreaming(true);

    // Append User Message immediately to state
    const userMsg: Message = { id: 'temp-user', role: 'USER', content: userText };
    setMessages(prev => [...prev, userMsg]);

    try {
      const token = localStorage.getItem('nexa_token');
      const response = await fetch('http://localhost:5000/api/chat/messages/stream', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({
          sessionId: selectedSessionId,
          content: userText
        })
      });

      if (!response.ok) throw new Error("Failed to start stream");

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();
      if (!reader) throw new Error("Reader undefined");

      let assistantText = "";
      // Add a blank assistant message placeholder
      setMessages(prev => [...prev, { id: 'temp-assistant', role: 'ASSISTANT', content: "" }]);

      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');
        
        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const dataStr = line.slice(6).trim();
            if (!dataStr) continue;
            
            try {
              const data = JSON.parse(dataStr);
              if (data.token) {
                assistantText += data.token;
                setMessages(prev => prev.map(msg => 
                  msg.id === 'temp-assistant' 
                    ? { ...msg, content: assistantText } 
                    : msg
                ));
              }
              if (data.done) {
                // Replace placeholder with database-saved message including speeds/metrics
                setMessages(prev => prev.map(msg => 
                  msg.id === 'temp-assistant' ? data.message : msg
                ));
              }
            } catch (e) {
              // Ignore line parse errors in split chunk boundaries
            }
          }
        }
      }

      loadSessions(); // Reload sessions to update speed metrics

    } catch (err) {
      console.error(err);
    } finally {
      setIsStreaming(false);
    }
  };

  // Compare mode submission (Parallel mocked streaming)
  const handleCompareSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!compareInput.trim() || isComparing) return;

    const query = compareInput;
    setCompareInput('');
    setIsComparing(true);

    setCompareOutputA("Loading local models...");
    setCompareOutputB("Loading local models...");

    // Speeds
    const speedA = compareModelA.includes('7b') ? 19.4 : 45.2;
    const speedB = compareModelB.includes('7b') ? 18.1 : 48.9;
    const latA = compareModelA.includes('7b') ? 240 : 80;
    const latB = compareModelB.includes('7b') ? 260 : 75;

    // Output template
    const ansA = `[${compareModelA.toUpperCase()} Response]: Processing prompt vectors client-side. WebGPU backend has active memory allocation. Query parsed. Returning localized context answers.`;
    const ansB = `[${compareModelB.toUpperCase()} Response]: Received instruction frame. Compiling answers using WASM acceleration. RAG matches retrieved. Output speed optimized.`;

    setTimeout(() => {
      setCompareStatsA({ speed: speedA, latency: latA });
      setCompareStatsB({ speed: speedB, latency: latB });
      setCompareOutputA(ansA);
      setCompareOutputB(ansB);
      setIsComparing(false);
    }, 1500);
  };

  return (
    <div className="h-[calc(100vh-10rem)] flex gap-6">
      
      {/* WORKSPACE SECTOR CONTROL */}
      <div className="w-80 flex flex-col gap-6 shrink-0 h-full">
        {/* Switch mode */}
        <div className="glass-panel p-4 rounded-xl flex items-center justify-between border border-white/5">
          <span className="text-sm font-semibold text-white">Compare Mode</span>
          <button 
            onClick={() => setMode(mode === 'standard' ? 'compare' : 'standard')}
            className="text-primary hover:text-primary/80 transition-colors"
          >
            {mode === 'compare' 
              ? <ToggleRight className="w-10 h-10 text-primary" /> 
              : <ToggleLeft className="w-10 h-10 text-muted-foreground" />
            }
          </button>
        </div>

        {mode === 'standard' ? (
          // SESSIONS LIST (STANDARD MODE)
          <div className="glass-panel rounded-xl border border-white/5 flex-1 flex flex-col min-h-0">
            <div className="p-4 border-b border-white/5 flex items-center justify-between">
              <span className="text-xs font-bold text-white uppercase tracking-wider">Chat Sessions</span>
              <button 
                onClick={() => setShowConfig(!showConfig)}
                className="p-1.5 rounded-lg hover:bg-white/5 text-muted-foreground hover:text-white"
                title="Config New Session"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>

            {/* Create Session Form Drawer */}
            {showConfig && (
              <form onSubmit={handleCreateSession} className="p-4 border-b border-white/5 bg-white/[0.02] flex flex-col gap-3">
                <input
                  type="text"
                  placeholder="Session Title..."
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  className="px-3 py-2 rounded border border-white/10 glass-input text-xs text-white outline-none focus:border-primary"
                />
                <div className="grid grid-cols-2 gap-2">
                  <select
                    value={selectedModel}
                    onChange={(e) => setSelectedModel(e.target.value)}
                    className="px-2 py-2 rounded border border-white/10 bg-black text-xs text-white outline-none"
                  >
                    {models.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
                  </select>
                  <input
                    type="text"
                    placeholder="Folder..."
                    value={folderName}
                    onChange={(e) => setFolderName(e.target.value)}
                    className="px-3 py-2 rounded border border-white/10 glass-input text-xs text-white outline-none focus:border-primary"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <div className="flex justify-between text-[10px] text-muted-foreground font-mono">
                    <span>Temp</span>
                    <span>{temperature}</span>
                  </div>
                  <input
                    type="range"
                    min="0.1"
                    max="1.5"
                    step="0.1"
                    value={temperature}
                    onChange={(e) => setTemperature(parseFloat(e.target.value))}
                    className="w-full accent-primary"
                  />
                </div>
                <button type="submit" className="w-full py-2 bg-primary text-white rounded text-xs font-bold hover:bg-primary/95 transition-all">
                  Create Session
                </button>
              </form>
            )}

            {/* Session Items */}
            <div className="flex-1 overflow-y-auto p-2 flex flex-col gap-1">
              {sessions.map(s => {
                const isActive = selectedSessionId === s.id;
                return (
                  <div 
                    key={s.id}
                    onClick={() => setSelectedSessionId(s.id)}
                    className={`p-3 rounded-lg flex items-center justify-between gap-3 cursor-pointer group transition-all ${isActive ? 'bg-primary/10 border border-primary/20 text-white' : 'hover:bg-white/5 text-muted-foreground'}`}
                  >
                    <div className="flex flex-col overflow-hidden">
                      <span className="text-xs font-semibold truncate text-white">{s.title}</span>
                      <span className="text-[10px] text-muted-foreground mt-0.5 font-mono">{s.modelId}</span>
                    </div>
                    <button
                      onClick={(e) => { e.stopPropagation(); handleDeleteSession(s.id); }}
                      className="p-1 rounded opacity-0 group-hover:opacity-100 hover:bg-red-500/10 hover:text-red-400 transition-all text-muted-foreground"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          // MODEL PICKERS (COMPARE MODE)
          <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
            <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Compare Config</span>
            
            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-semibold text-muted-foreground uppercase font-mono">Model A (Left)</label>
              <select
                value={compareModelA}
                onChange={(e) => setCompareModelA(e.target.value)}
                className="w-full px-3 py-2 rounded border border-white/10 bg-black text-xs text-white outline-none"
              >
                {models.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="text-[10px] font-semibold text-muted-foreground uppercase font-mono">Model B (Right)</label>
              <select
                value={compareModelB}
                onChange={(e) => setCompareModelB(e.target.value)}
                className="w-full px-3 py-2 rounded border border-white/10 bg-black text-xs text-white outline-none"
              >
                {models.map(m => <option key={m.id} value={m.id}>{m.name}</option>)}
              </select>
            </div>
          </div>
        )}
      </div>

      {/* CHAT WINDOW */}
      <div className="flex-1 glass-panel rounded-xl border border-white/5 flex flex-col min-h-0 shadow-lg relative">
        
        {mode === 'standard' ? (
          // STANDARD CONVERSATION PANELS
          <div className="flex-1 flex flex-col min-h-0">
            {selectedSessionId ? (
              <>
                <div className="flex-1 overflow-y-auto p-6 flex flex-col gap-4">
                  {messages.map(msg => {
                    const isUser = msg.role === 'USER';
                    return (
                      <div key={msg.id} className={`flex gap-3 max-w-2xl ${isUser ? 'ml-auto flex-row-reverse' : 'mr-auto'}`}>
                        <div className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 ${isUser ? 'bg-primary/20 text-primary border border-primary/20' : 'bg-white/5 text-white border border-white/10'}`}>
                          {isUser ? '👤' : <Bot className="w-4 h-4" />}
                        </div>
                        <div className="flex flex-col gap-2">
                          <div className={`px-4 py-3 rounded-2xl text-sm leading-relaxed whitespace-pre-wrap ${isUser ? 'bg-primary text-white rounded-tr-none' : 'bg-white/5 border border-white/10 text-muted-foreground rounded-tl-none'}`}>
                            {msg.content}
                          </div>
                          {!isUser && msg.tokensPerSecond && (
                            <div className="flex items-center gap-4 text-[10px] text-muted-foreground font-mono bg-white/[0.02] border border-white/5 px-2 py-1 rounded-md w-fit">
                              <span className="flex items-center gap-1"><Zap className="w-3.5 h-3.5 text-primary" /> {msg.tokensPerSecond.toFixed(1)} Tok/s</span>
                              <span className="flex items-center gap-1"><Cpu className="w-3.5 h-3.5 text-purple-400" /> {msg.inferenceTimeMs}ms</span>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                  <div ref={messagesEndRef} />
                </div>

                <form onSubmit={handleSendMessage} className="p-4 border-t border-white/5 flex gap-3">
                  <input
                    type="text"
                    value={input}
                    onChange={(e) => setInput(e.target.value)}
                    placeholder="Type a message to generate answers locally..."
                    className="flex-1 px-4 py-3 rounded-lg glass-input border border-white/10 focus:outline-none focus:border-primary text-sm text-white"
                  />
                  <button 
                    type="submit" 
                    disabled={isStreaming}
                    className="px-5 py-3 bg-primary hover:bg-primary/90 text-white rounded-lg transition-all flex items-center justify-center shadow-lg shadow-primary/10 disabled:opacity-50"
                  >
                    <Send className="w-4 h-4" />
                  </button>
                </form>
              </>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-muted-foreground text-sm font-mono">
                <span>Select a chat session or create a new one to begin.</span>
              </div>
            )}
          </div>
        ) : (
          // DUAL COMPARE WORKSPACE PANELS
          <div className="flex-1 flex flex-col min-h-0">
            <div className="flex-1 grid grid-cols-2 divide-x divide-white/5 overflow-y-auto p-6 gap-6">
              
              {/* Panel Left */}
              <div className="flex flex-col gap-4">
                <div className="flex justify-between items-center bg-white/5 px-3 py-2 rounded-lg border border-white/5 text-xs font-mono">
                  <span className="text-white font-bold">{compareModelA.toUpperCase()}</span>
                  {compareStatsA.speed > 0 && (
                    <span className="text-primary">{compareStatsA.speed.toFixed(1)} Tok/s ({compareStatsA.latency}ms)</span>
                  )}
                </div>
                <div className="bg-black/30 p-4 rounded-xl flex-1 text-sm font-mono leading-relaxed border border-white/5">
                  {compareOutputA || "Waiting for comparison query..."}
                </div>
              </div>

              {/* Panel Right */}
              <div className="flex flex-col gap-4 pl-6">
                <div className="flex justify-between items-center bg-white/5 px-3 py-2 rounded-lg border border-white/5 text-xs font-mono">
                  <span className="text-white font-bold">{compareModelB.toUpperCase()}</span>
                  {compareStatsB.speed > 0 && (
                    <span className="text-primary">{compareStatsB.speed.toFixed(1)} Tok/s ({compareStatsB.latency}ms)</span>
                  )}
                </div>
                <div className="bg-black/30 p-4 rounded-xl flex-1 text-sm font-mono leading-relaxed border border-white/5">
                  {compareOutputB || "Waiting for comparison query..."}
                </div>
              </div>

            </div>

            <form onSubmit={handleCompareSubmit} className="p-4 border-t border-white/5 flex gap-3">
              <input
                type="text"
                value={compareInput}
                onChange={(e) => setCompareInput(e.target.value)}
                placeholder="Type a comparison prompt (e.g. Write a quicksort in JavaScript)..."
                className="flex-1 px-4 py-3 rounded-lg glass-input border border-white/10 focus:outline-none focus:border-primary text-sm text-white"
              />
              <button 
                type="submit" 
                disabled={isComparing}
                className="px-6 py-3 bg-primary hover:bg-primary/90 text-white rounded-lg text-sm font-semibold transition-all shadow-lg"
              >
                Compare
              </button>
            </form>
          </div>
        )}
      </div>

    </div>
  );
}
