# Hot Reloading Setup for The Daily Tolkien

## Overview

This application now supports comprehensive hot reloading, which means your browser will automatically refresh when you make changes to view templates, stylesheets, JavaScript files, and other development assets.

## What's Enabled

### 🔥 Hot Reload Features

-   **Automatic browser refresh** when files change
-   **Ruby code reloading** without server restart
-   **View template reloading** (.erb, .haml, .slim files)
-   **Stylesheet reloading** (.css, .scss, .sass files)
-   **JavaScript reloading** (.js, .coffee files)
-   **Helper file reloading** (.rb files in app/helpers)
-   **Locale file reloading** (.yml files in config/locales)

### 📦 Gems Added

-   `listen` - Enhanced file watching for better reloading performance
-   `guard-livereload` - Monitors file changes and triggers browser refresh
-   `rack-livereload` - Middleware that enables automatic browser refresh

## How to Use

### Option 1: Using the Hot Reload Script (Recommended)

```bash
# Start development environment with hot reload
./bin/dev-hot
```

This script will:

-   Start Guard for file watching
-   Start Rails server with live reload middleware
-   Display helpful information about what's being watched
-   Gracefully handle shutdown when you press Ctrl+C

### Option 2: Manual Setup

```bash
# Terminal 1: Start Guard for file watching
bundle exec guard start

# Terminal 2: Start Rails server
bin/rails server
```

## Configuration Files

### Guardfile

Located at the project root, this file configures which files Guard watches:

-   View templates (`.erb`, `.haml`, `.slim`)
-   Stylesheets (`.css`, `.scss`, `.sass`)
-   JavaScript files (`.js`, `.coffee`)
-   Helper files
-   Locale files

### Development Environment

Enhanced in `config/environments/development.rb`:

-   Live reload middleware enabled
-   Improved file watching configuration
-   Optimized reloading settings

## How It Works

1. **File Detection**: Guard monitors your file system for changes
2. **Change Processing**: When a file changes, Guard determines what type of reload is needed
3. **Browser Communication**: Guard sends a signal to the browser via WebSocket
4. **Automatic Refresh**: The browser automatically refreshes to show your changes

## Ports

-   **Rails Server**: http://localhost:3001 (or 3000 if available)
-   **LiveReload**: Runs on port 35729 (automatic)

## Troubleshooting

### Browser Not Refreshing?

1. Make sure both Guard and Rails server are running
2. Check that you're accessing the correct port (3001)
3. Verify the browser console for any LiveReload connection errors
4. Restart both Guard and Rails server if needed

### Port Conflicts?

If port 3000 is in use, the setup will automatically use port 3001 or find the next available port.

### Performance Issues?

The `listen` gem provides efficient file watching. If you experience performance issues:

1. Make sure you're not watching unnecessary directories
2. Consider excluding large directories like `node_modules` if they exist

## Development Workflow

1. Start the hot reload environment: `./bin/dev-hot`
2. Open your browser to the displayed URL
3. Make changes to your views, styles, or JavaScript
4. Watch the browser automatically refresh with your changes
5. Code faster with instant feedback!

## Files Modified

### Gemfile

-   Added `listen`, `guard-livereload`, and `rack-livereload` gems

### config/environments/development.rb

-   Added `Rack::LiveReload` middleware
-   Configured improved file watching

### Guardfile (new)

-   Configured file watching patterns
-   Set up automatic browser refresh triggers

### bin/dev-hot (new)

-   Convenient script to start both Guard and Rails server
-   Provides helpful output and graceful shutdown

## Benefits

-   **Faster Development**: See changes instantly without manual refresh
-   **Better Workflow**: Focus on coding instead of context switching
-   **Reduced Friction**: No more F5 fatigue
-   **Professional Setup**: Industry-standard hot reloading configuration
