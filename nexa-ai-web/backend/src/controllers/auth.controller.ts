import { Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../db';
import { AuthRequest } from '../middleware/auth.middleware';

const JWT_SECRET = process.env.JWT_SECRET || 'nexa-secret-key-change-in-prod';

export async function signup(req: AuthRequest, res: Response) {
  try {
    const { email, password, firstName, lastName } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const existingUser = await prisma.user.findUnique({ where: { email } });
    if (existingUser) {
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    
    // Determine role (make the first user an admin for testing convenience)
    const count = await prisma.user.count();
    const role = count === 0 ? 'ADMIN' : 'USER';

    const user = await prisma.user.create({
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

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

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
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Error creating user' });
  }
}

export async function login(req: AuthRequest, res: Response) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    const user = await prisma.user.findUnique({
      where: { email },
      include: { profile: true }
    });

    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

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
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Error logging in' });
  }
}

export async function getMe(req: AuthRequest, res: Response) {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const user = await prisma.user.findUnique({
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
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Error fetching profile' });
  }
}

export async function updateProfile(req: AuthRequest, res: Response) {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { firstName, lastName, bio, avatarUrl } = req.body;

    const updated = await prisma.profile.update({
      where: { userId: req.user.id },
      data: {
        firstName,
        lastName,
        bio,
        avatarUrl
      }
    });

    return res.json({ profile: updated });
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Error updating profile' });
  }
}

export async function upgradeSubscription(req: AuthRequest, res: Response) {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const { plan } = req.body;
    if (plan !== 'PRO' && plan !== 'ENTERPRISE' && plan !== 'FREE') {
      return res.status(400).json({ error: 'Invalid subscription status' });
    }

    const updated = await prisma.user.update({
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
      await prisma.payment.create({
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
  } catch (err: any) {
    return res.status(500).json({ error: err.message || 'Error updating subscription' });
  }
}
