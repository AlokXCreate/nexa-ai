import { Response } from 'express';
import prisma from '../db';
import { AuthRequest } from '../middleware/auth.middleware';

// Default mock plugins list
const DEFAULT_PLUGINS = [
  {
    name: "Web Search Engine",
    identifier: "nexa.plugin.websearch",
    version: "1.0.2",
    description: "Equips the LLM with search engine access to fetch real-time data before compiling answers.",
    icon: "Globe",
    author: "Nexa Core Team"
  },
  {
    name: "Python Code Interpreter",
    identifier: "nexa.plugin.pyinterpreter",
    version: "1.4.0",
    description: "Runs code snippets in a local secure JavaScript/WebAssembly sandbox to verify output.",
    icon: "Code2",
    author: "Nexa Core Team"
  },
  {
    name: "Notion Knowledge Syncer",
    identifier: "nexa.plugin.notionsync",
    version: "0.9.5",
    description: "Syncs your Notion workspace databases directly into local RAG knowledge files.",
    icon: "Notebook",
    author: "Community"
  }
];

export async function getPlugins(req: AuthRequest, res: Response) {
  try {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });

    // Fetch user plugins
    let plugins = await prisma.plugin.findMany({
      where: { userId: req.user.id }
    });

    // Seed default plugins if empty
    if (plugins.length === 0) {
      await prisma.plugin.createMany({
        data: DEFAULT_PLUGINS.map(p => ({
          userId: req.user!.id,
          name: p.name,
          identifier: p.identifier,
          version: p.version,
          description: p.description,
          icon: p.icon,
          author: p.author,
          activeStatus: false
        }))
      });

      plugins = await prisma.plugin.findMany({
        where: { userId: req.user.id }
      });
    }

    return res.json(plugins);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
}

export async function togglePlugin(req: AuthRequest, res: Response) {
  try {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    const { id } = req.params;
    const { active } = req.body;

    const plugin = await prisma.plugin.findUnique({ where: { id } });
    if (!plugin || plugin.userId !== req.user.id) {
      return res.status(404).json({ error: 'Plugin not found' });
    }

    const updated = await prisma.plugin.update({
      where: { id },
      data: { activeStatus: active }
    });

    return res.json(updated);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
}

export async function registerCustomPlugin(req: AuthRequest, res: Response) {
  try {
    if (!req.user) return res.status(401).json({ error: 'Unauthorized' });
    const { name, identifier, version, description, icon, downloadUrl, author } = req.body;

    if (!name || !identifier || !version) {
      return res.status(400).json({ error: 'Name, identifier, and version are required' });
    }

    const existing = await prisma.plugin.findFirst({
      where: { userId: req.user.id, identifier }
    });
    if (existing) {
      return res.status(400).json({ error: 'Plugin with this identifier is already registered' });
    }

    const plugin = await prisma.plugin.create({
      data: {
        userId: req.user.id,
        name,
        identifier,
        version,
        description,
        icon: icon || 'PuzzlePattern',
        downloadUrl,
        author: author || 'Developer',
        activeStatus: false
      }
    });

    return res.status(201).json(plugin);
  } catch (err: any) {
    return res.status(500).json({ error: err.message });
  }
}
