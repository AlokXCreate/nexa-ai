const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

async function request(path: string, options: RequestInit = {}) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('nexa_token') : null;
  const headers = new Headers(options.headers || {});

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  if (options.body && !(options.body instanceof FormData)) {
    headers.set('Content-Type', 'application/json');
  }

  const res = await fetch(`${API_URL}${path}`, {
    ...options,
    headers
  });

  if (!res.ok) {
    const errData = await res.json().catch(() => ({}));
    throw new Error(errData.error || 'API Request failed');
  }

  return res.json();
}

export const api = {
  // Auth
  signup: (body: any) => request('/auth/signup', { method: 'POST', body: JSON.stringify(body) }),
  login: (body: any) => request('/auth/login', { method: 'POST', body: JSON.stringify(body) }),
  getMe: () => request('/auth/me'),
  updateProfile: (body: any) => request('/auth/profile', { method: 'PUT', body: JSON.stringify(body) }),
  upgradeSubscription: (plan: string) => request('/auth/upgrade', { method: 'POST', body: JSON.stringify({ plan }) }),

  // Chat Sessions
  getSessions: (folder?: string) => request(`/chat/sessions${folder ? `?folder=${folder}` : ''}`),
  createSession: (body: any) => request('/chat/sessions', { method: 'POST', body: JSON.stringify(body) }),
  deleteSession: (id: string) => request(`/chat/sessions/${id}`, { method: 'DELETE' }),
  getSessionMessages: (id: string) => request(`/chat/sessions/${id}/messages`),

  // Marketplace
  getModelCatalog: () => request('/marketplace/catalog'),
  getInstalledModels: () => request('/marketplace/installed'),
  downloadModel: (modelId: string) => request('/marketplace/download', { method: 'POST', body: JSON.stringify({ modelId }) }),

  // Optimizer
  profileHardware: (body: any) => request('/optimizer/profile', { method: 'POST', body: JSON.stringify(body) }),
  getDeviceProfile: () => request('/optimizer/profile'),

  // Plugins
  getPlugins: () => request('/plugins'),
  togglePlugin: (id: string, active: boolean) => request(`/plugins/${id}/toggle`, { method: 'PUT', body: JSON.stringify({ active }) }),
  registerPlugin: (body: any) => request('/plugins', { method: 'POST', body: JSON.stringify(body) }),

  // Admin
  getAdminStats: () => request('/admin/stats')
};
