'use client';

import React, { useState, useEffect } from 'react';
import { 
  Gauge, Cpu, HardDrive, CheckCircle2, 
  HelpCircle, Sparkles, RefreshCw
} from 'lucide-react';
import { api } from '../../../lib/api';

interface Profile {
  os: string;
  cpuCores: number;
  totalRamGb: number;
  gpuModel: string | null;
  maxSupportedModelSizeGb: number;
}

interface Recommendation {
  id: string;
  name: string;
  type: string;
  sizeGb: number;
  format: string;
  recommendedRamGb: number;
  score: number;
  compatibilityStatus: 'OPTIMAL' | 'COMPATIBLE' | 'LAGGY' | 'UNSUPPORTED';
}

export default function OptimizerPage() {
  const [loading, setLoading] = useState(false);
  const [profile, setProfile] = useState<Profile | null>(null);
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);
  const [advice, setAdvice] = useState('');

  // Real-time server diagnostics (Socket.io simulation)
  const [metrics, setMetrics] = useState({
    cpu: 12.5,
    ram: 6.4,
    gpu: 0.0
  });

  useEffect(() => {
    // Initial fetch
    api.getDeviceProfile()
      .then(data => {
        setProfile(data);
      })
      .catch(() => null);

    // Simulating WebSocket live statistics updates
    const interval = setInterval(() => {
      setMetrics(prev => ({
        cpu: Math.max(5, Math.min(95, prev.cpu + (Math.random() - 0.5) * 5)),
        ram: Math.max(4, Math.min(16, prev.ram + (Math.random() - 0.5) * 0.2)),
        gpu: Math.max(0, Math.min(100, prev.gpu + (Math.random() - 0.5) * 10))
      }));
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  const handleScan = async () => {
    setLoading(true);
    // Mocking browser window hardware specs
    const mockSpecs = {
      os: "Windows 11 (x64)",
      cpuCores: 8,
      totalRamGb: 16,
      gpuModel: "NVIDIA GeForce RTX 4560 Ti"
    };

    try {
      const res = await api.profileHardware(mockSpecs);
      setProfile(res.profile);
      setRecommendations(res.recommendations);
      setAdvice(res.systemAdvice);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-6">
      
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-xl font-bold text-white">Hardware Optimizer</h3>
          <p className="text-xs text-muted-foreground mt-1">Profile local hardware and receive recommendations for optimal edge LLM execution.</p>
        </div>
        <button 
          onClick={handleScan}
          disabled={loading}
          className="px-4 py-2.5 bg-primary hover:bg-primary/90 text-white rounded-lg text-xs font-semibold flex items-center gap-2 transition-all shadow shadow-primary/10"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          {loading ? 'Scanning...' : 'Scan System Specs'}
        </button>
      </div>

      {/* REAL-TIME DIAGNOSTIC METRIC CARDS */}
      <div className="grid md:grid-cols-3 gap-6">
        
        {/* CPU */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
          <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
            <span>CPU CORE LOAD</span>
            <Cpu className="w-4 h-4 text-primary" />
          </div>
          <div>
            <span className="text-3xl font-extrabold font-mono tracking-tight text-white">{metrics.cpu.toFixed(1)}%</span>
            <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden mt-3">
              <div className="bg-primary h-full rounded-full transition-all duration-500" style={{ width: `${metrics.cpu}%` }} />
            </div>
          </div>
        </div>

        {/* RAM */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
          <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
            <span>RAM IN-USE</span>
            <HardDrive className="w-4 h-4 text-purple-400" />
          </div>
          <div>
            <span className="text-3xl font-extrabold font-mono tracking-tight text-white">{metrics.ram.toFixed(1)} <span className="text-sm font-normal text-muted-foreground">GB</span></span>
            <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden mt-3">
              <div className="bg-purple-500 h-full rounded-full transition-all duration-500" style={{ width: `${(metrics.ram / 16) * 100}%` }} />
            </div>
          </div>
        </div>

        {/* GPU */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
          <div className="flex items-center justify-between text-xs text-muted-foreground font-mono">
            <span>GPU COPROCESSOR</span>
            <Gauge className="w-4 h-4 text-pink-400" />
          </div>
          <div>
            <span className="text-3xl font-extrabold font-mono tracking-tight text-white">{metrics.gpu.toFixed(1)}%</span>
            <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden mt-3">
              <div className="bg-pink-500 h-full rounded-full transition-all duration-500" style={{ width: `${metrics.gpu}%` }} />
            </div>
          </div>
        </div>

      </div>

      <div className="grid md:grid-cols-3 gap-6 items-stretch">
        
        {/* HARDWARE PROFILE SUMMARY */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-6 h-fit">
          <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Hardware Inventory</span>
          
          {profile ? (
            <div className="flex flex-col gap-4 font-mono text-xs text-muted-foreground">
              <div className="flex justify-between border-b border-white/[0.02] pb-2">
                <span>OS</span>
                <strong className="text-white">{profile.os}</strong>
              </div>
              <div className="flex justify-between border-b border-white/[0.02] pb-2">
                <span>CPU Cores</span>
                <strong className="text-white">{profile.cpuCores}</strong>
              </div>
              <div className="flex justify-between border-b border-white/[0.02] pb-2">
                <span>Total RAM</span>
                <strong className="text-white">{profile.totalRamGb} GB</strong>
              </div>
              <div className="flex justify-between border-b border-white/[0.02] pb-2">
                <span>GPU</span>
                <strong className="text-white truncate max-w-[140px]">{profile.gpuModel || 'None'}</strong>
              </div>
              <div className="flex justify-between">
                <span>Max Model size</span>
                <strong className="text-primary">{profile.maxSupportedModelSizeGb} GB</strong>
              </div>
            </div>
          ) : (
            <div className="text-center py-6 text-xs text-muted-foreground">
              No hardware profile recorded. Run the scan above.
            </div>
          )}

          {advice && (
            <div className="bg-primary/5 border border-primary/20 p-4 rounded-lg flex items-start gap-2 text-xs text-muted-foreground leading-normal mt-2">
              <Sparkles className="w-5 h-5 text-primary shrink-0" />
              <span>{advice}</span>
            </div>
          )}
        </div>

        {/* MODEL COMPATIBILITY LIST */}
        <div className="md:col-span-2 glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
          <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Recommended Local Models</span>
          
          <div className="flex flex-col gap-3">
            {recommendations.map(rec => (
              <div key={rec.id} className="p-3 bg-white/[0.02] border border-white/5 rounded-lg flex items-center justify-between gap-4">
                <div className="flex flex-col">
                  <span className="text-xs font-semibold text-white">{rec.name}</span>
                  <div className="flex gap-3 text-[10px] text-muted-foreground mt-0.5 font-mono">
                    <span>Size: {rec.sizeGb} GB</span>
                    <span>Required RAM: {rec.recommendedRamGb} GB</span>
                  </div>
                </div>

                <div className="flex items-center gap-4">
                  <div className="flex flex-col items-end gap-1">
                    <span className="text-[10px] text-muted-foreground font-mono">Compatibility Score</span>
                    <div className="flex items-center gap-1.5 font-mono text-xs font-bold">
                      <span className={rec.score >= 80 ? 'text-green-500' : rec.score >= 50 ? 'text-yellow-500' : 'text-red-500'}>{rec.score}%</span>
                    </div>
                  </div>

                  <span className={`px-2.5 py-1 rounded text-[9px] font-bold tracking-wider font-mono uppercase ${
                    rec.compatibilityStatus === 'OPTIMAL' 
                      ? 'bg-green-500/10 text-green-500 border border-green-500/20' 
                      : rec.compatibilityStatus === 'COMPATIBLE' 
                        ? 'bg-blue-500/10 text-blue-400 border border-blue-500/20'
                        : rec.compatibilityStatus === 'LAGGY'
                          ? 'bg-yellow-500/10 text-yellow-500 border border-yellow-500/20'
                          : 'bg-red-500/10 text-red-500 border border-red-500/20'
                  }`}>
                    {rec.compatibilityStatus}
                  </span>
                </div>
              </div>
            ))}

            {recommendations.length === 0 && (
              <div className="text-center text-xs text-muted-foreground py-8 font-mono">
                Scan your system to see model compatibilities.
              </div>
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
