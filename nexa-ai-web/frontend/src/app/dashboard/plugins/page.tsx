'use client';

import React, { useEffect, useState } from 'react';
import { 
  Blocks, Globe, Code2, Notebook, 
  Plus, Check, HelpCircle
} from 'lucide-react';
import { api } from '../../../lib/api';

interface Plugin {
  id: string;
  name: string;
  identifier: string;
  version: string;
  description: string | null;
  icon: string | null;
  author: string | null;
  activeStatus: boolean;
}

export default function PluginsPage() {
  const [plugins, setPlugins] = useState<Plugin[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddDrawer, setShowAddDrawer] = useState(false);

  // Custom Plugin Fields
  const [name, setName] = useState('');
  const [identifier, setIdentifier] = useState('');
  const [version, setVersion] = useState('1.0.0');
  const [description, setDescription] = useState('');
  const [author, setAuthor] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    loadPlugins();
  }, []);

  const loadPlugins = async () => {
    try {
      const data = await api.getPlugins();
      setPlugins(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleToggle = async (id: string, currentStatus: boolean) => {
    try {
      const updated = await api.togglePlugin(id, !currentStatus);
      setPlugins(plugins.map(p => p.id === id ? updated : p));
    } catch (err) {
      console.error(err);
    }
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    try {
      const plugin = await api.registerPlugin({
        name,
        identifier,
        version,
        description,
        author
      });

      setPlugins([...plugins, plugin]);
      setName('');
      setIdentifier('');
      setDescription('');
      setAuthor('');
      setShowAddDrawer(false);
    } catch (err: any) {
      setError(err.message || 'Error registering plugin');
    }
  };

  const renderIcon = (name: string | null) => {
    switch(name) {
      case 'Globe': return <Globe className="w-5 h-5 text-primary" />;
      case 'Code2': return <Code2 className="w-5 h-5 text-purple-400" />;
      case 'Notebook': return <Notebook className="w-5 h-5 text-pink-400" />;
      default: return <Blocks className="w-5 h-5 text-muted-foreground" />;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <span className="text-sm text-muted-foreground font-mono">Loading plugins configurations...</span>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-6">
      
      <div className="flex items-center justify-between">
        <div>
          <h3 className="text-xl font-bold text-white">Plugins & Tools Integrations</h3>
          <p className="text-xs text-muted-foreground mt-1">Enhance chat model capabilities by enabling external data sandboxes and sync plugins.</p>
        </div>
        <button 
          onClick={() => setShowAddDrawer(!showAddDrawer)}
          className="px-4 py-2.5 bg-primary hover:bg-primary/90 text-white rounded-lg text-xs font-semibold flex items-center gap-2 transition-all shadow shadow-primary/10"
        >
          <Plus className="w-3.5 h-3.5" />
          Register Custom Plugin
        </button>
      </div>

      <div className="grid md:grid-cols-3 gap-6 items-stretch">
        
        {/* PLUGINS LIST */}
        <div className="md:col-span-2 flex flex-col gap-4">
          {plugins.map(p => (
            <div 
              key={p.id}
              className={`glass-panel p-5 rounded-xl border flex items-start gap-4 transition-all ${
                p.activeStatus 
                  ? 'border-primary/20 bg-primary/[0.005]' 
                  : 'border-white/5'
              }`}
            >
              <div className="w-10 h-10 rounded-lg bg-white/5 flex items-center justify-center border border-white/5 shrink-0">
                {renderIcon(p.icon)}
              </div>

              <div className="flex-1 flex flex-col gap-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h4 className="text-sm font-bold text-white">{p.name}</h4>
                  <span className="text-[9px] font-mono text-muted-foreground bg-white/5 px-1.5 py-0.5 rounded border border-white/5">v{p.version}</span>
                </div>
                <span className="text-[10px] text-muted-foreground font-mono truncate">{p.identifier}</span>
                <p className="text-xs text-muted-foreground leading-relaxed mt-1">{p.description}</p>
                {p.author && (
                  <span className="text-[10px] text-muted-foreground mt-2">Author: <strong className="text-white">{p.author}</strong></span>
                )}
              </div>

              <button
                onClick={() => handleToggle(p.id, p.activeStatus)}
                className={`px-4 py-2 rounded-lg text-xs font-semibold transition-all border shrink-0 ${
                  p.activeStatus 
                    ? 'bg-primary/25 border-primary/40 text-primary hover:bg-primary/30' 
                    : 'bg-white/5 border-white/10 text-muted-foreground hover:bg-white/10 hover:text-white'
                }`}
              >
                {p.activeStatus ? 'Enabled' : 'Disabled'}
              </button>
            </div>
          ))}
        </div>

        {/* CUSTOM REGISTER DRAWER */}
        {showAddDrawer && (
          <div className="glass-panel p-6 rounded-xl border border-primary/20 flex flex-col gap-4 h-fit">
            <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">New Plugin Manifest</span>
            
            {error && (
              <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-[10px] p-2.5 rounded font-mono">
                {error}
              </div>
            )}

            <form onSubmit={handleRegister} className="flex flex-col gap-4 text-xs">
              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Plugin Name</label>
                <input 
                  type="text" 
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g. SQLite Exporter"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Identifier</label>
                <input 
                  type="text" 
                  required
                  value={identifier}
                  onChange={(e) => setIdentifier(e.target.value)}
                  placeholder="e.g. nexa.plugin.sqlite"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Version</label>
                <input 
                  type="text" 
                  required
                  value={version}
                  onChange={(e) => setVersion(e.target.value)}
                  placeholder="1.0.0"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Description</label>
                <textarea 
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  placeholder="What does this plugin do..."
                  rows={3}
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary resize-none"
                />
              </div>

              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Author</label>
                <input 
                  type="text" 
                  value={author}
                  onChange={(e) => setAuthor(e.target.value)}
                  placeholder="Custom dev"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>

              <button 
                type="submit"
                className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-semibold rounded-lg shadow mt-2"
              >
                Register Manifest
              </button>
            </form>
          </div>
        )}

      </div>

    </div>
  );
}
