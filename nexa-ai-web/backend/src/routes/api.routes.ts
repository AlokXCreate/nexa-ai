import { Router } from 'express';
import { signup, login, getMe, updateProfile, upgradeSubscription } from '../controllers/auth.controller';
import { getSessions, createSession, deleteSession, getSessionMessages, sendMessageStream } from '../controllers/chat.controller';
import { getModelCatalog, getInstalledModels, simulateModelDownload } from '../controllers/marketplace.controller';
import { profileHardware, getDeviceProfile } from '../controllers/optimizer.controller';
import { getPlugins, togglePlugin, registerCustomPlugin } from '../controllers/plugin.controller';
import { getAdminStats } from '../controllers/admin.controller';
import { requireAuth, requireAdmin } from '../middleware/auth.middleware';

const router = Router();

// --- AUTHENTICATION ROUTES ---
router.post('/auth/signup', signup);
router.post('/auth/login', login);
router.get('/auth/me', requireAuth, getMe);
router.put('/auth/profile', requireAuth, updateProfile);
router.post('/auth/upgrade', requireAuth, upgradeSubscription);

// --- CHAT ROUTES ---
router.get('/chat/sessions', requireAuth, getSessions);
router.post('/chat/sessions', requireAuth, createSession);
router.delete('/chat/sessions/:id', requireAuth, deleteSession);
router.get('/chat/sessions/:id/messages', requireAuth, getSessionMessages);
router.post('/chat/messages/stream', requireAuth, sendMessageStream);

// --- MARKETPLACE ROUTES ---
router.get('/marketplace/catalog', requireAuth, getModelCatalog);
router.get('/marketplace/installed', requireAuth, getInstalledModels);
router.post('/marketplace/download', requireAuth, simulateModelDownload);

// --- OPTIMIZER ROUTES ---
router.post('/optimizer/profile', requireAuth, profileHardware);
router.get('/optimizer/profile', requireAuth, getDeviceProfile);

// --- PLUGINS ROUTES ---
router.get('/plugins', requireAuth, getPlugins);
router.put('/plugins/:id/toggle', requireAuth, togglePlugin);
router.post('/plugins', requireAuth, registerCustomPlugin);

// --- ADMIN ROUTES ---
router.get('/admin/stats', requireAdmin, getAdminStats);

export default router;
