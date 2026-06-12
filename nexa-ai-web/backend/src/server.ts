import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import http from 'http';
import { Server } from 'socket.io';
import router from './routes/api.routes';

dotenv.config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allow all for development testing
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// Configure CORS and JSON parsing
app.use(cors());
app.use(express.json());

// Logger middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Mount routes
app.use('/api', router);

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
