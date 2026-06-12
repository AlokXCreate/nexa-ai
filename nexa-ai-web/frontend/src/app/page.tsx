'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { 
  Bot, ShieldCheck, Zap, HardDrive, Cpu, Layers, 
  ArrowRight, Check, HelpCircle, ArrowUpRight
} from 'lucide-react';
import { useAppStore } from '../lib/store';

export default function LandingPage() {
  const { token, theme, toggleTheme } = useAppStore();
  const [billingPeriod, setBillingPeriod] = useState<'monthly' | 'yearly'>('monthly');

  // Interactive Demo State
  const [demoInput, setDemoInput] = useState('');
  const [demoOutput, setDemoOutput] = useState('Type a message to test local processing speed simulation...');
  const [demoSpeed, setDemoSpeed] = useState(0);
  const [demoLatency, setDemoLatency] = useState(0);

  const runDemo = (e: React.FormEvent) => {
    e.preventDefault();
    if (!demoInput.trim()) return;

    setDemoOutput("Simulating token streams locally...");
    let speed = 48.2 + Math.random() * 5;
    let latency = 85 + Math.floor(Math.random() * 20);

    setTimeout(() => {
      setDemoSpeed(speed);
      setDemoLatency(latency);
      setDemoOutput(`[Local LLM Response]: Checked vector store index. 3 document chunks matched. Prompt context updated. Responding at ${speed.toFixed(1)} tokens/sec with ${latency}ms first-token delay!`);
    }, 800);
  };

  const faqs = [
    {
      q: "How does Nexa AI run models locally on my browser?",
      a: "Nexa AI leverages WebGPU and WebAssembly (WASM) to load quantized GGUF weights directly into your browser's execution memory thread. This processes all queries offline without transmitting your chats to remote servers."
    },
    {
      q: "What are the hardware requirements?",
      a: "For smaller 2B parameter models, any laptop with 8GB RAM and an integrated GPU is sufficient. For larger 7B/8B models, we recommend at least 16GB RAM and a dedicated graphics processor (NVIDIA, Apple Silicon M-series, or AMD)."
    },
    {
      q: "Can I sync my chats across my phone and website?",
      a: "Yes! Nexa AI supports local-first synchronization. By linking your Google Drive or custom database backup, your data is securely synced between the mobile application and the desktop web portal."
    }
  ];

  return (
    <div className="min-h-screen flex flex-col bg-background text-foreground bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-primary/10 via-background to-background">
      
      {/* HEADER */}
      <header className="sticky top-0 z-50 w-full glass-panel border-b border-white/5 px-6 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20">
            <Bot className="w-6 h-6 text-white" />
          </div>
          <span className="text-xl font-bold tracking-tight bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">Nexa AI</span>
        </div>

        <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-muted-foreground">
          <a href="#features" className="hover:text-foreground transition-colors">Features</a>
          <a href="#demo" className="hover:text-foreground transition-colors">Interactive Demo</a>
          <a href="#pricing" className="hover:text-foreground transition-colors">Pricing</a>
          <a href="#faq" className="hover:text-foreground transition-colors">FAQ</a>
        </nav>

        <div className="flex items-center gap-4">
          <button 
            onClick={toggleTheme} 
            className="p-2 rounded-lg hover:bg-white/5 transition-colors border border-white/10"
            aria-label="Toggle Dark/Light Mode"
          >
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>
          
          <Link 
            href={token ? "/dashboard/chat" : "/auth"} 
            className="px-5 py-2.5 rounded-lg bg-primary hover:bg-primary/90 text-white font-medium text-sm flex items-center gap-2 transition-all shadow-lg shadow-primary/10"
          >
            {token ? 'Go to Dashboard' : 'Sign In'}
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </header>

      {/* HERO SECTION */}
      <section className="flex-1 max-w-7xl mx-auto px-6 py-20 md:py-32 grid md:grid-cols-2 gap-12 items-center">
        <div className="flex flex-col gap-6">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/15 border border-primary/20 text-xs font-semibold text-primary w-fit">
            <ShieldCheck className="w-4 h-4" /> GDPR & HIPAA Compliant Private AI
          </div>
          <h1 className="text-4xl md:text-6xl font-extrabold tracking-tight leading-tight">
            Private. Edge-First.<br />
            <span className="bg-gradient-to-r from-primary via-purple-400 to-pink-500 bg-clip-text text-transparent">
              Local AI Engine.
            </span>
          </h1>
          <p className="text-lg text-muted-foreground leading-relaxed">
            Run lightweight LLMs, voice transcriptions, and document indexing locally on your web browser or device. Absolute data privacy with zero server hosting costs.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 mt-4">
            <Link 
              href="/auth" 
              className="px-8 py-4 rounded-xl bg-primary hover:bg-primary/90 text-white font-semibold text-center flex items-center justify-center gap-2 transition-all shadow-xl shadow-primary/20"
            >
              Start Free Trial
              <ArrowRight className="w-5 h-5" />
            </Link>
            <a 
              href="#demo"
              className="px-8 py-4 rounded-xl border border-white/10 bg-white/5 hover:bg-white/10 text-foreground font-semibold text-center transition-all"
            >
              Try Simulator
            </a>
          </div>
        </div>

        <div className="relative flex justify-center">
          {/* Glassmorphic Tech Stats Panel */}
          <div className="w-full max-w-md glass-panel p-8 rounded-3xl flex flex-col gap-6 shadow-2xl relative overflow-hidden animate-float">
            <div className="absolute -right-10 -top-10 w-40 h-40 bg-primary/25 rounded-full blur-3xl" />
            
            <div className="flex justify-between items-center border-b border-white/5 pb-4">
              <span className="font-semibold text-muted-foreground text-sm">ACTIVE LOCAL ENGINE</span>
              <span className="px-2 py-0.5 rounded bg-green-500/10 text-green-500 text-xs font-mono">ONLINE</span>
            </div>

            <div className="grid grid-cols-2 gap-6">
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground uppercase font-mono">Generation Speed</span>
                <span className="text-3xl font-bold font-mono tracking-tight text-primary">48.2 <span className="text-sm font-normal">T/s</span></span>
              </div>
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground uppercase font-mono">First Token Delay</span>
                <span className="text-3xl font-bold font-mono tracking-tight text-white">85 <span className="text-sm font-normal">ms</span></span>
              </div>
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground uppercase font-mono">RAM Overhead</span>
                <span className="text-3xl font-bold font-mono tracking-tight text-purple-400">2.1 <span className="text-sm font-normal">GB</span></span>
              </div>
              <div className="flex flex-col gap-1">
                <span className="text-xs text-muted-foreground uppercase font-mono">Local Embeddings</span>
                <span className="text-3xl font-bold font-mono tracking-tight text-pink-400">1,500 <span className="text-sm font-normal">dim</span></span>
              </div>
            </div>

            <div className="flex flex-col gap-2 bg-white/5 p-4 rounded-xl border border-white/5">
              <div className="flex justify-between text-xs font-mono text-muted-foreground">
                <span>CPU Load</span>
                <span>12.5%</span>
              </div>
              <div className="w-full bg-white/10 h-1.5 rounded-full overflow-hidden">
                <div className="bg-primary h-full rounded-full" style={{ width: '12.5%' }} />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* CORE FEATURES SECTION */}
      <section id="features" className="py-24 border-t border-white/5 bg-black/20">
        <div className="max-w-7xl mx-auto px-6 flex flex-col gap-16">
          <div className="text-center flex flex-col gap-4 max-w-2xl mx-auto">
            <h2 className="text-3xl md:text-4xl font-extrabold tracking-tight">Core Edge Optimization Features</h2>
            <p className="text-muted-foreground">Nexa AI bundles everything you need to execute, optimize, and customize AI intelligence securely client-side.</p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-4 border border-white/5 hover:border-primary/30 transition-all">
              <div className="w-12 h-12 rounded-lg bg-primary/20 flex items-center justify-center text-primary">
                <HardDrive className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold">Local RAG Knowledge Base</h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Index PDFs and text documents on your local browser. Document chunking, indexing, and vector similarity comparisons are completed without cloud dependencies.
              </p>
            </div>

            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-4 border border-white/5 hover:border-purple-500/30 transition-all">
              <div className="w-12 h-12 rounded-lg bg-purple-500/20 flex items-center justify-center text-purple-400">
                <Layers className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold">Side-by-Side Comparison</h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Compare local responses from Llama 3, Phi-3, and Gemma side-by-side. Inspect latency, token speeds, and context parameters in real-time.
              </p>
            </div>

            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-4 border border-white/5 hover:border-pink-500/30 transition-all">
              <div className="w-12 h-12 rounded-lg bg-pink-500/20 flex items-center justify-center text-pink-400">
                <Cpu className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold">Hardware Device Profiler</h3>
              <p className="text-muted-foreground text-sm leading-relaxed">
                Scan device RAM, GPU capabilities, and OS kernels. Receive direct recommendations for optimal model downloads to avoid system jank and OOM errors.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* INTERACTIVE SIMULATOR SECTION */}
      <section id="demo" className="py-24 border-t border-white/5">
        <div className="max-w-4xl mx-auto px-6 flex flex-col gap-12">
          <div className="text-center flex flex-col gap-4">
            <h2 className="text-3xl font-bold">Interactive Generation Simulator</h2>
            <p className="text-muted-foreground text-sm">Experience the generation latency and vector retrieval speeds of our edge architecture.</p>
          </div>

          <div className="glass-panel rounded-2xl overflow-hidden border border-white/10 shadow-xl">
            <div className="bg-white/5 px-6 py-4 flex items-center justify-between border-b border-white/5 text-sm">
              <div className="flex items-center gap-2 font-mono text-muted-foreground">
                <span className="w-2.5 h-2.5 rounded-full bg-green-500 animate-pulse" />
                <span>llama-3-3b.gguf</span>
              </div>
              <div className="flex gap-4 font-mono text-xs text-muted-foreground">
                <span>Speed: <strong className="text-primary">{demoSpeed > 0 ? `${demoSpeed.toFixed(1)} T/s` : '0 T/s'}</strong></span>
                <span>Latency: <strong className="text-white">{demoLatency > 0 ? `${demoLatency}ms` : '0ms'}</strong></span>
              </div>
            </div>

            <div className="p-6 flex flex-col gap-4">
              <div className="bg-black/30 p-4 rounded-xl min-h-[120px] font-mono text-sm leading-relaxed whitespace-pre-wrap border border-white/5">
                {demoOutput}
              </div>

              <form onSubmit={runDemo} className="flex gap-3">
                <input 
                  type="text" 
                  value={demoInput}
                  onChange={(e) => setDemoInput(e.target.value)}
                  placeholder="Ask the simulator (e.g. Run benchmark, load RAG file)..."
                  className="flex-1 px-4 py-3 rounded-lg glass-input border border-white/10 focus:outline-none focus:border-primary text-sm"
                />
                <button 
                  type="submit" 
                  className="px-6 py-3 bg-primary hover:bg-primary/90 text-white rounded-lg text-sm font-semibold transition-all"
                >
                  Generate
                </button>
              </form>
            </div>
          </div>
        </div>
      </section>

      {/* PRICING SECTION */}
      <section id="pricing" className="py-24 border-t border-white/5 bg-black/10">
        <div className="max-w-7xl mx-auto px-6 flex flex-col gap-12">
          <div className="text-center flex flex-col gap-4 max-w-xl mx-auto">
            <h2 className="text-3xl font-bold">Predictable Pricing for Everyone</h2>
            <p className="text-muted-foreground">Absolutely zero server surcharge fees for local model compilation, ever.</p>
            
            <div className="flex items-center justify-center gap-4 mt-4 bg-white/5 p-1 rounded-full w-fit mx-auto border border-white/5">
              <button 
                onClick={() => setBillingPeriod('monthly')}
                className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${billingPeriod === 'monthly' ? 'bg-primary text-white shadow' : 'text-muted-foreground'}`}
              >
                Monthly
              </button>
              <button 
                onClick={() => setBillingPeriod('yearly')}
                className={`px-4 py-1.5 rounded-full text-xs font-semibold transition-all ${billingPeriod === 'yearly' ? 'bg-primary text-white shadow' : 'text-muted-foreground'}`}
              >
                Yearly (Save 20%)
              </button>
            </div>
          </div>

          <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto w-full items-stretch">
            {/* Free */}
            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-6 border border-white/5">
              <div>
                <h3 className="text-lg font-bold">Standard Free</h3>
                <span className="text-4xl font-extrabold font-mono mt-2 block">$0</span>
                <span className="text-xs text-muted-foreground">Free forever</span>
              </div>
              <ul className="flex flex-col gap-3 text-sm text-muted-foreground flex-1">
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Local models up to 3B parameters</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Standard chat history</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Basic hardware profiling</li>
              </ul>
              <Link href="/auth" className="w-full py-3 rounded-lg border border-white/10 hover:bg-white/5 text-center font-semibold text-sm transition-all">
                Get Started
              </Link>
            </div>

            {/* Pro */}
            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-6 border-2 border-primary relative">
              <span className="absolute -top-3 right-6 px-3 py-1 rounded-full bg-primary text-[10px] font-bold tracking-wider text-white">POPULAR</span>
              <div>
                <h3 className="text-lg font-bold text-white">Pro Developer</h3>
                <span className="text-4xl font-extrabold font-mono mt-2 block">
                  {billingPeriod === 'monthly' ? '$9.99' : '$7.99'}
                  <span className="text-sm font-normal text-muted-foreground">/mo</span>
                </span>
                <span className="text-xs text-primary font-semibold">Billed {billingPeriod}</span>
              </div>
              <ul className="flex flex-col gap-3 text-sm text-muted-foreground flex-1">
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Unlimited large models (7B+ params)</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Advanced Local RAG indexes</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Hardware profiling with acceleration</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Sync to Google Drive / Cloud API</li>
              </ul>
              <Link href="/auth" className="w-full py-3 rounded-lg bg-primary hover:bg-primary/90 text-white text-center font-semibold text-sm transition-all shadow-lg shadow-primary/20">
                Upgrade Now
              </Link>
            </div>

            {/* Enterprise */}
            <div className="glass-panel p-8 rounded-2xl flex flex-col gap-6 border border-white/5">
              <div>
                <h3 className="text-lg font-bold">Enterprise</h3>
                <span className="text-4xl font-extrabold font-mono mt-2 block">Custom</span>
                <span className="text-xs text-muted-foreground">For organizations</span>
              </div>
              <ul className="flex flex-col gap-3 text-sm text-muted-foreground flex-1">
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Custom private model loading</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Shared knowledge base RAG</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> SSO and Role Management</li>
                <li className="flex items-center gap-2"><Check className="w-4 h-4 text-green-500" /> Dedicated developer support</li>
              </ul>
              <a href="mailto:support@nexa.ai" className="w-full py-3 rounded-lg border border-white/10 hover:bg-white/5 text-center font-semibold text-sm transition-all">
                Contact Sales
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ SECTION */}
      <section id="faq" className="py-24 border-t border-white/5">
        <div className="max-w-3xl mx-auto px-6 flex flex-col gap-12">
          <div className="text-center flex flex-col gap-4">
            <h2 className="text-3xl font-bold">Frequently Asked Questions</h2>
            <p className="text-muted-foreground">Everything you need to know about Nexa AI's edge execution.</p>
          </div>

          <div className="flex flex-col gap-6">
            {faqs.map((faq, index) => (
              <div key={index} className="glass-panel p-6 rounded-xl border border-white/5 flex gap-4">
                <HelpCircle className="w-6 h-6 text-primary shrink-0" />
                <div className="flex flex-col gap-2">
                  <h4 className="font-bold text-white">{faq.q}</h4>
                  <p className="text-muted-foreground text-sm leading-relaxed">{faq.a}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* FOOTER */}
      <footer className="mt-auto border-t border-white/5 bg-black/40 px-8 py-12 text-sm text-muted-foreground">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-center gap-6">
          <div className="flex items-center gap-2">
            <Bot className="w-5 h-5 text-primary" />
            <span className="font-bold text-white">Nexa AI</span>
          </div>

          <div className="flex gap-8">
            <Link href="/terms" className="hover:text-foreground transition-colors">Terms of Service</Link>
            <Link href="/privacy" className="hover:text-foreground transition-colors">Privacy Policy</Link>
            <a href="mailto:support@nexa.ai" className="hover:text-foreground transition-colors">Support</a>
          </div>

          <div className="flex items-center gap-4">
            <a href="https://github.com/AlokXCreate/nexa-ai" target="_blank" rel="noreferrer" className="p-2 rounded-lg hover:bg-white/5 text-muted-foreground hover:text-white transition-colors" aria-label="GitHub Repository">
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/>
              </svg>
            </a>
            <span>© 2026 Nexa AI. All rights reserved.</span>
          </div>
        </div>
      </footer>

    </div>
  );
}
