# Agent Role Mapping

## Overview

This document defines how the multi-agent system maps to software development workflows and responsibilities.

## Agent Responsibilities

### **Requirements Analyst** (PM/Analyst Role)
**Primary Role**: Project management, requirements clarification, scope decisions

**Responsibilities**:
- Analyze and clarify user requirements
- Create implementation plans and project phases
- Identify dependencies and constraints
- Define acceptance criteria and success metrics
- Flag scope issues and technical challenges
- Document business requirements

**Output Status**: `READY_FOR_DEVELOPMENT`

**When to Use**:
- Starting a new feature or project phase
- Analyzing bug reports or issues
- Clarifying ambiguous requirements
- Creating project roadmaps
- Auditing project scope

---

### **Architect** (Technical Design Role)
**Primary Role**: System architecture, technical design, high-level decisions

**Responsibilities**:
- Design system architecture and structure
- Make technology and framework choices
- Design APIs, interfaces, and data models
- Plan integration strategies
- Document design decisions and rationale
- Create technical specifications
- Consider security, performance, and scalability

**Output Status**: `READY_FOR_IMPLEMENTATION`

**When to Use**:
- Designing new features or systems
- Planning refactoring approaches
- Making technology choices
- Designing APIs or interfaces
- Planning system integrations
- Addressing architectural concerns

---

### **Implementer** (Development Role)
**Primary Role**: Hands-on coding, feature implementation, code writing

**Responsibilities**:
- Write production-quality code
- Implement features per specifications
- Follow coding standards and conventions
- Handle edge cases and errors
- Integrate with existing codebase
- Add appropriate logging and comments
- Ensure code quality and maintainability

**Output Status**: `READY_FOR_TESTING` or `IMPLEMENTATION_COMPLETE`

**When to Use**:
- Implementing designed features
- Writing production code
- Fixing bugs
- Refactoring code
- Adding new functionality
- Integrating third-party libraries

---

### **Tester** (Quality Assurance Role)
**Primary Role**: Testing strategy, test implementation, quality validation

**Responsibilities**:
- Design comprehensive test strategies
- Write unit, integration, and end-to-end tests
- Execute tests and analyze results
- Validate against requirements
- Test edge cases and error handling
- Ensure code coverage and quality
- Document test results and issues

**Output Status**: `TESTING_COMPLETE`

**When to Use**:
- After implementation is complete
- Validating bug fixes
- Regression testing
- Performance testing
- Integration testing
- Quality assurance validation

---

### **Documenter** (Documentation Role)
**Primary Role**: Documentation creation, maintenance, and organization

**Responsibilities**:
- Write user guides and tutorials
- Create API documentation
- Document architecture and design
- Write code comments and docstrings
- Create examples and code samples
- Update existing documentation
- Maintain documentation consistency

**Output Status**: `DOCUMENTATION_COMPLETE`

**When to Use**:
- After feature implementation
- Updating existing documentation
- Creating user guides
- Documenting APIs
- Writing tutorials
- Creating migration guides

---

## Standard Workflow Patterns

### Complete Feature Development
```
Requirements Analyst → Architect → Implementer → Tester → Documenter
```

**Flow**:
1. **Requirements Analyst**: Analyzes requirements, creates plan → `READY_FOR_DEVELOPMENT`
2. **Architect**: Designs system architecture → `READY_FOR_IMPLEMENTATION`
3. **Implementer**: Writes production code → `READY_FOR_TESTING`
4. **Tester**: Validates functionality → `TESTING_COMPLETE`
5. **Documenter**: Creates documentation → `DOCUMENTATION_COMPLETE`

---

### Bug Fix Workflow
```
Requirements Analyst → Architect → Implementer → Tester
```

**Flow**:
1. **Requirements Analyst**: Analyzes bug, identifies scope → `READY_FOR_DEVELOPMENT`
2. **Architect**: Designs fix approach → `READY_FOR_IMPLEMENTATION`
3. **Implementer**: Implements fix → `READY_FOR_TESTING`
4. **Tester**: Validates fix, regression testing → `TESTING_COMPLETE`

---

### Hotfix Workflow (Critical Issues)
```
Implementer → Tester
```

**Flow**:
1. **Implementer**: Quick fix implementation → `READY_FOR_TESTING`
2. **Tester**: Emergency validation → `TESTING_COMPLETE`

---

### Refactoring Workflow
```
Architect → Implementer → Tester → Documenter
```

**Flow**:
1. **Architect**: Designs refactoring strategy → `READY_FOR_IMPLEMENTATION`
2. **Implementer**: Refactors code → `READY_FOR_TESTING`
3. **Tester**: Regression testing → `TESTING_COMPLETE`
4. **Documenter**: Updates technical docs → `DOCUMENTATION_COMPLETE`

---

### Documentation Update Workflow
```
Requirements Analyst → Documenter → Tester
```

**Flow**:
1. **Requirements Analyst**: Audits documentation needs → `READY_FOR_DEVELOPMENT`
2. **Documenter**: Updates documentation → `DOCUMENTATION_COMPLETE`
3. **Tester**: Validates accuracy of examples → `TESTING_COMPLETE`

---

## Agent Selection Guidelines

### Choose Requirements Analyst when:
- ✅ Starting a new feature or project
- ✅ Requirements are unclear or ambiguous
- ✅ Need to analyze bug reports
- ✅ Planning project phases
- ✅ Defining acceptance criteria
- ❌ **NOT** for technical implementation decisions
- ❌ **NOT** for writing code

### Choose Architect when:
- ✅ Need to design system architecture
- ✅ Making technology or framework choices
- ✅ Designing APIs or interfaces
- ✅ Planning major refactoring
- ✅ Need to make technical trade-off decisions
- ❌ **NOT** for writing production code
- ❌ **NOT** for defining business requirements

### Choose Implementer when:
- ✅ Ready to write production code
- ✅ Architecture/design is complete
- ✅ Implementing features or bug fixes
- ✅ Refactoring existing code
- ✅ Integrating third-party code
- ❌ **NOT** for designing architecture
- ❌ **NOT** for writing tests

### Choose Tester when:
- ✅ Implementation is complete
- ✅ Need to validate functionality
- ✅ Writing test suites
- ✅ Regression testing
- ✅ Performance validation
- ❌ **NOT** for implementing features
- ❌ **NOT** for architectural decisions

### Choose Documenter when:
- ✅ Feature is implemented and tested
- ✅ Need to update documentation
- ✅ Writing user guides
- ✅ Creating API documentation
- ✅ Adding code examples
- ❌ **NOT** for writing production code
- ❌ **NOT** for making technical decisions

---

## Status Transition Guide

| Current Status | Recommended Next Agent |
|----------------|----------------------|
| *Starting New Work* | Requirements Analyst |
| `READY_FOR_DEVELOPMENT` | Architect |
| `READY_FOR_IMPLEMENTATION` | Implementer |
| `IMPLEMENTATION_COMPLETE` | Tester |
| `READY_FOR_TESTING` | Tester |
| `TESTING_COMPLETE` | Documenter (optional) or Complete |
| `DOCUMENTATION_COMPLETE` | Complete |

---

## Communication Between Agents

### Information Handoffs

**Requirements Analyst → Architect**:
- Feature requirements and acceptance criteria
- Business constraints and limitations
- Technical challenges identified
- Project scope and phases

**Architect → Implementer**:
- System architecture and design
- API/interface specifications
- Technical decisions and rationale
- Integration guidance
- Implementation priorities

**Implementer → Tester**:
- Completed features and changes
- Edge cases to test
- Known limitations
- Integration points
- Suggested test scenarios

**Tester → Documenter**:
- Validated functionality
- Usage patterns observed
- Edge cases discovered
- Common issues encountered

---

## Benefits of This Approach

1. **Clear Separation of Concerns**: Each agent focuses on its specialty
2. **Quality Assurance**: Multiple review points in workflow
3. **Comprehensive Coverage**: All aspects of development covered
4. **Flexible Workflows**: Adapt agent sequence to project needs
5. **Scalable**: Easy to add more specialized agents
6. **Traceable**: Clear status transitions and handoffs

---

## Customization for Your Project

[**NOTE TO TEMPLATE USER**: Customize agent workflows for your project]

Consider your project's specific needs:
- **Parallel Development**: Can multiple agents work simultaneously?
- **Skip Steps**: Which agents are optional for your workflow?
- **Additional Agents**: Do you need specialized agents?
- **Custom Workflows**: What are your common development patterns?

---

This mapping ensures agents work efficiently within their expertise while maintaining comprehensive coverage of all development aspects.
