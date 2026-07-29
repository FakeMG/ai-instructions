Give me all the flows of this system in text, not as a sequence diagram.
Class1.FunctionA -> Class2.FunctionB -> etc

---

Explain a flow. Go through each class that is involved in the flow to explain the code and the intention behind it. Focus on the why. All the leaf classes of a class must be explained before explaining that class. Follow this format:

```
[Class1](path/to/Class1.cs)
Class1.FunctionA:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code line by line, describing what it does and why it does in that way. Focus on the why.

Class1.FunctionB:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code line by line, describing what it does and why it does in that way. Focus on the why.

Continue with all functions in the class.

[Class2](path/to/Class2.cs)
Class2.FunctionA:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code line by line, describing what it does and why it does in that way. Focus on the why.

Class2.FunctionB:
- Why do we have this function? What is its purpose in the flow? How does it contribute to the overall functionality of the application?
- Explain the code line by line, describing what it does and why it does in that way. Focus on the why.

Continue with all functions in the class.

etc
```
- Leaf class: classes that you can understand without reading other classes.
- Non-leaf class: data classes and classes that are outside of the system.