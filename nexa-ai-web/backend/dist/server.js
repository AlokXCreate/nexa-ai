"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const http_1 = __importDefault(require("http"));
const socket_io_1 = require("socket.io");
const api_routes_1 = __importDefault(require("./routes/api.routes"));
dotenv_1.default.config();
const app = (0, express_1.default)();
const server = http_1.default.createServer(app);
const io = new socket_io_1.Server(server, {
    cors: {
        origin: "*", // Allow all for development testing
        methods: ["GET", "POST", "PUT", "DELETE"]
    }
});
// Configure CORS and JSON parsing
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Logger middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});
// Mount routes
app.use('/api', api_routes_1.default);
// Basic health check route
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date() });
});
// Socket.io connection handlers for real-time dashboard overlays
io.on('connection', (socket) => {
    console.log(`[Socket] New client connected: ${socket.id}`);
    // Emit mock server stats periodically for real-time admin charts
    const intervalId = setInterval(() => {
        socket.emit('realtime-metrics', {
            timestamp: new Date(),
            activeUsers: 45 + Math.floor(Math.random() * 10),
            cpuLoadPercent: 10 + Math.random() * 15,
            ramUsageGb: 3.2 + Math.random() * 0.4,
            networkSpeedMbps: 850 + Math.floor(Math.random() * 100)
        });
    }, 3000);
    socket.on('disconnect', () => {
        console.log(`[Socket] Client disconnected: ${socket.id}`);
        clearInterval(intervalId);
    });
});
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
    console.log(`========================================`);
    console.log(` Nexa AI Backend server running on:`);
    console.log(` http://localhost:${PORT}`);
    console.log(`========================================`);
});
