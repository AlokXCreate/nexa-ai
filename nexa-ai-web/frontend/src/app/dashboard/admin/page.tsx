'use client';

import React, { useEffect, useState } from 'react';
import { 
  Users, CreditCard, Layers, Zap, 
  Activity, ShieldAlert, BarChart3
} from 'lucide-react';
import { api } from '../../../lib/api';

interface AdminStats {
  metrics: {
    totalUsers: number;
    premiumUsers: number;
    totalSessions: number;
    totalMessages: number;
    totalRevenue: number;
    averageTokensPerSecond: number;
    averageLatencyMs: number;
  };
  subscriptions: {
    FREE: number;
    PRO: number;
    ENTERPRISE: number;
  };
  systemHealth: {
    cpuLoadPercent: number;
    ramUsageGb: number;
    totalEgressGb: number;
    status: string;
    errorRatePercent: number;
  };
  latencyHistory: Array<{ day: string; latencyMs: number }>;
}

export default function AdminPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api.getAdminStats()
      .then(data => {
        setStats(data);
      })
      .catch(err => {
        setError(err.message || 'Access Denied: Admin privileges required.');
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <span className="text-sm text-muted-foreground font-mono">Fetching admin statistics...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex items-center justify-center h-96 text-center">
        <div className="flex flex-col items-center gap-4 max-w-sm glass-panel p-8 rounded-xl border border-red-500/20 bg-red-500/[0.01]">
          <ShieldAlert className="w-12 h-12 text-red-500 animate-pulse" />
          <h3 className="text-lg font-bold text-white">Access Violation</h3>
          <p className="text-xs text-muted-foreground leading-normal">{error}</p>
        </div>
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div className="flex flex-col gap-6">
      
      <div>
        <h3 className="text-xl font-bold text-white">Admin Operations Panel</h3>
        <p className="text-xs text-muted-foreground mt-1">Review global system metrics, model download bandwiths, subscription details and telemetry logs.</p>
      </div>

      {/* METRIC OVERVIEW GRID */}
      <div className="grid md:grid-cols-4 gap-6">
        
        {/* Total Users */}
        <div className="glass-panel p-5 rounded-xl border border-white/5 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[10px] text-muted-foreground uppercase font-mono">Total Registrations</span>
            <span className="text-2xl font-extrabold font-mono text-white">{stats.metrics.totalUsers}</span>
          </div>
          <Users className="w-8 h-8 text-primary" />
        </div>

        {/* Premium Converters */}
        <div className="glass-panel p-5 rounded-xl border border-white/5 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[10px] text-muted-foreground uppercase font-mono">Premium Subscriptions</span>
            <span className="text-2xl font-extrabold font-mono text-white">{stats.metrics.premiumUsers}</span>
          </div>
          <Activity className="w-8 h-8 text-purple-400" />
        </div>

        {/* Total Sessions */}
        <div className="glass-panel p-5 rounded-xl border border-white/5 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[10px] text-muted-foreground uppercase font-mono">Aggregated Chats</span>
            <span className="text-2xl font-extrabold font-mono text-white">{stats.metrics.totalSessions}</span>
          </div>
          <Layers className="w-8 h-8 text-pink-400" />
        </div>

        {/* Total Egress Revenue */}
        <div className="glass-panel p-5 rounded-xl border border-white/5 flex items-center justify-between">
          <div className="flex flex-col gap-1">
            <span className="text-[10px] text-muted-foreground uppercase font-mono">Egress Payments</span>
            <span className="text-2xl font-extrabold font-mono text-primary">${stats.metrics.totalRevenue.toFixed(2)}</span>
          </div>
          <CreditCard className="w-8 h-8 text-green-500" />
        </div>

      </div>

      {/* GRAPH AND SYSTEM HEALTH BLOCKS */}
      <div className="grid md:grid-cols-3 gap-6">
        
        {/* LATENCY HISTORICAL GRAPH MOCK */}
        <div className="md:col-span-2 glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-4">
          <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Inference Latency Trend (Weekly)</span>
          
          <div className="h-48 flex items-end justify-between gap-4 pt-4 px-2">
            {stats.latencyHistory.map(lh => {
              // Normalized height mapping (Max height value is 200ms)
              const heightPct = Math.round((lh.latencyMs / 200) * 100);
              return (
                <div key={lh.day} className="flex-1 flex flex-col items-center gap-2 h-full justify-end group">
                  <span className="text-[9px] font-mono text-primary opacity-0 group-hover:opacity-100 transition-opacity">{lh.latencyMs}ms</span>
                  <div 
                    className="w-full bg-primary/20 hover:bg-primary rounded-t transition-all cursor-pointer" 
                    style={{ height: `${heightPct}%` }}
                  />
                  <span className="text-[10px] text-muted-foreground font-mono">{lh.day}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* SYSTEM HEALTH AND CAPABILITIES */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-6">
          <span className="text-xs font-bold text-white uppercase tracking-wider border-b border-white/5 pb-2">Telemetry Health</span>

          <div className="flex flex-col gap-4 text-xs font-mono text-muted-foreground">
            <div className="flex justify-between border-b border-white/[0.02] pb-2">
              <span>Status</span>
              <strong className="text-green-500 uppercase">{stats.systemHealth.status}</strong>
            </div>
            <div className="flex justify-between border-b border-white/[0.02] pb-2">
              <span>Telemetry CPU Load</span>
              <strong className="text-white">{stats.systemHealth.cpuLoadPercent}%</strong>
            </div>
            <div className="flex justify-between border-b border-white/[0.02] pb-2">
              <span>Telemetry RAM In-Use</span>
              <strong className="text-white">{stats.systemHealth.ramUsageGb} GB</strong>
            </div>
            <div className="flex justify-between border-b border-white/[0.02] pb-2">
              <span>Total CDN Egress</span>
              <strong className="text-white">{stats.systemHealth.totalEgressGb} GB</strong>
            </div>
            <div className="flex justify-between">
              <span>Error rate</span>
              <strong className="text-white">{(stats.systemHealth.errorRatePercent * 100).toFixed(2)}%</strong>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}
