"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MODEL_CATALOG = void 0;
exports.getModelCatalog = getModelCatalog;
exports.getInstalledModels = getInstalledModels;
exports.simulateModelDownload = simulateModelDownload;
// Hardcoded Model Catalog representing GGUF / TFLite targets
exports.MODEL_CATALOG = [
    {
        id: "llama-3-3b",
        name: "Llama 3 (3B)",
        type: "LLM",
        parameters: "3.2 Billion",
        sizeGb: 2.1,
        format: "GGUF (Q4_K_M)",
        description: "Highly optimized lightweight meta model. Perfect for daily tasks and low-resource devices.",
        recommendedRamGb: 8,
        isPopular: true
    },
    {
        id: "llama-3-8b",
        name: "Llama 3 (8B)",
        type: "LLM",
        parameters: "8.0 Billion",
        sizeGb: 4.8,
        format: "GGUF (Q4_K_M)",
        description: "Standard general-purpose model. High quality instruction follower and reasoner.",
        recommendedRamGb: 12,
        isPopular: false
    },
    {
        id: "phi-3-mini",
        name: "Phi-3 Mini (3.8B)",
        type: "LLM",
        parameters: "3.8 Billion",
        sizeGb: 2.2,
        format: "GGUF (Q4_K_M)",
        description: "Microsoft's state of the art lightweight language model. Very fast inference.",
        recommendedRamGb: 8,
        isPopular: true
    },
    {
        id: "deepseek-coder-7b",
        name: "DeepSeek Coder (7B)",
        type: "LLM",
        parameters: "6.7 Billion",
        sizeGb: 4.1,
        format: "GGUF (Q4_K_M)",
        description: "Outstanding coding and math capabilities. Ideal for local software engineering tasks.",
        recommendedRamGb: 12,
        isPopular: false
    },
    {
        id: "gemma-2b-it",
        name: "Gemma 2B IT",
        type: "LLM",
        parameters: "2.5 Billion",
        sizeGb: 1.6,
        format: "GGUF (Q4_K_M)",
        description: "Google's open-source mobile-first assistant. Ultra thin profile with excellent latency.",
        recommendedRamGb: 6,
        isPopular: true
    },
    {
        id: "whisper-tiny-en",
        name: "Whisper Tiny (English)",
        type: "AUDIO",
        parameters: "39 Million",
        sizeGb: 0.08,
        format: "GGML",
        description: "Real-time speech-to-text transcriber. Processes voice inputs offline with sub-second lag.",
        recommendedRamGb: 4,
        isPopular: false
    }
];
async function getModelCatalog(req, res) {
    try {
        return res.json(exports.MODEL_CATALOG);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function getInstalledModels(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        // For simplicity, we track installed status inside a user setting/profile or mock it.
        // In our Prisma schema, we don't have an "InstalledModel" model but we can fetch
        // download logs or configurations to see what's active. Let's mock a few defaults.
        const installed = [
            { modelId: "llama-3-3b", installedAt: new Date(Date.now() - 86400000 * 5) },
            { modelId: "whisper-tiny-en", installedAt: new Date(Date.now() - 86400000 * 2) }
        ];
        return res.json(installed);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function simulateModelDownload(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { modelId } = req.body;
        const exists = exports.MODEL_CATALOG.find(m => m.id === modelId);
        if (!exists)
            return res.status(404).json({ error: 'Model not found in catalog' });
        // Mock progress stream event hooks
        // In production, backend serves the actual file from CDN (Cloudflare R2)
        return res.json({
            success: true,
            message: `Starting model download for ${exists.name}`,
            url: `https://cdn.nexa.ai/models/${modelId}.gguf`,
            sizeGb: exists.sizeGb
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
