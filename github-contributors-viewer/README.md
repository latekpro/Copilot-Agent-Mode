# GitHub Contributors Viewer

A two-tier web application that displays GitHub repository contributors in a gallery view. Built with React frontend and Node.js/Express backend.

## Features

- Search for a GitHub repository using owner/organization name and repository name
- Display all contributors to the repository in a gallery view
- Show contributor avatars, usernames, and contribution counts
- Link to contributor GitHub profiles

## Project Structure

The project is organized in a two-tier architecture:

- `frontend/`: React application
- `backend/`: Node.js/Express API server

## Getting Started

### Prerequisites

- Node.js (v14 or higher)
- npm (v6 or higher)

### Installation

1. Clone the repository

2. Install dependencies for both frontend and backend
   ```
   npm run install-all
   ```

### Configuration

1. Backend: Configure environment variables in `backend/.env`
   ```
   PORT=5000
   GITHUB_TOKEN=your_github_token_here (optional)
   ```

2. Frontend: Configure environment variables in `frontend/.env`
   ```
   REACT_APP_API_URL=http://localhost:5000
   ```

### Running the Application

1. Start both frontend and backend concurrently:
   ```
   npm run dev
   ```

2. Or start them separately:
   - Backend: `npm run backend`
   - Frontend: `npm run frontend`

3. Open your browser and navigate to:
   ```
   http://localhost:3000
   ```

## API Endpoints

- `GET /api/contributors/:owner/:repo` - Get contributors for a GitHub repository
- `GET /api/health` - Health check endpoint

## Technologies Used

### Frontend
- React
- Axios for HTTP requests
- CSS for styling

### Backend
- Node.js
- Express
- Axios for calling GitHub API
- dotenv for environment variables
- cors for Cross-Origin Resource Sharing
