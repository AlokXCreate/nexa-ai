'use client';

import React, { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { 
  Bot, MessageSquare, ShoppingBag, FolderArchive, 
  Gauge, Blocks, ShieldAlert, Settings, LogOut, Menu, Bell
} from 'lucide-react';
import { useAppStore } from '../../lib/store';
import { api } from '../../lib/api';

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { token, user, setAuth, logout, theme, toggleTheme } = useAppStore();
  const [mounted, setMounted] = useState(false);
  const [showNotifications, setShowNotifications] = useState(false);
  const [notifications, setNotifications] = useState([
    { id: 1, title: "Model Download Complete", content: "Llama 3 (3B) has been successfully verified locally.", type: "INFO", read: false },
    { id: 2, title: "Hardware Alert", content: "High RAM pressure detected. Consider swapping to a 2B parameter profile.", type: "WARNING", read: false }
  ]);

  useEffect(() => {
    setMounted(true);
    if (!token) {
      router.push('/auth');
    } else {
      // Sync user profile state from API on load
      api.getMe().then(data => {
        setAuth(token, data.user);
      }).catch(() => {
        // Token expired or invalid
        logout();
        router.push('/auth');
      });
    }
  }, [token, router, setAuth, logout]);

  if (!mounted || !token || !user) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 rounded-xl bg-primary flex items-center justify-center animate-bounce">
            <Bot className="w-7 h-7 text-white" />
          </div>
          <span className="text-sm text-muted-foreground font-mono">Authenticating session...</span>
        </div>
      </div>
    );
  }

  const navItems = [
    { name: 'Chat Workspace', path: '/dashboard/chat', icon: MessageSquare },
    { name: 'Model Marketplace', path: '/dashboard/marketplace', icon: ShoppingBag },
    { name: 'Local RAG (Files)', path: '/dashboard/rag', icon: FolderArchive },
    { name: 'Hardware Optimizer', path: '/dashboard/optimizer', icon: Gauge },
    { name: 'Plugins & Addons', path: '/dashboard/plugins', icon: Blocks },
    ...(user.role === 'ADMIN' ? [{ name: 'Admin Console', path: '/dashboard/admin', icon: ShieldAlert }] : []),
    { name: 'Settings & Profile', path: '/dashboard/settings', icon: Settings }
  ];

  const unreadCount = notifications.filter(n => !n.read).length;

  return (
    <div className="min-h-screen flex bg-background text-foreground overflow-hidden">
      
      {/* SIDEBAR */}
      <aside className="w-64 border-r border-white/5 bg-black/40 flex flex-col shrink-0">
        <div className="p-6 flex items-center gap-3 border-b border-white/5">
          <Link href="/" className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center shadow-lg shadow-primary/20">
            <Bot className="w-6 h-6 text-white" />
          </Link>
          <div className="flex flex-col">
            <span className="font-bold tracking-tight text-white leading-tight">Nexa AI</span>
            <span className="text-[10px] text-primary font-mono tracking-widest font-semibold uppercase">{user.subscriptionStatus} MEMBER</span>
          </div>
        </div>

        <nav className="flex-1 p-4 flex flex-col gap-1.5 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = pathname === item.path;
            return (
              <Link
                key={item.path}
                href={item.path}
                className={`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all ${
                  isActive 
                    ? 'bg-primary text-white shadow-lg shadow-primary/10' 
                    : 'text-muted-foreground hover:bg-white/5 hover:text-white'
                }`}
              >
                <Icon className="w-4 h-4 shrink-0" />
                {item.name}
              </Link>
            );
          })}
        </nav>

        {/* User Card */}
        <div className="p-4 border-t border-white/5 bg-white/[0.01] flex items-center justify-between gap-3">
          <div className="flex items-center gap-3 overflow-hidden">
            <img 
              src={user.profile?.avatarUrl || `https://api.dicebear.com/7.x/bottts/svg?seed=${user.email}`} 
              alt="Avatar" 
              className="w-10 h-10 rounded-lg bg-white/5 border border-white/10 shrink-0"
            />
            <div className="flex flex-col overflow-hidden">
              <span className="text-xs font-semibold text-white truncate">
                {user.profile?.firstName ? `${user.profile.firstName} ${user.profile.lastName || ''}` : user.email.split('@')[0]}
              </span>
              <span className="text-[10px] text-muted-foreground truncate">{user.email}</span>
            </div>
          </div>
          <button 
            onClick={() => { logout(); router.push('/'); }}
            className="p-2 rounded-lg hover:bg-red-500/10 hover:text-red-400 text-muted-foreground transition-all shrink-0"
            title="Log Out"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </aside>

      {/* MAIN CONTENT AREA */}
      <div className="flex-1 flex flex-col min-w-0 relative">
        
        {/* HEADER BAR */}
        <header className="h-16 border-b border-white/5 bg-black/20 px-8 flex items-center justify-between shrink-0">
          <h2 className="text-lg font-bold text-white capitalize">
            {pathname.split('/').pop()?.replace('-', ' ') || 'Dashboard'}
          </h2>

          <div className="flex items-center gap-4">
            <button 
              onClick={toggleTheme} 
              className="p-2 rounded-lg hover:bg-white/5 transition-colors border border-white/5 text-sm"
            >
              {theme === 'dark' ? '☀️' : '🌙'}
            </button>

            {/* Notifications Menu */}
            <div className="relative">
              <button 
                onClick={() => setShowNotifications(!showNotifications)}
                className="p-2 rounded-lg hover:bg-white/5 transition-colors border border-white/5 relative"
              >
                <Bell className="w-4 h-4 text-muted-foreground hover:text-white" />
                {unreadCount > 0 && (
                  <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-primary animate-pulse" />
                )}
              </button>

              {showNotifications && (
                <div className="absolute right-0 mt-2 w-80 glass-panel border border-white/10 rounded-xl shadow-2xl p-4 flex flex-col gap-3 z-50">
                  <div className="flex justify-between items-center border-b border-white/5 pb-2">
                    <span className="text-xs font-bold text-white">Notifications</span>
                    <button 
                      onClick={() => setNotifications(notifications.map(n => ({ ...n, read: true })))}
                      className="text-[10px] text-primary hover:underline font-semibold"
                    >
                      Mark all read
                    </button>
                  </div>
                  <div className="flex flex-col gap-2 max-h-60 overflow-y-auto">
                    {notifications.map(n => (
                      <div key={n.id} className={`p-2.5 rounded-lg border text-xs flex flex-col gap-1 ${n.read ? 'bg-transparent border-white/5 text-muted-foreground' : 'bg-primary/5 border-primary/20 text-white'}`}>
                        <span className="font-semibold">{n.title}</span>
                        <span className="text-[10px] leading-normal">{n.content}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>
        </header>

        {/* CONTAINER FOR INNER ROUTES */}
        <main className="flex-1 overflow-y-auto p-8 bg-[radial-gradient(ellipse_at_bottom_left,_var(--tw-gradient-stops))] from-white/[0.02] via-transparent to-transparent">
          {children}
        </main>
      </div>

    </div>
  );
}
