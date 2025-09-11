---
applyTo: "**"
description: "General guidelines"
---

# General Guidelines to Follow

## Your Mission

Your mission is to ensure that the codebase is of high quality, maintainable, and adheres to best practices.

## Visual Procedures

Whenever you make any changes to the view of the website, make sure that it is visually consistent with the rest of the app. Make sure that all colors, fonts, and styles match the existing design. Ensure that the user experience is smooth and intuitive. Test the changes on different devices and screen sizes to ensure responsiveness and usability.

## Thought Processes

When thinking about a task, make a todo list of items that you'll need to perform in the after thinking about it thoroughly. Make sure that you're moving along in the last as you check items off. Do this no matter how the task may seem, even if making a todo list doesn't seem like a good idea.

## Scan for common Rails security vulnerabilities using static analysis

You will run Brakeman with the command "bin/brakeman --no-pager". Whenever you run Brakeman, it is imperative that you always use the --no-pager flag. Brakeman is a static analysis security vulnerability scanner for Ruby on Rails applications, to identify potential security issues in the codebase whenver you finish making changes according to a prompt. Address any vulnerabilities that are found to ensure the application is secure after making changes. You must do this before running the application tests below.

## Linting

You will lint the codebase using RuboCop with the command "bin/rubocop". Address any linting issues that are found to ensure the code adheres to Ruby style guidelines. You must do this before running the application tests below.

## Testing

You will ensure, after you finish making changes, that all tests pass successfully. This includes unit tests, integration tests, and any other automated tests present in the codebase. It is absolutely inadmissable for the codebase be pushed to GitHub with failing tests. The GitHub actions being run upon pushing absolutely cannot fail. If you run any test and it fails, you must figure out the issue, fix it, and re-run the tests until they all pass.

Everything in the app must be thoroughly tested. After making changes to the app, make sure that all the changes you made are thoroughly tested. If you find any gaps in the test coverage, you must add tests to cover those gaps. You must ensure that all new code is covered by tests, and that existing code remains covered by tests.

Whenever you make any changes to the view, you need to completely and thoroughly, to 100% of all possiblities, test every possible action that the user can make in the view. There can be no errors, and every button, page, etc. must perform as intended for the user. Do this until all problems are solved completely.

Tests need to be clear, concise, and easy to understand. If you find any tests that are overly complex or difficult to understand, you must refactor them to improve their clarity and maintainability. 100% of the code must be covered by tests. 100% of the tests must pass before you can stop iterating and consider your task completed. It doesn't matter if the failing tests are unrelated to the changes you just made. All tests must pass.
