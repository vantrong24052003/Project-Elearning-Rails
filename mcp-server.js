const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

const basePaths = {
  controllers: path.resolve(__dirname, 'app/controllers'),
  models: path.resolve(__dirname, 'app/models'),
  views: path.resolve(__dirname, 'app/views'),
  frontend: path.resolve(__dirname, 'app/frontend'),
  config: path.resolve(__dirname, 'config') 
};

const isPathSafe = (filePath, basePath) => {
  const relativePath = path.relative(basePath, filePath);
  return relativePath && !relativePath.startsWith('..') && !path.isAbsolute(relativePath);
};

app.get('/controller/:namespace/:filename', async (req, res) => {
  const { namespace, filename } = req.params;
  const filePath = path.join(basePaths.controllers, namespace, filename);

  if (!isPathSafe(filePath, basePaths.controllers)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  try {
    const data = await fs.readFile(filePath, 'utf8');
    res.json({ content: data });
  } catch (err) {
    res.status(404).json({ error: 'File not found' });
  }
});

app.get('/model/:filename', async (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(basePaths.models, filename);

  if (!isPathSafe(filePath, basePaths.models)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  try {
    const data = await fs.readFile(filePath, 'utf8');
    res.json({ content: data });
  } catch (err) {
    res.status(404).json({ error: 'File not found' });
  }
});

app.get('/view/:namespace/:controller/:viewfile', async (req, res) => {
  const { namespace, controller, viewfile } = req.params;
  const filePath = path.join(basePaths.views, namespace, controller, viewfile);

  if (!isPathSafe(filePath, basePaths.views)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  try {
    const data = await fs.readFile(filePath, 'utf8');
    res.json({ content: data });
  } catch (err) {
    res.status(404).json({ error: 'File not found' });
  }
});

app.get('/config/:filename', async (req, res) => {
  const { filename } = req.params;
  const filePath = path.join(basePaths.config, filename);

  if (!isPathSafe(filePath, basePaths.config)) {
    return res.status(403).json({ error: 'Access denied' });
  }

  try {
    const data = await fs.readFile(filePath, 'utf8');
    res.json({ content: data });
  } catch (err) {
    res.status(404).json({ error: 'File not found' });
  }
});

app.get('/', (req, res) => {
    res.json({ message: 'MCP server is running' });
  });

app.use('/frontend', express.static(basePaths.frontend));

const PORT = 5000;
app.listen(PORT, () => {
  console.log(`MCP server running on http://localhost:${PORT}`);
});