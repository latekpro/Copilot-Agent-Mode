require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// API Routes
app.get('/api/contributors/:owner/:repo', async (req, res) => {
  try {
    const { owner, repo } = req.params;
    const response = await axios.get(
      `https://api.github.com/repos/${owner}/${repo}/contributors`,
      {
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          // Optional: Add GitHub token if you need higher rate limits
          // 'Authorization': `token ${process.env.GITHUB_TOKEN}`
        }
      }
    );
    
    // Extract useful contributor info
    const contributors = response.data.map(contributor => ({
      id: contributor.id,
      login: contributor.login,
      avatar_url: contributor.avatar_url,
      contributions: contributor.contributions,
      profile_url: contributor.html_url
    }));
    
    res.json(contributors);
  } catch (error) {
    console.error('Error fetching GitHub contributors:', error.message);
    
    if (error.response && error.response.status === 404) {
      return res.status(404).json({ message: 'Repository not found' });
    }
    
    if (error.response && error.response.status === 403) {
      return res.status(403).json({ message: 'API rate limit exceeded. Try again later.' });
    }
    
    res.status(500).json({ message: 'Server error' });
  }
});

// Health check route
app.get('/api/health', (req, res) => {
  res.json({ status: 'UP' });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
