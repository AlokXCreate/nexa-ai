'use client';

import React, { useState } from 'react';
import { 
  User, CreditCard, Sparkles, Check, 
  HelpCircle, AlertCircle, Save
} from 'lucide-react';
import { api } from '../../../lib/api';
import { useAppStore } from '../../../lib/store';

export default function SettingsPage() {
  const { user, token, setAuth } = useAppStore();

  // Profile forms
  const [firstName, setFirstName] = useState(user?.profile?.firstName || '');
  const [lastName, setLastName] = useState(user?.profile?.lastName || '');
  const [bio, setBio] = useState(user?.profile?.bio || '');
  const [saveStatus, setSaveStatus] = useState('');
  const [loading, setLoading] = useState(false);

  // Billing forms
  const [billingLoading, setBillingLoading] = useState(false);

  const handleProfileSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaveStatus('');
    setLoading(true);

    try {
      const res = await api.updateProfile({
        firstName,
        lastName,
        bio
      });

      // Update Zustand state
      if (user && token) {
        setAuth(token, {
          ...user,
          profile: {
            ...user.profile,
            ...res.profile
          }
        });
      }

      setSaveStatus('Profile saved successfully!');
    } catch (err: any) {
      setSaveStatus(err.message || 'Failed to update profile');
    } finally {
      setLoading(false);
    }
  };

  const handlePlanUpgrade = async (plan: 'FREE' | 'PRO' | 'ENTERPRISE') => {
    if (user?.subscriptionStatus === plan || billingLoading) return;

    setBillingLoading(true);
    try {
      const data = await api.upgradeSubscription(plan);
      if (token) {
        setAuth(token, data.user);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setBillingLoading(false);
    }
  };

  if (!user) return null;

  return (
    <div className="max-w-4xl mx-auto flex flex-col gap-6">
      
      <div>
        <h3 className="text-xl font-bold text-white">Settings & Profile</h3>
        <p className="text-xs text-muted-foreground mt-1">Configure user accounts, manage billing subscriptions and local backup options.</p>
      </div>

      <div className="grid md:grid-cols-3 gap-6 items-stretch">
        
        {/* PROFILE CARD */}
        <div className="md:col-span-2 glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-6 h-fit">
          <div className="flex items-center gap-2 border-b border-white/5 pb-2">
            <User className="w-4 h-4 text-primary" />
            <span className="text-xs font-bold text-white uppercase tracking-wider font-mono">User Details</span>
          </div>

          {saveStatus && (
            <div className={`p-3 rounded-lg text-xs text-center font-mono ${saveStatus.includes('success') ? 'bg-green-500/10 border border-green-500/20 text-green-400' : 'bg-red-500/10 border border-red-500/20 text-red-400'}`}>
              {saveStatus}
            </div>
          )}

          <form onSubmit={handleProfileSave} className="flex flex-col gap-4 text-xs">
            <div className="grid grid-cols-2 gap-4">
              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">First Name</label>
                <input 
                  type="text" 
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  placeholder="John"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <label className="font-semibold text-muted-foreground">Last Name</label>
                <input 
                  type="text" 
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  placeholder="Doe"
                  className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary"
                />
              </div>
            </div>

            <div className="flex flex-col gap-1.5">
              <label className="font-semibold text-muted-foreground">Biography / Status</label>
              <textarea 
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                placeholder="A bit about yourself..."
                rows={4}
                className="px-3 py-2.5 rounded border border-white/10 glass-input text-white outline-none focus:border-primary resize-none"
              />
            </div>

            <button 
              type="submit" 
              disabled={loading}
              className="px-4 py-2.5 bg-primary hover:bg-primary/90 text-white rounded-lg font-semibold flex items-center justify-center gap-2 transition-all shadow shadow-primary/10 disabled:opacity-50 mt-2"
            >
              <Save className="w-3.5 h-3.5" />
              {loading ? 'Saving details...' : 'Save Profile'}
            </button>
          </form>
        </div>

        {/* BILLING AND MEMBERSHIP PLANS */}
        <div className="glass-panel p-6 rounded-xl border border-white/5 flex flex-col gap-6">
          <div className="flex items-center gap-2 border-b border-white/5 pb-2">
            <CreditCard className="w-4 h-4 text-purple-400" />
            <span className="text-xs font-bold text-white uppercase tracking-wider font-mono">Billing & Membership</span>
          </div>

          <div className="flex flex-col gap-3">
            <div className="p-4 bg-white/[0.02] border border-white/5 rounded-lg flex flex-col gap-1">
              <span className="text-[10px] text-muted-foreground uppercase font-mono">ACTIVE LEVEL</span>
              <strong className="text-sm text-primary uppercase">{user.subscriptionStatus} MEMBER</strong>
            </div>

            <div className="flex flex-col gap-2.5 mt-2">
              <span className="text-[10px] text-muted-foreground uppercase font-mono">Modify Plan (Stripe Mock)</span>
              
              {/* Free Button */}
              <button 
                onClick={() => handlePlanUpgrade('FREE')}
                disabled={billingLoading || user.subscriptionStatus === 'FREE'}
                className={`w-full py-2.5 rounded-lg text-xs font-semibold border flex items-center justify-between px-3 ${
                  user.subscriptionStatus === 'FREE'
                    ? 'border-green-500/25 bg-green-500/5 text-green-400 cursor-default'
                    : 'border-white/10 bg-white/5 text-white hover:bg-white/10'
                }`}
              >
                <span>Free Plan</span>
                {user.subscriptionStatus === 'FREE' ? <Check className="w-4.5 h-4.5" /> : <span>$0</span>}
              </button>

              {/* Pro Button */}
              <button 
                onClick={() => handlePlanUpgrade('PRO')}
                disabled={billingLoading || user.subscriptionStatus === 'PRO'}
                className={`w-full py-2.5 rounded-lg text-xs font-semibold border flex items-center justify-between px-3 ${
                  user.subscriptionStatus === 'PRO'
                    ? 'border-green-500/25 bg-green-500/5 text-green-400 cursor-default'
                    : 'border-white/10 bg-white/5 text-white hover:bg-white/10'
                }`}
              >
                <span>Pro Membership</span>
                {user.subscriptionStatus === 'PRO' ? <Check className="w-4.5 h-4.5" /> : <span>$9.99/mo</span>}
              </button>

              {/* Enterprise Button */}
              <button 
                onClick={() => handlePlanUpgrade('ENTERPRISE')}
                disabled={billingLoading || user.subscriptionStatus === 'ENTERPRISE'}
                className={`w-full py-2.5 rounded-lg text-xs font-semibold border flex items-center justify-between px-3 ${
                  user.subscriptionStatus === 'ENTERPRISE'
                    ? 'border-green-500/25 bg-green-500/5 text-green-400 cursor-default'
                    : 'border-white/10 bg-white/5 text-white hover:bg-white/10'
                }`}
              >
                <span>Enterprise</span>
                {user.subscriptionStatus === 'ENTERPRISE' ? <Check className="w-4.5 h-4.5" /> : <span>$49.99/mo</span>}
              </button>
            </div>
          </div>
        </div>

      </div>

    </div>
  );
}
