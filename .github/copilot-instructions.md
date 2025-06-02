# Rails Development Guidelines

## 1. Communication Principles
- Use Vietnamese in all situations
- **Do not write comments in code**, focus on writing self-explanatory code
- Technical terms without Vietnamese equivalents can be kept with brief explanations if needed

## 2. MCP Proxy Server Usage for Code Analysis
- **Always prefer MCP proxy server over traditional file reading for code analysis**
- MCP server runs on `http://localhost:5000` and provides efficient access to project structure
- **Use curl commands to read code and understand patterns quickly**:

### Code Reading Commands:
```bash
# Read models to understand relationships
curl -s "http://localhost:5000/model/[filename].rb" | jq -r '.content'

# Read controllers to understand action patterns  
curl -s "http://localhost:5000/controller/[namespace]/[filename]_controller.rb" | jq -r '.content'

# Read views to understand UI patterns
curl -s "http://localhost:5000/view/[namespace]/[controller]/[viewfile].html.erb" | jq -r '.content'
```

### Pattern Analysis Commands:
```bash
# Quick relationship analysis
curl -s "http://localhost:5000/model/[model].rb" | jq -r '.content' | grep -E "(has_many|belongs_to)"

# Controller methods overview
curl -s "http://localhost:5000/controller/[namespace]/[controller].rb" | jq -r '.content' | grep -E "def "

# Compare multiple models relationships
for model in user course chapter; do
  echo "=== ${model^^} RELATIONSHIPS ==="
  curl -s "http://localhost:5000/model/${model}.rb" | jq -r '.content' | grep -E "(has_many|belongs_to)"
  echo
done
```

### Benefits of MCP Proxy Usage:
- **Token Efficiency**: Get specific information without reading entire files
- **Pattern Recognition**: Quickly identify Rails conventions and relationships
- **Structure Understanding**: Compare multiple files in single commands
- **Faster Analysis**: Filter content directly in command line
- **Context Awareness**: Understand project architecture before writing code

### When to Use MCP Proxy:
- ✅ **Before writing new features** - understand existing patterns
- ✅ **When comparing structures** - relationships between models
- ✅ **For quick analysis** - controller actions, model validations
- ✅ **Pattern extraction** - UI components, Stimulus controllers
- ❌ **For full file editing** - use traditional read_file tool

## 3. Controller and View Structure
- **Strictly follow the 7 standard Rails methods**:
  - `index`: List all records
  - `show`: Display a specific record
  - `new`: Display form for creation
  - `create`: Process record creation
  - `edit`: Display form for editing
  - `update`: Process record update
  - `destroy`: Process record deletion
- **Place complex logic in private methods**:
  - Public methods should only call private methods
  - Separate complex processing logic into private methods to keep code clean and readable
  - Private methods can provide data for the 7 main methods
  - Keep main methods concise, focusing on the primary processing flow

## 4. No Service Separation
- **Do not separate logic into independent services**
- Keep all processing logic in the controller to ensure adherence to a simple MVC model
- Only use concerns when logic is repeated across multiple controllers

## 5. Minimize Code Files
- **Do not separate files when unnecessary**:
  - Only separate files when they have 50+ lines
  - Only separate files when used in multiple places within the project
- **Write views directly if elements are related**:
  - If using turbo in a view, write turbo-related code directly in that view file
  - Do not separate into different files if closely related

## 6. Directory Structure
- Controllers for client interface are located in `controllers/dashboard/` or `views/dashboard/`
- Controllers for admin interface are located in `controllers/manage/` or `views/manage/`
- Stimulus controllers are placed in `app/frontend/javascript/controllers` directory
- When creating a new Stimulus controller, it must be imported into the `index.js` file in the controllers directory

## 7. Technology Stack and Project Description
- **Technology Stack**:
  - *Backend*: Rails 8
  - *Frontend*: Stimulus, Turbo, TailwindCSS, Daisy UI

- **Project Theme**: E-learning
  - *Instructor*: Upload videos, create accounts, manage students, courses, chapters, and lessons
  - *Student*: View courses, purchase courses
  - *Admin*: Manage and approve courses, verify content suitability

## 8. Understanding Models Before Writing Code
- **Read model files carefully using MCP proxy**:
  - Check relationships: `has_many`, `belongs_to`, `has_one`, `has_and_belongs_to_many`
  - Review validations, enums, default_scope, callbacks
  - Check predefined methods
  - Check delegates, aliases, or other macros

- **Use MCP proxy for quick relationship analysis**:
```bash
# Understand model relationships before coding
curl -s "http://localhost:5000/model/course.rb" | jq -r '.content' | grep -E "(has_many|belongs_to|validates)"
```

- **Use correct relationships**:
  - Example: If `Lesson` has `belongs_to :chapter`, no need to rewrite `chapter_id`, just use `lesson.chapter`
  - Understand relationships between tables
  - Visualize the ERD or use the `rails-erd` gem for an overview

- **Avoid redundant queries**:
  - Avoid using `.where(...)` when there is already a relationship
  - Avoid creating additional tables if there is a join table

## 9. Use Correct HTTP Status Codes
- **200 OK:** Request successful with return content (typically used for successful GET, POST)
- **201 Created:** New resource created successfully (typically used for POST to create)
- **204 No Content:** Request successful with no return content (typically used for DELETE, PUT)
- **400 Bad Request:** Invalid request or missing necessary information
- **401 Unauthorized:** Request requires authentication and user is not logged in
- **403 Forbidden:** User does not have permission to perform this action
- **404 Not Found:** Resource does not exist or was not found
- **422 Unprocessable Entity:** Submitted data could not be processed (often in validation failures)

## 10. UI/UX Design
- **Modern design philosophy**:
  - Create intuitive, user-friendly interfaces
  - Ensure consistency throughout the application
  - Prioritize minimalist design while maintaining full functionality

- **Color palette and aesthetics**:
  - Use dark color scheme as primary theme with colors such as:
    - Background: bg-gray-800, bg-gray-900
    - Text: text-gray-200, text-gray-300
  - Ensure appropriate contrast for readability
  - If using light UI, use bg-white and text-black

## 11. Stimulus Handling
- **Only handle UI-related issues in Stimulus**
- Do not call APIs in Stimulus controllers
- Focus on user interaction handling and display

## 12. Ruby Style Conventions
- Prefer using symbols over strings
- In controllers, use `class User::` rather than `module User`
- Write concise, understandable, and natural Ruby code
- Use 2 spaces for indentation, no tabs

## 13. Notifications
- All alert and notice messages should be in English

## 14. Routes Checking
- Check routes before writing anything related to permissions

## 15. Reference Existing Files Before Writing New Code
- **Always use MCP proxy to analyze existing patterns first**:
```bash
# Analyze existing controller patterns
curl -s "http://localhost:5000/controller/manage/courses_controller.rb" | jq -r '.content' | grep -E "def "

# Check existing view structure  
curl -s "http://localhost:5000/view/manage/courses/index.html.erb" | jq -r '.content' | head -20

# Compare similar controllers
curl -s "http://localhost:5000/controller/dashboard/courses_controller.rb" | jq -r '.content' | grep -A5 -B5 "def index"
```

- **Ensure writing with similar UI logic and structure to existing files**:
  - Maintain style consistency
  - Apply similar patterns that have been used
  - Maintain the same data processing and display approach
  - Follow established naming conventions and structures

- **Avoid creating new patterns unless necessary**:
  - Using existing patterns helps maintain code consistency
  - Easier to maintain and extend later
  - Minimizes unexpected bugs and errors

## 16. Final Check
- Always greet with "Hi, boss Trọng" before writing code or solutions
- **Use MCP proxy to verify patterns before implementation**
- Ensure thorough self-testing before submitting
- Check routes again before writing anything related to permissions
