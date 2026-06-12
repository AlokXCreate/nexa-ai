'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Bot, Mail, Lock, User, ArrowRight } from 'lucide-react';
import { api } from '../../lib/api';
import { useAppStore } from '../../lib/store';

export default function AuthPage() {
  const router = useRouter();
  const setAuth = useAppStore((state) => state.setAuth);
  
  const [activeTab, setActiveTab] = useState<'login' | 'signup'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (activeTab === 'login') {
        const data = await api.login({ email, password });
        setAuth(data.token, data.user);
      } else {
        const data = await api.signup({ email, password, firstName, lastName });
        setAuth(data.token, data.user);
      }
      router.push('/dashboard/chat');
    } catch (err: any) {
      setError(err.message || 'Authentication failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/10 via-background to-background p-6">
      
      <div className="w-full max-w-md glass-panel p-8 rounded-2xl flex flex-col gap-6 shadow-2xl relative overflow-hidden border border-white/5">
        <div className="absolute -right-20 -top-20 w-48 h-48 bg-primary/20 rounded-full blur-3xl" />

        <div className="flex flex-col items-center gap-3 text-center">
          <Link href="/" className="w-12 h-12 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20 hover:scale-105 transition-all">
            <Bot className="w-7 h-7 text-white" />
          </Link>
          <div>
            <h2 className="text-2xl font-bold tracking-tight text-white">Welcome to Nexa AI</h2>
            <p className="text-muted-foreground text-xs mt-1">Manage private edge intelligence configurations</p>
          </div>
        </div>

        {/* Tab selector */}
        <div className="grid grid-cols-2 bg-white/5 p-1 rounded-lg border border-white/5">
          <button
            onClick={() => { setActiveTab('login'); setError(''); }}
            className={`py-2 rounded-md text-sm font-semibold transition-all ${activeTab === 'login' ? 'bg-primary text-white' : 'text-muted-foreground'}`}
          >
            Login
          </button>
          <button
            onClick={() => { setActiveTab('signup'); setError(''); }}
            className={`py-2 rounded-md text-sm font-semibold transition-all ${activeTab === 'signup' ? 'bg-primary text-white' : 'text-muted-foreground'}`}
          >
            Sign Up
          </button>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/20 text-red-400 text-xs p-3 rounded-lg text-center font-mono">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          {activeTab === 'signup' && (
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-muted-foreground">First Name</label>
                <div className="relative">
                  <User className="absolute left-3 top-3 w-4 h-4 text-muted-foreground" />
                  <input
                    type="text"
                    required
                    value={firstName}
                    onChange={(e) => setFirstName(e.target.value)}
                    placeholder="John"
                    className="w-full pl-9 pr-4 py-2.5 rounded-lg glass-input border border-white/10 text-sm focus:outline-none focus:border-primary text-white"
                  />
                </div>
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="text-xs font-semibold text-muted-foreground">Last Name</label>
                <div className="relative">
                  <User className="absolute left-3 top-3 w-4 h-4 text-muted-foreground" />
                  <input
                    type="text"
                    required
                    value={lastName}
                    onChange={(e) => setLastName(e.target.value)}
                    placeholder="Doe"
                    className="w-full pl-9 pr-4 py-2.5 rounded-lg glass-input border border-white/10 text-sm focus:outline-none focus:border-primary text-white"
                  />
                </div>
              </div>
            </div>
          )}

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-muted-foreground">Email Address</label>
            <div className="relative">
              <Mail className="absolute left-3 top-3.5 w-4 h-4 text-muted-foreground" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@domain.com"
                className="w-full pl-9 pr-4 py-2.5 rounded-lg glass-input border border-white/10 text-sm focus:outline-none focus:border-primary text-white"
              />
            </div>
          </div>

          <div className="flex flex-col gap-1.5">
            <label className="text-xs font-semibold text-muted-foreground">Password</label>
            <div className="relative">
              <Lock className="absolute left-3 top-3.5 w-4 h-4 text-muted-foreground" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-9 pr-4 py-2.5 rounded-lg glass-input border border-white/10 text-sm focus:outline-none focus:border-primary text-white"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 rounded-lg bg-primary hover:bg-primary/90 text-white font-semibold text-sm flex items-center justify-center gap-2 transition-all shadow-lg shadow-primary/20 disabled:opacity-50 mt-2"
          >
            {loading ? 'Processing...' : activeTab === 'login' ? 'Sign In' : 'Create Account'}
            <ArrowRight className="w-4 h-4" />
          </button>
        </form>

        <div className="text-center text-xs text-muted-foreground border-t border-white/5 pt-4">
          By continuing, you agree to our{' '}
          <Link href="/terms" className="text-primary hover:underline">
            Terms
          </Link>{' '}
          and{' '}
          <Link href="/privacy" className="text-primary hover:underline">
            Privacy Policy
          </Link>
          .
        </div>
      </div>
    </div>
  );
}
