"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSessions = getSessions;
exports.createSession = createSession;
exports.deleteSession = deleteSession;
exports.getSessionMessages = getSessionMessages;
exports.sendMessageStream = sendMessageStream;
const db_1 = __importDefault(require("../db"));
async function getSessions(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { folder } = req.query;
        const sessions = await db_1.default.chatSession.findMany({
            where: {
                userId: req.user.id,
                ...(folder ? { folderName: folder } : {})
            },
            orderBy: { updatedAt: 'desc' }
        });
        return res.json(sessions);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function createSession(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { title, modelId, systemPrompt, temperature, folderName } = req.body;
        const session = await db_1.default.chatSession.create({
            data: {
                userId: req.user.id,
                title: title || 'New Chat Session',
                modelId: modelId || 'llama-3-3b',
                systemPrompt: systemPrompt || 'You are Nexa AI, a helpful assistant.',
                temperature: temperature || 0.7,
                folderName: folderName || null
            }
        });
        return res.status(201).json(session);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function deleteSession(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { id } = req.params;
        await db_1.default.chatSession.delete({
            where: { id, userId: req.user.id }
        });
        return res.json({ success: true });
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
async function getSessionMessages(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { id } = req.params;
        const messages = await db_1.default.chatMessage.findMany({
            where: {
                sessionId: id,
                session: { userId: req.user.id }
            },
            orderBy: { createdAt: 'asc' }
        });
        return res.json(messages);
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
// Stream LLM answer with server-sent events (SSE)
async function sendMessageStream(req, res) {
    try {
        if (!req.user)
            return res.status(401).json({ error: 'Unauthorized' });
        const { sessionId, content } = req.body;
        if (!sessionId || !content) {
            return res.status(400).json({ error: 'Session ID and message content are required' });
        }
        const session = await db_1.default.chatSession.findFirst({
            where: { id: sessionId, userId: req.user.id }
        });
        if (!session) {
            return res.status(404).json({ error: 'Session not found' });
        }
        // 1. Save User Message
        await db_1.default.chatMessage.create({
            data: {
                sessionId,
                role: 'USER',
                content,
                tokensCount: Math.ceil(content.length / 4)
            }
        });
        // Determine performance characteristics based on model selected
        const isProModel = session.modelId.includes('7b') || session.modelId.includes('13b') || session.modelId.includes('deepseek');
        const tokensPerSec = isProModel ? 18.5 + Math.random() * 5 : 42.0 + Math.random() * 10;
        const tftMs = isProModel ? 250 + Math.floor(Math.random() * 100) : 80 + Math.floor(Math.random() * 30);
        // Mock response dictionary for rich context answers
        const promptKeywords = content.toLowerCase();
        let responseTemplate = "I am processing your query locally. Nexa AI optimizes model operations directly on your device CPU/GPU utilizing our unified GGUF backend.";
        if (promptKeywords.includes('rag') || promptKeywords.includes('document') || promptKeywords.includes('pdf')) {
            responseTemplate = "Analyzing your uploaded local knowledge documents... RAG search returned 3 matching vectors. Context has been loaded into model window context of 2048 tokens.";
        }
        else if (promptKeywords.includes('benchmark') || promptKeywords.includes('speed') || promptKeywords.includes('tokens')) {
            responseTemplate = `Running local token generation test. Parameters detected: \n- Token Speed: ${tokensPerSec.toFixed(1)} Tok/sec\n- Latency: ${tftMs}ms\n- Active Model: ${session.modelId.toUpperCase()}\nHardware optimization complete.`;
        }
        else if (promptKeywords.includes('hello') || promptKeywords.includes('hi')) {
            responseTemplate = "Hello! I am Nexa AI, your private client-side assistant. How can I help you today?";
        }
        else if (promptKeywords.includes('compare') || promptKeywords.includes('versus')) {
            responseTemplate = "You are currently running in standard mode. Switch to the Compare Chat workspace to view two models processing this query side-by-side with latency logs.";
        }
        const words = responseTemplate.split(' ');
        // Set headers for Server Sent Events
        res.setHeader('Content-Type', 'text/event-stream');
        res.setHeader('Cache-Control', 'no-cache');
        res.setHeader('Connection', 'keep-alive');
        let assistantResponseText = "";
        let wordIndex = 0;
        const intervalId = setInterval(async () => {
            if (wordIndex < words.length) {
                const word = words[wordIndex] + " ";
                assistantResponseText += word;
                res.write(`data: ${JSON.stringify({ token: word })}\n\n`);
                wordIndex++;
            }
            else {
                clearInterval(intervalId);
                // 2. Save Assistant Response in Database
                const responseTokens = Math.ceil(assistantResponseText.length / 4);
                const totalInferenceTime = Math.round((responseTokens / tokensPerSec) * 1000);
                const savedMsg = await db_1.default.chatMessage.create({
                    data: {
                        sessionId,
                        role: 'ASSISTANT',
                        content: assistantResponseText.trim(),
                        tokensCount: responseTokens,
                        tokensPerSecond: tokensPerSec,
                        inferenceTimeMs: totalInferenceTime
                    }
                });
                // 3. Update Session Performance Averages
                await db_1.default.chatSession.update({
                    where: { id: sessionId },
                    data: {
                        tokensPerSecond: tokensPerSec,
                        timeToFirstTokenMs: tftMs,
                        totalTokens: { increment: responseTokens + Math.ceil(content.length / 4) }
                    }
                });
                res.write(`data: ${JSON.stringify({ done: true, message: savedMsg })}\n\n`);
                res.end();
            }
        }, 50); // Send a word every 50ms (simulates streaming)
        // Handle client disconnect
        req.on('close', () => {
            clearInterval(intervalId);
        });
    }
    catch (err) {
        return res.status(500).json({ error: err.message });
    }
}
