# Reverse Proxy Setup

This project contains the reverse proxy configuration for hosting the frontend and backend applications.

## Prerequisites

- Docker
- Frontend application built and available in `../frontend/dist`
- Backend running on port 8000

## Configuration

The setup includes:
- Nginx reverse proxy running on port 80
- Static file hosting for frontend (from ../frontend/dist)
- API proxy for backend requests (/api/* → localhost:8000)
- Authentication header forwarding

## Usage

1. Make sure your frontend is built:
   ```bash
   cd ../frontend
   npm run build
   ```

2. Start your backend service on port 8000

3. Start the reverse proxy:
   ```bash
   docker compose up --build
   ```

The services will be available at:
- Frontend: http://localhost/
- Backend API: http://localhost/api/

## Notes

- The frontend static files are mounted from `../frontend/dist`
- API requests to `/api/*` are forwarded to the backend at `localhost:8000`
- Authentication headers (Bearer tokens) are automatically forwarded to the backend
- For development, you might want to run the frontend directly (e.g., on port 5173) instead of building it 