import { create } from 'zustand';

interface User {
  id: string;
  email: string;
  role: string;
  subscriptionStatus: 'FREE' | 'PRO' | 'ENTERPRISE';
  profile?: {
    firstName?: string;
    lastName?: string;
    avatarUrl?: string;
    bio?: string;
  };
}

interface AppState {
  token: string | null;
  user: User | null;
  theme: 'dark' | 'light';
  currentSessionId: string | null;
  isSidebarOpen: boolean;
  
  // Actions
  setAuth: (token: string | null, user: User | null) => void;
  toggleTheme: () => void;
  setTheme: (theme: 'dark' | 'light') => void;
  setCurrentSessionId: (id: string | null) => void;
  toggleSidebar: () => void;
  logout: () => void;
}

export const useAppStore = create<AppState>((set) => {
  // Safe window/localStorage access
  const initialToken = typeof window !== 'undefined' ? localStorage.getItem('nexa_token') : null;
  const initialUser = typeof window !== 'undefined' ? JSON.parse(localStorage.getItem('nexa_user') || 'null') : null;
  const initialTheme = typeof window !== 'undefined' ? (localStorage.getItem('nexa_theme') as 'dark' | 'light' || 'dark') : 'dark';

  return {
    token: initialToken,
    user: initialUser,
    theme: initialTheme,
    currentSessionId: null,
    isSidebarOpen: true,

    setAuth: (token, user) => set(() => {
      if (typeof window !== 'undefined') {
        if (token) localStorage.setItem('nexa_token', token);
        else localStorage.removeItem('nexa_token');
        if (user) localStorage.setItem('nexa_user', JSON.stringify(user));
        else localStorage.removeItem('nexa_user');
      }
      return { token, user };
    }),

    toggleTheme: () => set((state) => {
      const nextTheme = state.theme === 'dark' ? 'light' : 'dark';
      if (typeof window !== 'undefined') {
        localStorage.setItem('nexa_theme', nextTheme);
        document.documentElement.classList.toggle('dark', nextTheme === 'dark');
      }
      return { theme: nextTheme };
    }),

    setTheme: (theme) => set(() => {
      if (typeof window !== 'undefined') {
        localStorage.setItem('nexa_theme', theme);
        document.documentElement.classList.toggle('dark', theme === 'dark');
      }
      return { theme };
    }),

    setCurrentSessionId: (id) => set({ currentSessionId: id }),
    toggleSidebar: () => set((state) => ({ isSidebarOpen: !state.isSidebarOpen })),

    logout: () => set(() => {
      if (typeof window !== 'undefined') {
        localStorage.removeItem('nexa_token');
        localStorage.removeItem('nexa_user');
      }
      return { token: null, user: null, currentSessionId: null };
    }),
  };
});
