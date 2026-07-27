A function can point to multiple functions, and a function can be pointed to by multiple functions. The flow is not necessarily linear, but it is always directed. The flow should be described in the order of execution.

Explain what and why for each line of code from start to the end of the flow. Focus on the why.

Find all the flows in [Assigning](Assets/_Project/_Scripts/Assigning/) and [Structures](Assets/_Project/_Scripts/Structures/) , for each flow walk me through the code, explain the code and the intention behind it. Follow this format:

```
# 1. Name of the Flow 1

Class1.FunctionA -> Class2.FunctionB -> etc

[Class1](path/to/Class1.cs)
Class1.FunctionA:
- Line 5-10: Explain the code line by line, describing what it does and why it does in that way
- Line 11-15: etc

Class1.FunctionB:
- Line 17-20: Explain the code line by line, describing what it does and why it does in that way
- Line 21-25: etc

Continue with all functions in the class.

[Class2](path/to/Class2.cs)
Class2.FunctionA:
- Line 5-10: Explain the code line by line, describing what it does and why it does in that way
- Line 11-15: etc

Class2.FunctionB:
- Line 17-20: Explain the code line by line, describing what it does and why it does in that way
- Line 21-25: etc

Continue with all functions in the class.

etc

# 2. Name of the Flow 2
...
# N. Name of the Flow N
```