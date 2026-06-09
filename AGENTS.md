# AGENT GUIDELINES

This document outlines the conventions and practices for agentic coding within this repository. Adhering to these guidelines ensures consistency, maintainability, and seamless collaboration.

---

## 1. Build, Lint, and Test Commands

Agents should prioritize using the project's established commands for building, linting, and testing.

### General Commands:
- **Build:** `[COMMAND_TO_BUILD_PROJECT]`
  - *Example:* `npm run build`, `mvn clean install`, `go build ./...`
- **Lint:** `[COMMAND_TO_RUN_LINTER]`
  - *Example:* `npm run lint`, `flake8 .`, `ruff check .`
- **Test (All):** `[COMMAND_TO_RUN_ALL_TESTS]`
  - *Example:* `npm test`, `pytest`, `go test ./...`

### Running a Single Test:
When working on a specific feature or bug, agents should aim to run only the relevant tests to save time and resources.

- **For JavaScript/TypeScript (e.g., Jest, Mocha):**
  - `[TEST_COMMAND] -- test-file-pattern`
  - *Example:* `npm test -- src/components/Button.test.tsx`
  - *Example:* `jest src/utils/auth.test.js`
- **For Python (e.g., Pytest):**
  - `[TEST_COMMAND] path/to/test_file.py::test_function_name`
  - *Example:* `pytest tests/unit/test_api.py::test_get_user`
  - *Example:* `pytest -k "test_login"` (to run tests matching a keyword)
- **For Go:**
  - `[TEST_COMMAND] -run TestFunctionName ./path/to/package`
  - *Example:* `go test -run TestUserService_CreateUser ./internal/user`
- **For Java (e.g., Maven Surefire, Gradle Test):**
  - `[MAVEN_COMMAND] -Dtest=MyTestClass#testMethod`
  - *Example:* `mvn test -Dtest=UserServiceTest#testCreateUser`
  - `[GRADLE_COMMAND] --tests "com.example.MyTestClass.testMethod"`
  - *Example:* `gradle test --tests "com.example.AuthServiceTest.testLogin"`

**Important:** Before running any test commands, ensure all dependencies are installed using the appropriate package manager (e.g., `npm install`, `pip install -r requirements.txt`, `go mod download`, `mvn install`).

---

## 2. Code Style Guidelines

Consistency in code style is crucial for readability and maintainability. Agents must adhere to the following guidelines.

### Imports:
- **Ordering:** Imports should be grouped and ordered logically:
  1. Standard library imports
  2. Third-party library imports
  3. Local project imports
- **Formatting:** Each group should be separated by a blank line. Within groups, imports should be sorted alphabetically.
- **Example (Python):**
  ```python
  import os
  import sys

  import requests
  from flask import Flask

  from .config import settings
  from .utils import helpers
  ```
- **Example (TypeScript/JavaScript):**
  ```typescript
  import { useEffect, useState } from 'react';
  import axios from 'axios';
  import { Button } from '@/components/ui/button';
  import { UserProfile } from '@/types/user';
  ```

### Formatting:
- **Indentation:** Use `[INDENTATION_STYLE]` (e.g., 2 spaces, 4 spaces, tabs).
- **Line Length:** Aim for a maximum of `[MAX_LINE_LENGTH]` characters per line.
- **Braces/Parentheses:** Follow the `[BRACE_STYLE]` (e.g., K&R, Allman, inline).
- **Semicolons:** Use `[SEMICOLON_USAGE]` (e.g., always, never, only when necessary).
- **Quotes:** Use `[QUOTE_STYLE]` for strings (e.g., single quotes, double quotes, backticks).

### Types:
- **Type Annotations:** Strongly prefer explicit type annotations for functions, variables, and class members in languages that support them (e.g., TypeScript, Python with type hints, Java).
- **Clarity:** Types should be as specific as possible without being overly verbose.

### Naming Conventions:
- **Variables/Functions:** Use `[VARIABLE_FUNCTION_NAMING_CONVENTION]` (e.g., `camelCase`, `snake_case`, `kebab-case`).
- **Classes/Interfaces:** Use `[CLASS_INTERFACE_NAMING_CONVENTION]` (e.g., `PascalCase`).
- **Constants:** Use `[CONSTANT_NAMING_CONVENTION]` (e.g., `UPPER_SNAKE_CASE`).
- **Files/Directories:** Use `[FILE_DIRECTORY_NAMING_CONVENTION]` (e.g., `kebab-case`, `snake_case`).

### Error Handling:
- **Graceful Degradation:** Implement robust error handling to prevent application crashes and provide meaningful feedback to users.
- **Logging:** Log errors with sufficient detail (stack traces, relevant context) to aid debugging.
- **Specificity:** Catch specific exceptions/errors rather than broad ones when possible.
- **Retries:** Implement retry mechanisms for transient errors in external service calls.

---

## 3. Cursor Rules (`.cursor/rules/` or `.cursorrules`)

If this project utilizes Cursor's AI coding assistance, adhere to any specific rules or configurations defined in `.cursor/rules/` or `.cursorrules`. These rules often provide context-aware suggestions and automated refactorings.

**Note:** If these files exist, agents should read them to understand the specific directives.

---

## 4. Copilot Rules (`.github/copilot-instructions.md`)

If GitHub Copilot is integrated into this project, consult `.github/copilot-instructions.md` for guidance on its usage. These instructions typically dictate preferred code patterns, comment styles, or other behaviors Copilot should follow.

**Note:** If this file exists, agents should read it to understand the specific directives.
