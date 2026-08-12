# List all features of the system
I have no knowledge about how this system works. List all the features the system has. What problems does each feature solve?

Follow this format:
```
# Overview of the system
- What is the system about? What is its purpose? What problem does it solve? How does it contribute to the overall functionality of the application?

## 1. [Feature Name 1]
- What is the feature about? What is its purpose? What problem does it solve? How does it contribute to the overall functionality of the system?

## N. [Feature Name N]
```

Prefer explanations that are:
- Beginner-friendly, assuming no prior knowledge.
- Plain-language first, technical terms second.
- Focused on one class or concept at a time.
- Clear about each component’s responsibility.
- Explicit about differences between similar concepts.
- Grounded in practical examples.
- Supported by small, realistic code snippets when useful.
- Clear about what a system does not do.
- Concise, without unnecessary architecture jargon.

# Explain a class
What is the focused purpose and responsibility of the class? Why does it exist? What problem does it solve? Use simple words.

Follow this format:
```
# Focused purpose and responsibility of Class1
# Why does Class1 exist? What problem does it solve? How does it contribute to the overall functionality of the application?
# What it does not do
```

<!-- All the leaf classes of a class must be explained before explaining that class. Skip classes that have already been explained.
- Leaf class: classes that you can understand without reading other classes.
- Non-leaf class: data classes and classes that are outside of the system. -->

# List all main flows
Give me all the main flows of this feature in text, not as a sequence diagram. Don't dump the entire codebase. Focus on the main flows that are critical to the feature's functionality. Use this format:
```
Class1.FunctionA -> Class2.FunctionB -> etc
```

---

# Explain a flow

Give me the flow in text, not as a sequence diagram:
```
Class1.FunctionA -> Class2.FunctionB -> etc
```

Go through each class involved in the flow, explaining the functions involved and the intention behind each one. Focus on the why. All the leaf classes of a class must be explained before explaining that class. Skip classes that have already been explained. Use simple words. Follow this format:

```
[Class1](path/to/Class1.cs)
Class1.FunctionA:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code, describing what it does and why it does in that way. Focus on the why.

Class1.FunctionB:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code, describing what it does and why it does in that way. Focus on the why.

Continue with all functions in the class.

[Class2](path/to/Class2.cs)
Class2.FunctionA:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code, describing what it does and why it does in that way. Focus on the why.

Class2.FunctionB:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code, describing what it does and why it does in that way. Focus on the why.

Continue with all functions in the class.

etc
```
- Leaf class: classes that you can understand without reading other classes.
- Non-leaf class: data classes and classes that are outside of the system.