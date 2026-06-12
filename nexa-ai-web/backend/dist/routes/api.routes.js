"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_controller_1 = require("../controllers/auth.controller");
const chat_controller_1 = require("../controllers/chat.controller");
const marketplace_controller_1 = require("../controllers/marketplace.controller");
const optimizer_controller_1 = require("../controllers/optimizer.controller");
const plugin_controller_1 = require("../controllers/plugin.controller");
const admin_controller_1 = require("../controllers/admin.controller");
const auth_middleware_1 = require("../middleware/auth.middleware");
const router = (0, express_1.Router)();
// --- AUTHENTICATION ROUTES ---
router.post('/auth/signup', auth_controller_1.signup);
router.post('/auth/login', auth_controller_1.login);
router.get('/auth/me', auth_middleware_1.requireAuth, auth_controller_1.getMe);
router.put('/auth/profile', auth_middleware_1.requireAuth, auth_controller_1.updateProfile);
router.post('/auth/upgrade', auth_middleware_1.requireAuth, auth_controller_1.upgradeSubscription);
// --- CHAT ROUTES ---
router.get('/chat/sessions', auth_middleware_1.requireAuth, chat_controller_1.getSessions);
router.post('/chat/sessions', auth_middleware_1.requireAuth, chat_controller_1.createSession);
router.delete('/chat/sessions/:id', auth_middleware_1.requireAuth, chat_controller_1.deleteSession);
router.get('/chat/sessions/:id/messages', auth_middleware_1.requireAuth, chat_controller_1.getSessionMessages);
router.post('/chat/messages/stream', auth_middleware_1.requireAuth, chat_controller_1.sendMessageStream);
// --- MARKETPLACE ROUTES ---
router.get('/marketplace/catalog', auth_middleware_1.requireAuth, marketplace_controller_1.getModelCatalog);
router.get('/marketplace/installed', auth_middleware_1.requireAuth, marketplace_controller_1.getInstalledModels);
router.post('/marketplace/download', auth_middleware_1.requireAuth, marketplace_controller_1.simulateModelDownload);
// --- OPTIMIZER ROUTES ---
router.post('/optimizer/profile', auth_middleware_1.requireAuth, optimizer_controller_1.profileHardware);
router.get('/optimizer/profile', auth_middleware_1.requireAuth, optimizer_controller_1.getDeviceProfile);
// --- PLUGINS ROUTES ---
router.get('/plugins', auth_middleware_1.requireAuth, plugin_controller_1.getPlugins);
router.put('/plugins/:id/toggle', auth_middleware_1.requireAuth, plugin_controller_1.togglePlugin);
router.post('/plugins', auth_middleware_1.requireAuth, plugin_controller_1.registerCustomPlugin);
// --- ADMIN ROUTES ---
router.get('/admin/stats', auth_middleware_1.requireAdmin, admin_controller_1.getAdminStats);
exports.default = router;
