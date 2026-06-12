"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.signup = signup;
exports.login = login;
exports.getMe = getMe;
exports.updateProfile = updateProfile;
exports.upgradeSubscription = upgradeSubscription;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const db_1 = __importDefault(require("../db"));
const JWT_SECRET = process.env.JWT_SECRET || 'nexa-secret-key-change-in-prod';
async function signup(req, res) {
    try {
        const { email, password, firstName, lastName } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }
        const existingUser = await db_1.default.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ error: 'User with this email already exists' });
        }
        const passwordHash = await bcryptjs_1.default.hash(password, 10);
        // Determine role (make the first user an admin for testing convenience)
        const count = await db_1.default.user.count();
        const role = count === 0 ? 'ADMIN' : 'USER';
        const user = await db_1.default.user.create({
            data: {
                email,
                passwordHash,
                role,
                profile: {
                    create: {
                        firstName,
                        lastName,
                        avatarUrl: `https://api.dicebear.com/7.x/bottts/svg?seed=${encodeURIComponent(email)}`,
                        bio: 'Welcome to Nexa AI!'
                    }
                }
            },
            include: {
                profile: true
            }
        });
        const token = jsonwebtoken_1.default.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        return res.status(201).json({
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                subscriptionStatus: user.subscriptionStatus,
                profile: user.profile
            }
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message || 'Error creating user' });
    }
}
async function login(req, res) {
    try {
        const { email, password } = req.body;
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required' });
        }
        const user = await db_1.default.user.findUnique({
            where: { email },
            include: { profile: true }
        });
        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        const isMatch = await bcryptjs_1.default.compare(password, user.passwordHash);
        if (!isMatch) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }
        const token = jsonwebtoken_1.default.sign({ id: user.id, email: user.email, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
        return res.json({
            token,
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                subscriptionStatus: user.subscriptionStatus,
                profile: user.profile
            }
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message || 'Error logging in' });
    }
}
async function getMe(req, res) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const user = await db_1.default.user.findUnique({
            where: { id: req.user.id },
            include: { profile: true }
        });
        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }
        return res.json({
            user: {
                id: user.id,
                email: user.email,
                role: user.role,
                subscriptionStatus: user.subscriptionStatus,
                profile: user.profile
            }
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message || 'Error fetching profile' });
    }
}
async function updateProfile(req, res) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const { firstName, lastName, bio, avatarUrl } = req.body;
        const updated = await db_1.default.profile.update({
            where: { userId: req.user.id },
            data: {
                firstName,
                lastName,
                bio,
                avatarUrl
            }
        });
        return res.json({ profile: updated });
    }
    catch (err) {
        return res.status(500).json({ error: err.message || 'Error updating profile' });
    }
}
async function upgradeSubscription(req, res) {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const { plan } = req.body;
        if (plan !== 'PRO' && plan !== 'ENTERPRISE' && plan !== 'FREE') {
            return res.status(400).json({ error: 'Invalid subscription status' });
        }
        const updated = await db_1.default.user.update({
            where: { id: req.user.id },
            data: {
                subscriptionStatus: plan
            },
            include: {
                profile: true
            }
        });
        // Save Mock Payment Record
        const amount = plan === 'PRO' ? 9.99 : plan === 'ENTERPRISE' ? 49.99 : 0;
        if (amount > 0) {
            await db_1.default.payment.create({
                data: {
                    userId: req.user.id,
                    transactionId: `mock-txn-${Date.now()}-${Math.random().toString(36).substring(7)}`,
                    amount,
                    status: 'COMPLETED',
                    provider: 'STRIPE'
                }
            });
        }
        return res.json({
            user: {
                id: updated.id,
                email: updated.email,
                role: updated.role,
                subscriptionStatus: updated.subscriptionStatus,
                profile: updated.profile
            }
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message || 'Error updating subscription' });
    }
}
