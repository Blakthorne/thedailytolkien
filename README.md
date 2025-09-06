# The Daily Tolkien

A Ruby on Rails web application that displays daily quotes from J.R.R. Tolkien's works. The app rotates through a database of quotes, ensuring users see a different quote each day without repetition for years.

## Features

-   **Daily Quote Rotation**: Displays a different Tolkien quote each visit, ensuring each quote is shown before repetition
-   **Quote Metadata**: Includes book, chapter, character, and context information
-   **Display Tracking**: Tracks how many times each quote has been displayed and when
-   **Extensible Design**: Easy to add more quotes or features in the future
-   **Comprehensive Database**: Currently contains 63 quotes from various Tolkien works

## Technology Stack

-   **Ruby on Rails 8.0.2.1**: Latest Rails version with modern defaults
-   **Ruby 3.4.5**: Current Ruby version
-   **SQLite**: Database for development (easily configurable for production)
-   **Importmap**: For JavaScript module management
-   **Turbo & Stimulus**: For enhanced frontend interactivity
-   **Solid Stack**: Solid Cache, Solid Queue, Solid Cable for performance

## Getting Started

### Prerequisites

-   Ruby 3.4.5 (managed via mise or rbenv)
-   Rails 8.0.2.1
-   SQLite3

### Installation

1. Clone the repository:

    ```bash
    git clone https://github.com/Blakthorne/thedailytolkien.git
    cd thedailytolkien
    ```

2. Install dependencies:

    ```bash
    bundle install
    ```

3. Create and setup the database:

    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

4. Start the development server:

    ```bash
    rails server
    ```

5. Visit `http://localhost:3000` to see the daily quote!

## Database Structure

The application uses a single `quotes` table with the following columns:

-   `text` (string): The quote text (required)
-   `book` (string): The book the quote is from (required)
-   `chapter` (string): The chapter (optional)
-   `context` (string): Additional context (optional)
-   `character` (string): The character who said it (optional)
-   `days_displayed` (integer): Number of times displayed
-   `last_date_displayed` (integer): Unix timestamp of last display
-   `first_date_displayed` (integer): Unix timestamp of first display

## Development

### Adding New Quotes

Edit `db/seeds.rb` to add more quotes, then run:

```bash
rails db:seed
```

### Running Tests

```bash
rails test
```

### Code Style

The project follows Rails conventions and uses RuboCop for linting.

## Deployment

The app is configured with Kamal for easy deployment. See `config/deploy.yml` for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear, detailed comments
4. Add tests if applicable
5. Submit a pull request

## License

See LICENSE file for details.

## About

This project demonstrates modern Rails development practices with a focus on clean, well-documented code following literate programming principles.
