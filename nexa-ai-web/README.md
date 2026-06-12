# Nexa AI - Responsive SaaS Web Platform

A highly secure, privacy-preserving client-side AI assistant web companion designed to execute Large Language Models (LLMs) locally on consumer devices. This repository contains the complete Next.js frontend, Node/Express backend, and Prisma/PostgreSQL database schema.

---

## 1. Project Architecture

The application is structured as a decoupled monorepo workspace:

```
nexa-ai-web/
├── database/            # Prisma schema configurations & DB seed scripts
├── backend/             # Express.js REST APIs & Socket.io server (TypeScript)
├── frontend/            # Next.js App Router, Tailwind & Framer Motion
└── docker-compose.yml   # Dev dependencies for PostgreSQL & Redis
```

### Core Technologies
* **Frontend**: Next.js 16 (App Router), React 19, TypeScript, Tailwind CSS, Framer Motion, Zustand (State Store), TanStack React Query.
* **Backend**: Node.js, Express, TypeScript, JWT Auth, Socket.io (Real-time telemetry).
* **Database & ORM**: PostgreSQL, Prisma Client.
* **Services**: Local RAG vector simulator, WebGPU benchmark trackers, and Stripe Mock billing interfaces.

---

## 2. Dev Environment Local Setup

Follow these steps to run the entire stack locally:

### Prerequisites
* **Node.js** (v20+ recommended) & **npm**
* **Docker Desktop** (for PostgreSQL & Redis container orchestration)

---

### Step A: Spin Up Local Databases
1. Start the PostgreSQL and Redis containers:
   ```bash
   docker-compose up -d
   ```

---

### Step B: Setup and Run Backend Services
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install npm package dependencies:
   ```bash
   npm install
   ```
3. Generate the Prisma database client:
   ```bash
   npm run db:generate
   ```
4. Push the Prisma schema structures into the active PostgreSQL instance:
   ```bash
   npm run db:push
   ```
5. Seed the database with mock records (Admins, Users, payments, chats):
   ```bash
   npx ts-node ../database/seed.ts
   ```
6. Start the TypeScript development server:
   ```bash
   npm run dev
   ```
   *The Express service will bind to:* `http://localhost:5000`

---

### Step C: Setup and Run Next.js Frontend
1. Navigate to the frontend directory:
   ```bash
   cd ../frontend
   ```
2. Install npm packages:
   ```bash
   npm install
   ```
3. Run the Next.js development server:
   ```bash
   npm run dev
   ```
   *Open your browser and navigate to:* `http://localhost:3000`

---

## 3. Pre-seeded Test Accounts

Use these credentials to log in and test user role scopes:

### Admin User (Full Dashboard & Admin Metrics Console)
* **Email**: `admin@nexa.ai`
* **Password**: `admin123`

### Standard User (Standard Chat, Compare Mode, & Hardware Profiler)
* **Email**: `user@nexa.ai`
* **Password**: `user123`

---

## 4. REST API Endpoint Catalog

All requests must append the token header: `Authorization: Bearer <JWT_TOKEN>`.

### Authentication
* `POST /api/auth/signup` - Register a user and Profile database record.
* `POST /api/auth/login` - Verify password credentials and return sign-in token.
* `GET /api/auth/me` - Retrieve current user profile and subscription status.
* `PUT /api/auth/profile` - Modify bio fields, name properties, and avatar URLs.
* `POST /api/auth/upgrade` - Upgrades active level (PRO/ENTERPRISE) with Stripe mock transaction logging.

### Chat & Vector Operations
* `GET /api/chat/sessions` - Retrieve all user conversation sessions.
* `POST /api/chat/sessions` - Create folder-bound or standard chat sessions.
* `DELETE /api/chat/sessions/:id` - Remove session history records.
* `GET /api/chat/sessions/:id/messages` - Return message logs.
* `POST /api/chat/messages/stream` - Initiates word-by-word Server-Sent Events (SSE) streaming.

### Device Optimizer & Plugins
* `POST /api/optimizer/profile` - Profile local client capabilities and output recommended model lists.
* `GET /api/plugins` - Return available plugin extensions.
* `PUT /api/plugins/:id/toggle` - Toggle plugin extension status.

### Admin Operations
* `GET /api/admin/stats` - Retreive aggregate revenue metrics, subscription counts, and Weekly Latency averages. (Requires `ADMIN` role).
