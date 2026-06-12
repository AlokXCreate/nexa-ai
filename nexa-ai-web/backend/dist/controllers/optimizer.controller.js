"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.profileHardware = profileHardware;
exports.getDeviceProfile = getDeviceProfile;
const db_1 = __importDefault(require("../db"));
const marketplace_controller_1 = require("./marketplace.controller");
async function profileHardware(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { os, cpuCores, totalRamGb, gpuModel } = req.body;
        if (!os || !cpuCores || !totalRamGb) {
            return res.status(400).json({ error: 'OS, CPU cores, and total RAM are required' });
        }
        // Determine max supported size based on total RAM (leaves 4GB for OS/Browser)
        const availableRam = totalRamGb - 4.0;
        let maxSupportedModelSizeGb = 1.5; // Default safe limit (2B models)
        if (availableRam >= 8.0) {
            maxSupportedModelSizeGb = 6.0; // Can run 7B-8B quantized models
        }
        else if (availableRam >= 4.0) {
            maxSupportedModelSizeGb = 3.0; // Can run 3B-4B models
        }
        // Update or create device profile in database
        const profile = await db_1.default.deviceProfile.upsert({
            where: {
                id: (await db_1.default.deviceProfile.findFirst({ where: { userId: req.user.id } }))?.id || 'new-profile'
            },
            update: {
                os,
                cpuCores,
                totalRamGb,
                gpuModel,
                maxSupportedModelSizeGb
            },
            create: {
                userId: req.user.id,
                os,
                cpuCores,
                totalRamGb,
                gpuModel,
                maxSupportedModelSizeGb
            }
        });
        // Score and filter recommended models from catalog
        const recommendations = marketplace_controller_1.MODEL_CATALOG.map(model => {
            let score = 100;
            let status = 'OPTIMAL';
            // Constraint checking
            if (model.recommendedRamGb > totalRamGb) {
                score -= 50;
                status = 'LAGGY';
            }
            if (model.sizeGb > maxSupportedModelSizeGb) {
                score -= 40;
                if (model.sizeGb > totalRamGb * 0.8) {
                    status = 'UNSUPPORTED';
                    score = 0;
                }
                else if (status !== 'LAGGY') {
                    status = 'COMPATIBLE';
                }
            }
            return {
                ...model,
                score: Math.max(0, score),
                compatibilityStatus: status
            };
        }).sort((a, b) => b.score - a.score);
        return res.json({
            profile,
            recommendations,
            systemAdvice: maxSupportedModelSizeGb >= 6.0
                ? "Your hardware is optimized for local 8B parameter models. Hardware acceleration (WebGPU) is active."
                : maxSupportedModelSizeGb >= 3.0
                    ? "Optimal setup for 3B parameter models. RAM is slightly constrained. Avoid loading multiple tabs."
                    : "Low resource profile detected. We recommend running 2B models or offloading to remote cloud endpoints."
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function getDeviceProfile(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const profile = await db_1.default.deviceProfile.findFirst({
            where: { userId: req.user.id }
        });
        if (!profile) {
            return res.status(404).json({ error: 'No hardware profile found. Run system scanner first.' });
        }
        return res.json(profile);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
