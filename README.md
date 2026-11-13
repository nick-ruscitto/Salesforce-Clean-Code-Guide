# Salesforce Clean Code Guide

A comprehensive guide to writing clean, maintainable, and testable Salesforce code following industry best practices and SOLID principles.

## Overview

This guide provides coding standards, architectural patterns, and working examples for Salesforce development. It covers Apex, Lightning Web Components, Aura Components, and testing strategies with a focus on maintainability, readability, and adherence to SOLID principles.

## Contents

### Style Guides

**[APEX_STYLE_GUIDE.md](./APEX_STYLE_GUIDE.md)**
- Naming conventions for classes, interfaces, variables, methods
- Formatting standards for code blocks, SOQL queries
- Comment and documentation guidelines
- Exception handling patterns

**[LWC_STYLE_GUIDE.md](./LWC_STYLE_GUIDE.md)**
- Lightning Web Component best practices
- Component composition and properties
- Event handling patterns
- Component styling guidelines
- Testing strategies for LWCs

**[AURA_STYLE_GUIDE.md](./AURA_STYLE_GUIDE.md)**
- Aura component naming conventions
- Component, application, and event patterns
- Single responsibility principles for Aura

**[FRONT_END_STYLE_GUIDE.md](./FRONT_END_STYLE_GUIDE.md)**
- HTML, CSS, and JavaScript formatting
- Naming conventions (kebab-case for classes/IDs)
- Front-end code organization

**[DATA_ACCESSOR_GUIDE.md](./DATA_ACCESSOR_GUIDE.md)**
- Data Access Object (DAO) pattern implementation
- Query and DML abstraction
- Mocking strategies for unit tests
- MVC pattern in Salesforce

**[UNIT_TEST_GUIDE.md](./UNIT_TEST_GUIDE.md)**
- Unit testing philosophy and best practices
- Writing effective tests beyond code coverage
- Avoiding false positives and false negatives
- Test-driven development approach

**[SOLID_GUIDE.md](./SOLID_GUIDE.md)**
- Single Responsibility Principle (SRP)
- Open/Closed Principle (OCP)
- Liskov Substitution Principle (LSP)
- Interface Segregation Principle (ISP)
- Dependency Inversion Principle (DIP)

### Example Projects

#### DAO Base Framework

Foundation classes for implementing the Data Access Object pattern in Salesforce.

**Classes:**
- `DmlInterface` - Base interface for all DAOs with DML operations
- `DmlBase` - Production implementation with real database operations
- `DmlBaseMock` - Test implementation with in-memory operations
- `MockIdGenerator` - Generates fake Salesforce IDs for testing
- `MockSObjectBuilder` - Builds SObjects with read-only fields for testing
- `DmlBaseTest` - Integration tests for base framework
- `MockIdGeneratorTest` - Tests for ID generation utility

**Purpose:**
Provides the infrastructure for creating DAOs throughout your application. All DAO implementations extend these base classes.

#### DAO Real World Example

Complete working example of the DAO pattern in a realistic scenario: an Account record page with contact management.

**Architecture:**
- **Data Layer**: AccountDAO, ContactDAO with implementations and mocks
- **Controller Layer**: AccountController (read), ContactController (read), ContactFormController (write)
- **Presentation Layer**: LWC components for displaying and managing data
- **Test Layer**: Comprehensive unit tests using mocks

**Components:**
- `accountContainer` - Orchestrates the account page
- `accountDetails` - Displays account information
- `accountContactList` - Shows contacts with create functionality
- `newContactForm` - Form for creating new contacts

**Demonstrates:**
- SOLID principles in action
- Separation of concerns (read vs write controllers)
- Mock-based unit testing without database dependencies
- Component communication patterns
- Full CRUD cycle with proper abstraction

**See:** [DAO Real World Example/README.md](./DAO%20Real%20World%20Example/README.md)

#### Trigger Facade Example

Example trigger implementation using the Facade design pattern with SOLID principles.

**Architecture:**
- **Trigger**: Switch statement delegating to facade
- **Facade**: Orchestrates business logic classes
- **Business Logic**: Specialized classes with single responsibilities

**Components:**
- `ContactTrigger` - Main trigger with switch on `operationType`
- `ContactTriggerFacade` - Coordinates handler execution
- `ContactEmailChangeFilter` - Finds contacts whose email changed
- `ContactEmailVerification` - Marks changed emails as unverified

**Demonstrates:**
- Facade pattern for trigger organization
- Single Responsibility Principle
- Clean separation between orchestration and implementation
- Maintainable and testable trigger architecture

**See:** [Trigger Facade Example/README.md](./Trigger%20Facade%20Example/README.md)

## Key Principles

### SOLID Principles

This guide emphasizes SOLID principles throughout:

- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Subtypes must be substitutable for base types
- **Interface Segregation**: Clients shouldn't depend on unused interfaces
- **Dependency Inversion**: Depend on abstractions, not concretions

### Testing Philosophy

- Unit tests are as important as production code
- Test behavior, not implementation
- Use mocks to isolate units under test
- Avoid false positives/negatives
- Aim for meaningful coverage, not just 75%

### Code Organization

- MVC pattern: Model (DAOs), View (LWC/Aura), Controller (Controllers)
- Separate read and write operations
- Keep classes small and focused
- Use dependency injection for testability
- Favor composition over inheritance

## How to Use This Guide

1. **Start with SOLID_GUIDE.md** to understand core principles
2. **Review relevant style guides** for your technology (Apex, LWC, Aura)
3. **Study the DAO pattern** via DATA_ACCESSOR_GUIDE.md
4. **Explore examples** to see patterns in action
5. **Apply to your projects** incrementally

## Repository Structure

```
Salesforce Clean Code Guide/
├── README.md (this file)
├── APEX_STYLE_GUIDE.md
├── LWC_STYLE_GUIDE.md
├── AURA_STYLE_GUIDE.md
├── FRONT_END_STYLE_GUIDE.md
├── DATA_ACCESSOR_GUIDE.md
├── UNIT_TEST_GUIDE.md
├── SOLID_GUIDE.md
├── DAO Base Framework/
│   └── classes/
│       ├── DmlInterface.cls
│       ├── DmlBase.cls
│       ├── DmlBaseMock.cls
│       ├── MockIdGenerator.cls
│       └── MockSObjectBuilder.cls
├── DAO Real World Example/
│   ├── README.md
│   ├── classes/ (Controllers, DAOs, Tests)
│   └── lwc/ (Components)
└── Trigger Facade Example/
    ├── README.md
    ├── classes/ (Facade, Business Logic)
    └── triggers/
```

## Benefits

**Maintainability**
- Clear patterns make code easier to understand and modify
- Single Responsibility makes changes isolated and safe

**Testability**
- Dependency injection enables true unit tests
- Mocking eliminates database dependencies
- Tests run faster and more reliably

**Scalability**
- Well-organized code scales with team size
- Consistent patterns reduce cognitive load
- Easy to onboard new developers

**Quality**
- SOLID principles prevent common pitfalls
- Style guides ensure consistency
- Testing philosophy catches bugs early

## Contributing

This guide represents best practices for enterprise Salesforce development. It evolves based on experience and industry standards.

## License

This guide is provided as-is for educational and professional development purposes.
