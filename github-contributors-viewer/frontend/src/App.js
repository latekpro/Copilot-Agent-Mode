import { useState } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [owner, setOwner] = useState('');
  const [repo, setRepo] = useState('');
  const [contributors, setContributors] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000';

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!owner || !repo) {
      setError('Please enter both a GitHub handle and repository name.');
      return;
    }

    setLoading(true);
    setError('');
    setContributors([]);
    
    try {
      const response = await axios.get(`${API_URL}/api/contributors/${owner}/${repo}`);
      setContributors(response.data);
      if (response.data.length === 0) {
        setError('No contributors found for this repository.');
      }
    } catch (err) {
      if (err.response && err.response.data && err.response.data.message) {
        setError(err.response.data.message);
      } else {
        setError('Error fetching contributors. Please try again.');
      }
      console.error('Error:', err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>GitHub Contributors Gallery</h1>
        <form onSubmit={handleSubmit} className="search-form">
          <div className="form-group">
            <input
              type="text"
              value={owner}
              onChange={(e) => setOwner(e.target.value)}
              placeholder="GitHub Username/Organization"
              className="form-control"
              aria-label="GitHub username or organization"
            />
          </div>
          <div className="form-group">
            <input
              type="text"
              value={repo}
              onChange={(e) => setRepo(e.target.value)}
              placeholder="Repository Name"
              className="form-control"
              aria-label="Repository name"
            />
          </div>
          <button type="submit" className="submit-btn" disabled={loading}>
            {loading ? 'Loading...' : 'Find Contributors'}
          </button>
        </form>

        {error && <div className="error-message">{error}</div>}

        {loading && <div className="loading">Loading contributors...</div>}

        {contributors.length > 0 && (
          <div className="results">
            <h2>Contributors to {owner}/{repo}</h2>
            <div className="contributors-gallery">
              {contributors.map((contributor) => (
                <div key={contributor.id} className="contributor-card">
                  <a 
                    href={contributor.profile_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="contributor-link"
                  >
                    <img
                      src={contributor.avatar_url}
                      alt={`${contributor.login}'s avatar`}
                      className="contributor-avatar"
                    />
                    <div className="contributor-info">
                      <div className="contributor-name">{contributor.login}</div>
                      <div className="contribution-count">
                        {contributor.contributions} {contributor.contributions === 1 ? 'contribution' : 'contributions'}
                      </div>
                    </div>
                  </a>
                </div>
              ))}
            </div>
          </div>
        )}
      </header>
      <footer className="App-footer">
        <img src="/unicorn.png" alt="Unicorn" className="unicorn-image" />
        <span>VisionDays 2025 - Denis is the best!</span>
        <img src="/unicorn.png" alt="Unicorn" className="unicorn-image" />
      </footer>
    </div>
  );
}

export default App;
