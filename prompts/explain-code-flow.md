# List all features of the system
I have no knowledge about how this system works. List all the features the system has. What problems does each feature solve?

Prefer explanations that are:
- Beginner-friendly, assuming no prior knowledge.
- Plain-language first, technical terms second.
- Focused on one class or concept at a time.
- Clear about each component’s responsibility.
- Explicit about differences between similar concepts.
- Shown as short execution flows.
- Grounded in practical examples.
- Supported by small, realistic code snippets when useful.
- Clear about what a system does not do.
- Concise, without unnecessary architecture jargon.

# List all user facing flows
Give me all the user facing flows of this system.
```
1. Flow 1 Name
- Description of Flow 1
2. Flow 2 Name
- Description of Flow 2
etc.
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