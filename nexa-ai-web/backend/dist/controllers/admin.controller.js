"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAdminStats = getAdminStats;
const db_1 = __importDefault(require("../db"));
async function getAdminStats(req, res) {
    try {
        const totalUsers = await db_1.default.user.count();
        const premiumUsers = await db_1.default.user.count({ where: { subscriptionStatus: { in: ['PRO', 'ENTERPRISE'] } } });
        const totalSessions = await db_1.default.chatSession.count();
        const totalMessages = await db_1.default.chatMessage.count();
        const totalPayments = await db_1.default.payment.aggregate({ _sum: { amount: true } });
        // Average speeds and latencies
        const avgStats = await db_1.default.chatMessage.aggregate({
            _avg: {
                tokensPerSecond: true,
                inferenceTimeMs: true
            },
            where: {
                role: 'ASSISTANT'
            }
        });
        // Subscriptions count breakdown
        const freeCount = await db_1.default.user.count({ where: { subscriptionStatus: 'FREE' } });
        const proCount = await db_1.default.user.count({ where: { subscriptionStatus: 'PRO' } });
        const enterpriseCount = await db_1.default.user.count({ where: { subscriptionStatus: 'ENTERPRISE' } });
        // Mock telemetry server load metrics
        const systemHealth = {
            cpuLoadPercent: 12.5,
            ramUsageGb: 3.4,
            totalEgressGb: 142.8,
            status: "HEALTHY",
            errorRatePercent: 0.02
        };
        // Latency trends (simulating 7 days)
        const latencyHistory = [
            { day: "Mon", latencyMs: 120 },
            { day: "Tue", latencyMs: 115 },
            { day: "Wed", latencyMs: 140 },
            { day: "Thu", latencyMs: 125 },
            { day: "Fri", latencyMs: 110 },
            { day: "Sat", latencyMs: 95 },
            { day: "Sun", latencyMs: 100 }
        ];
        return res.json({
            metrics: {
                totalUsers,
                premiumUsers,
                totalSessions,
                totalMessages,
                totalRevenue: totalPayments._sum.amount || 0,
                averageTokensPerSecond: avgStats._avg.tokensPerSecond || 32.5,
                averageLatencyMs: avgStats._avg.inferenceTimeMs || 120
            },
            subscriptions: {
                FREE: freeCount,
                PRO: proCount,
                ENTERPRISE: enterpriseCount
            },
            systemHealth,
            latencyHistory
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
