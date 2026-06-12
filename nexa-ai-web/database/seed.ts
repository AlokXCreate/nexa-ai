import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding Nexa AI database...');

  // 1. Create default admin account
  const passwordHash = await bcrypt.hash('admin123', 10);
  const admin = await prisma.user.upsert({
    where: { email: 'admin@nexa.ai' },
    update: {},
    create: {
      email: 'admin@nexa.ai',
      passwordHash,
      role: 'ADMIN',
      subscriptionStatus: 'ENTERPRISE',
      profile: {
        create: {
          firstName: 'Principal',
          lastName: 'Architect',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=admin@nexa.ai',
          bio: 'Nexa AI System Admin & Chief Architect'
        }
      }
    }
  });
  console.log(`Admin user created: ${admin.email}`);

  // 2. Create default standard user account
  const userPassHash = await bcrypt.hash('user123', 10);
  const user = await prisma.user.upsert({
    where: { email: 'user@nexa.ai' },
    update: {},
    create: {
      email: 'user@nexa.ai',
      passwordHash: userPassHash,
      role: 'USER',
      subscriptionStatus: 'PRO',
      profile: {
        create: {
          firstName: 'Jane',
          lastName: 'Smith',
          avatarUrl: 'https://api.dicebear.com/7.x/bottts/svg?seed=user@nexa.ai',
          bio: 'Local edge AI enthusiast'
        }
      }
    }
  });
  console.log(`Standard user created: ${user.email}`);

  // 3. Create mock payment transactions for admin dashboard
  await prisma.payment.createMany({
    data: [
      { userId: user.id, transactionId: 'txn-1', amount: 9.99, status: 'COMPLETED', provider: 'STRIPE' },
      { userId: admin.id, transactionId: 'txn-2', amount: 49.99, status: 'COMPLETED', provider: 'STRIPE' }
    ],
    skipDuplicates: true
  });

  // 4. Create a default active chat session for the user
  const session = await prisma.chatSession.create({
    data: {
      userId: user.id,
      title: 'Local Rust Development Guidance',
      modelId: 'phi-3-mini',
      temperature: 0.5,
      tokensPerSecond: 48.2,
      timeToFirstTokenMs: 85,
      totalTokens: 140
    }
  });

  await prisma.chatMessage.createMany({
    data: [
      { sessionId: session.id, role: 'SYSTEM', content: 'You are Nexa AI, a helpful private assistant.' },
      { sessionId: session.id, role: 'USER', content: 'How do I write a safe file writer in Rust?' },
      { sessionId: session.id, role: 'ASSISTANT', content: 'In Rust, you can safely write files using std::fs::File. Here is a quick example:\n\n```rust\nuse std::fs::File;\nuse std::io::prelude::*;\n\nfn main() -> std::io::Result<()> {\n    let mut file = File::create("foo.txt")?;\n    file.write_all(b"Hello, world!")?;\n    Ok(())\n}\n```\nAll operations are verified compile-time.', tokensCount: 120, tokensPerSecond: 48.2, inferenceTimeMs: 2400 }
    ]
  });

  console.log('Database seeding complete successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
