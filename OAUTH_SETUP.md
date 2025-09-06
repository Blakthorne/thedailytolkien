# OAuth Setup Instructions

## Google OAuth2 Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API
4. Go to "Credentials" in the left sidebar
5. Click "Create Credentials" > "OAuth 2.0 Client IDs"
6. Set the application type to "Web application"
7. Add authorized redirect URIs:
    - For development: `http://localhost:3000/users/auth/google_oauth2/callback`
    - For production: `https://yourdomain.com/users/auth/google_oauth2/callback`
8. Copy the Client ID and Client Secret

## Rails Credentials Setup

Run the following command to edit your Rails credentials:

```bash
rails credentials:edit
```

Add the following to your credentials file:

````yaml
google_oauth2:
    client_id: "your_google_client_id_here"
    client_secret: "your_google_client_secret_here"

## Environment Variables (Alternative)

You can also set environment variables instead of using Rails credentials:

```bash
export GOOGLE_CLIENT_ID="your_google_client_id_here"
export GOOGLE_CLIENT_SECRET="your_google_client_secret_here"
<!-- Facebook env vars removed -->
````

## Test Users

The application comes with pre-seeded test users:

-   **Admin**: admin@thedailytolkien.com / password123
-   **Commentor**: user@thedailytolkien.com / password123

## User Roles

-   **admin**: Full access to all features
-   **commentor**: Standard user access (default role)

Users can be promoted to admin by updating their role in the database or through an admin interface (to be implemented).
