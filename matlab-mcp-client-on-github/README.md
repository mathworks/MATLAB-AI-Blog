
<a id="TMP_6650"></a>

# MATLAB MCP Client Blog post
<!-- Begin Toc -->

## Table of Contents
&emsp;[0. Setup the interface to call OpenAI LLMs](#TMP_8ece)
 
&emsp;[1. Build the MCP client](#TMP_2f87)
 
&emsp;&emsp;[1.1. Connect to an MCP server endpoint](#TMP_4dce)
 
&emsp;&emsp;[1.2. Discover tools](#TMP_5845)
 
&emsp;&emsp;[1.3. Look up arguments required to call a tool](#TMP_8a88)
 
&emsp;[2. Integrate the MCP client with an LLM](#TMP_5839)
 
&emsp;&emsp;[2.1. Pass tools as a function to the model](#TMP_341c)
 
&emsp;&emsp;[2.2. Let the model select the tool](#TMP_23d0)
 
&emsp;&emsp;[2.3. Integrate in an agentic loop](#TMP_4750)
 
<!-- End Toc -->

This live script demonstrates how to easily build an MCP Client in MATLAB to connect with an MCP server and an LLM to call the server tools.


The example uses a single tool from a [prime sequence MCP server](<https://production-server-demo.mathworks-workshop.com/~files/mcp-production-server/index.html>). 

<a id="TMP_8ece"></a>

# 0. Setup the interface to call OpenAI LLMs

Make sure you get the latest version of the [LLM\-with\-MATLAB](https://github.com/matlab-deep-learning/llms-with-matlab) repo:

```matlab
gitclone("https://github.com/matlab-deep-learning/llms-with-matlab");
addpath(genpath("llms-with-matlab"))
```

Create a .env file with your OPENAI\_API\_KEY

```
OPENAI_API_KEY=sk-proj-xxxxx
```
```matlab
loadenv('.env')
```
<a id="TMP_2f87"></a>

# 1. Build the MCP client
<a id="TMP_4dce"></a>

## 1.1. Connect to an MCP server endpoint
```matlab
endpoint = "https://production-server-demo.mathworks-workshop.com/primeSequence/mcp";
client = mcpHTTPClient(endpoint)
```

```matlabTextOutput
client = 
  mcpHTTPClient with properties:

       Endpoint: "https://production-server-demo.mathworks-workshop.com/primeSequence/mcp"
    ServerTools: {[1x1 struct]}

```

<a id="TMP_5845"></a>

## 1.2. Discover tools

In this case there is only one tool:

```matlab
serverTools = client.ServerTools;
for i = 1:length(serverTools)
    disp(serverTools{i}.name)
    disp(serverTools{i}.description)
    disp('---')
end
```

```matlabTextOutput
primeSequence
Return the first N primes of the given sequence type. Four sequence types supported: Eisenstein, Balanced, Isolated and Gaussian.
---
```

<a id="TMP_8a88"></a>

## 1.3. Look up arguments required to call a tool
```matlab
tool1 = serverTools{1};
toolName = tool1.name;
client.ServerTools{1}.inputSchema
```

```matlabTextOutput
ans = struct with fields:
          type: 'object'
    properties: [1x1 struct]
      required: {2x1 cell}

```


The input schema informs which arguments or properties are required: 

```matlab
client.ServerTools{1}.inputSchema.properties
```

```matlabTextOutput
ans = struct with fields:
       n: [1x1 struct]
    type: [1x1 struct]

```

```matlab
client.ServerTools{1}.inputSchema.properties.n
```

```matlabTextOutput
ans = struct with fields:
           type: 'number'
    description: 'Length of the generated sequence'

```

```matlab
client.ServerTools{1}.inputSchema.properties.type
```

```matlabTextOutput
ans = struct with fields:
           type: 'string'
    description: 'Name of the sequence to generate'

```

```matlab
client.ServerTools{1}.inputSchema.required
```

```matlabTextOutput
ans = 2x1 cell array

'n'       
'type'    

```

<a id="TMP_5839"></a>

# 2. Integrate the MCP client with an LLM
<a id="TMP_341c"></a>

## 2.1. Pass tools as a function to the model

The following functions are provided by the LLMs with MATLAB repo. In this example, the OpenAI service is used to provide the Large Language Model.

```matlab
f = openAIFunction(serverTools)
```

```matlabTextOutput
f = 
  openAIFunction with properties:

    FunctionName: "primeSequence"
     Description: "Return the first N primes of the given sequence type. Four sequence types supported: Eisenstein, Balanced, Isolated and Gaussian."
      Parameters: [1x1 struct]

```

```matlab
model = openAIChat(Tools=f)
```

```matlabTextOutput
model = 
  openAIChat with properties:

           ModelName: "gpt-4o-mini"
         Temperature: 1
                TopP: 1
       StopSequences: [0x0 string]
             TimeOut: 10
        SystemPrompt: []
      ResponseFormat: "text"
     PresencePenalty: 0
    FrequencyPenalty: 0
       FunctionNames: "primeSequence"

```

<a id="TMP_23d0"></a>

## 2.2. Let the model select the tool

Let the LLM select which tool to call. Here there is only one tool to choose from:

```matlab
[~,completeOutput] = generate(model,"generate a sequence of 10 prime numbers")
```

```matlabTextOutput
completeOutput = struct with fields:
           role: 'assistant'
        content: []
     tool_calls: [4x1 struct]
        refusal: []
    annotations: []

```

```matlab
completeOutput.tool_calls
```


|Fields|id|type|function|
|:--:|:--:|:--:|:--:|
|1|'call_BCLBeQZobdMrOKOWq6B8R1Ba'|'function'|1x1 struct|
|2|'call_fFvnhWFIilNbdCXmZ2TISMvk'|'function'|1x1 struct|
|3|'call_89AFYa7hj2atkCisWiAFFtm0'|'function'|1x1 struct|
|4|'call_iktdTLjRNzVKUNXL9JzmfXcy'|'function'|1x1 struct|


<a id="TMP_4750"></a>

## 2.3. Integrate in an agentic loop

Now just integrate this logic in an agentic loop:

```matlab
toolRequest = completeOutput.tool_calls(1).function
```

```matlabTextOutput
toolRequest = struct with fields:
         name: 'primeSequence'
    arguments: '{"n": 10, "type": "Eisenstein"}'

```

```matlab
output = callTool(client,toolRequest)
```

```matlabTextOutput
output = "[2,5,11,17,23,29,41,47,53,59]"
```

