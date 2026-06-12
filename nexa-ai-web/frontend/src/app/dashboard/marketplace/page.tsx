'use client';

import React, { useEffect, useState } from 'react';
import { 
  ShoppingBag, HardDrive, AlertTriangle, 
  ArrowDownToLine, Check, HelpCircle
} from 'lucide-react';
import { api } from '../../../lib/api';

interface Model {
  id: string;
  name: string;
  type: string;
  parameters: string;
  sizeGb: number;
  format: string;
  description: string;
  recommendedRamGb: number;
  isPopular: boolean;
}

export default function MarketplacePage() {
  const [catalog, setCatalog] = useState<Model[]>([]);
  const [installed, setInstalled] = useState<string[]>([]);
  const [downloads, setDownloads] = useState<{ [key: string]: number }>({});
  const [loading, setLoading] = useState(true);

  // System profile limits
  const [systemRamGb, setSystemRamGb] = useState(8);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      const cat = await api.getModelCatalog();
      setCatalog(cat);

      const inst = await api.getInstalledModels();
      setInstalled(inst.map((i: any) => i.modelId));

      const prof = await api.getDeviceProfile().catch(() => null);
      if (prof) setSystemRamGb(prof.totalRamGb);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleDownload = async (modelId: string) => {
    if (downloads[modelId] !== undefined || installed.includes(modelId)) return;

    try {
      const res = await api.downloadModel(modelId);
      console.log(res.message);

      // Simulate download progress stream
      setDownloads(prev => ({ ...prev, [modelId]: 0 }));
      
      const interval = setInterval(() => {
        setDownloads(prev => {
          const current = prev[modelId];
          if (current >= 100) {
            clearInterval(interval);
            setInstalled(inst => [...inst, modelId]);
            // Remove from progress tracker
            const next = { ...prev };
            delete next[modelId];
            return next;
          }
          return { ...prev, [modelId]: current + 10 + Math.floor(Math.random() * 10) };
        });
      }, 300);

    } catch (err) {
      console.error(err);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <span className="text-sm text-muted-foreground font-mono">Loading marketplace catalog...</span>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-xl font-bold text-white">Model Marketplace</h3>
          <p className="text-xs text-muted-foreground mt-1">Download LLM and translation engines directly to local browser storage.</p>
        </div>
        
        {/* System constraint overlay */}
        <div className="glass-panel px-4 py-2 rounded-lg border border-white/5 text-xs font-mono flex items-center gap-2 text-muted-foreground">
          <HardDrive className="w-4 h-4 text-primary" />
          <span>System RAM Limit: <strong className="text-white">{systemRamGb} GB</strong></span>
        </div>
      </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {catalog.map(model => {
          const isInstalled = installed.includes(model.id);
          const isDownloading = downloads[model.id] !== undefined;
          const progress = downloads[model.id] || 0;
          const isMemoryCritical = model.recommendedRamGb > systemRamGb;

          return (
            <div 
              key={model.id}
              className={`glass-panel p-6 rounded-xl border flex flex-col gap-4 relative overflow-hidden transition-all ${
                isInstalled 
                  ? 'border-green-500/20 bg-green-500/[0.01]' 
                  : isMemoryCritical 
                    ? 'border-yellow-500/20 hover:border-yellow-500/40 bg-yellow-500/[0.005]' 
                    : 'border-white/5 hover:border-primary/20'
              }`}
            >
              {model.isPopular && (
                <span className="absolute top-4 right-4 px-2 py-0.5 rounded bg-primary/20 text-primary text-[8px] font-bold tracking-wider uppercase">POPULAR</span>
              )}

              <div className="flex flex-col">
                <span className="text-xs font-bold text-primary tracking-wider uppercase font-mono">{model.type}</span>
                <h4 className="text-lg font-bold text-white mt-1">{model.name}</h4>
                <div className="flex gap-4 mt-2 font-mono text-[10px] text-muted-foreground">
                  <span>Size: <strong className="text-white">{model.sizeGb} GB</strong></span>
                  <span>Format: <strong className="text-white">{model.format}</strong></span>
                </div>
              </div>

              <p className="text-xs text-muted-foreground leading-normal flex-1">
                {model.description}
              </p>

              {/* Memory warn callout */}
              {isMemoryCritical && (
                <div className="bg-yellow-500/10 border border-yellow-500/25 p-3 rounded-lg flex items-start gap-2 text-[10px] text-yellow-400 leading-normal">
                  <AlertTriangle className="w-4 h-4 shrink-0" />
                  <span>Memory Warning: Requires {model.recommendedRamGb}GB RAM. Running this model may cause browser lag.</span>
                </div>
              )}

              {/* Download actions */}
              <div className="border-t border-white/5 pt-4">
                {isInstalled ? (
                  <div className="w-full py-2.5 rounded-lg bg-green-500/10 border border-green-500/25 text-green-500 text-xs font-semibold flex items-center justify-center gap-2">
                    <Check className="w-4 h-4" /> Installed & Active
                  </div>
                ) : isDownloading ? (
                  <div className="flex flex-col gap-2">
                    <div className="flex justify-between text-[10px] text-muted-foreground font-mono">
                      <span>Downloading files...</span>
                      <span>{progress}%</span>
                    </div>
                    <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden">
                      <div className="bg-primary h-full rounded-full transition-all duration-300" style={{ width: `${progress}%` }} />
                    </div>
                  </div>
                ) : (
                  <button 
                    onClick={() => handleDownload(model.id)}
                    className="w-full py-2.5 rounded-lg bg-white/5 hover:bg-white/10 text-white border border-white/10 text-xs font-semibold flex items-center justify-center gap-2 transition-all"
                  >
                    <ArrowDownToLine className="w-4 h-4" /> Download model
                  </button>
                )}
              </div>
            </div>
          );
        })}
      </div>

    </div>
  );
}
