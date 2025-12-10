%[text] # MATLAB MCP Client Blog post
%[text] 
%[text:tableOfContents]{"heading":"Table of Contents"}
%[text] This live script demonstrates how to easily build an MCP Client in MATLAB to connect with an MCP server and an LLM to call the server tools.
%[text] The example uses a single tool from a [<u>prime sequence MCP server</u>](https://production-server-demo.mathworks-workshop.com/~files/mcp-production-server/index.html). 
%[text] 
%%
%[text] ## 0. Setup the interface to call OpenAI LLMs
%[text] Make sure you get the latest version of the [<u>LLM-with-MATLAB</u>](https://github.com/matlab-deep-learning/llms-with-matlab) repo:
gitclone("https://github.com/matlab-deep-learning/llms-with-matlab");
addpath(genpath("llms-with-matlab"))
%%
%[text] Create a .env file with your OPENAI\_API\_KEY
%[text] ```
%[text] OPENAI_API_KEY=sk-proj-xxxxx
%[text] ```
loadenv('.env')
%%
%[text] ## 1. Build the MCP client
%[text] ### 1.1. Connect to an MCP server endpoint
endpoint = "https://production-server-demo.mathworks-workshop.com/primeSequence/mcp";
client = mcpHTTPClient(endpoint) %[output:5913aed8]
%%
%[text] ### 1.2. Discover tools
%[text] In this case there is only one tool:
serverTools = client.ServerTools;
for i = 1:length(serverTools) %[output:group:7d5d0ca6]
    disp(serverTools{i}.name) %[output:0115224e]
    disp(serverTools{i}.description) %[output:70d9d548]
    disp('---') %[output:91cadb71]
end %[output:group:7d5d0ca6]
%%
%[text] ### 1.3. Look up arguments required to call a tool
tool1 = serverTools{1};
toolName = tool1.name;
client.ServerTools{1}.inputSchema %[output:08c168fb]
%[text] The input schema informs which arguments or properties are required: 
client.ServerTools{1}.inputSchema.properties %[output:12894683]
client.ServerTools{1}.inputSchema.properties.n %[output:8aa4449b]
client.ServerTools{1}.inputSchema.properties.type %[output:4c769874]
client.ServerTools{1}.inputSchema.required %[output:0f2bdf26]
%%
%[text] ## 2. Integrate the MCP client with an LLM
%[text] ### 2.1. Pass tools as a function to the model
%[text] The following functions are provided by the LLMs with MATLAB repo. In this example, the OpenAI service is used to provide the Large Language Model.
f = openAIFunction(serverTools) %[output:78a42157]
model = openAIChat(Tools=f) %[output:9d97b291]
%%
%[text] ### 2.2. Let the model select the tool
%[text] Let the LLM select which tool to call. Here there is only one tool to choose from:
[~,completeOutput] = generate(model,"generate a sequence of 10 prime numbers") %[output:390d4779]
completeOutput.tool_calls %[output:42f5da24]
%%
%[text] ### 2.3. Integrate in an agentic loop
%[text] Now just integrate this logic in an agentic loop:
toolRequest = completeOutput.tool_calls(1).function %[output:0b8ee492]
output = callTool(client,toolRequest) %[output:3f4342ce]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
%[output:5913aed8]
%   data: {"dataType":"textualVariable","outputData":{"name":"client","value":"  <a href=\"matlab:helpPopup('mcpHTTPClient')\" style=\"font-weight:bold\">mcpHTTPClient<\/a> with properties:\n\n       Endpoint: \"https:\/\/production-server-demo.mathworks-workshop.com\/primeSequence\/mcp\"\n    ServerTools: {[1×1 struct]}\n"}}
%---
%[output:0115224e]
%   data: {"dataType":"text","outputData":{"text":"primeSequence\n","truncated":false}}
%---
%[output:70d9d548]
%   data: {"dataType":"text","outputData":{"text":"Return the first N primes of the given sequence type. Four sequence types supported: Eisenstein, Balanced, Isolated and Gaussian.\n","truncated":false}}
%---
%[output:91cadb71]
%   data: {"dataType":"text","outputData":{"text":"---\n","truncated":false}}
%---
%[output:08c168fb]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"          type: 'object'\n    properties: [1×1 struct]\n      required: {2×1 cell}\n"}}
%---
%[output:12894683]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"       n: [1×1 struct]\n    type: [1×1 struct]\n"}}
%---
%[output:8aa4449b]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"           type: 'number'\n    description: 'Length of the generated sequence'\n"}}
%---
%[output:4c769874]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"ans","value":"           type: 'string'\n    description: 'Name of the sequence to generate'\n"}}
%---
%[output:0f2bdf26]
%   data: {"dataType":"matrix","outputData":{"columns":1,"header":"2×1 cell array","name":"ans","rows":2,"type":"cell","value":[["'n'"],["'type'"]]}}
%---
%[output:78a42157]
%   data: {"dataType":"textualVariable","outputData":{"name":"f","value":"  <a href=\"matlab:helpPopup('openAIFunction')\" style=\"font-weight:bold\">openAIFunction<\/a> with properties:\n\n    FunctionName: \"primeSequence\"\n     Description: \"Return the first N primes of the given sequence type. Four sequence types supported: Eisenstein, Balanced, Isolated and Gaussian.\"\n      Parameters: [1×1 struct]\n"}}
%---
%[output:9d97b291]
%   data: {"dataType":"textualVariable","outputData":{"name":"model","value":"  <a href=\"matlab:helpPopup('openAIChat')\" style=\"font-weight:bold\">openAIChat<\/a> with properties:\n\n           ModelName: \"gpt-4o-mini\"\n         Temperature: 1\n                TopP: 1\n       StopSequences: [0×0 string]\n             TimeOut: 10\n        SystemPrompt: []\n      ResponseFormat: \"text\"\n     PresencePenalty: 0\n    FrequencyPenalty: 0\n       FunctionNames: \"primeSequence\"\n"}}
%---
%[output:390d4779]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"completeOutput","value":"           role: 'assistant'\n        content: []\n     tool_calls: [4×1 struct]\n        refusal: []\n    annotations: []\n"}}
%---
%[output:42f5da24]
%   data: {"dataType":"tabular","outputData":{"columnNames":["id","type","function"],"columns":3,"cornerText":"Fields","dataTypes":["char","char","struct"],"header":"4×1 struct array with fields:","name":"ans","rows":4,"type":"struct","value":[["'call_BCLBeQZobdMrOKOWq6B8R1Ba'","'function'","1×1 struct"],["'call_fFvnhWFIilNbdCXmZ2TISMvk'","'function'","1×1 struct"],["'call_89AFYa7hj2atkCisWiAFFtm0'","'function'","1×1 struct"],["'call_iktdTLjRNzVKUNXL9JzmfXcy'","'function'","1×1 struct"]]}}
%---
%[output:0b8ee492]
%   data: {"dataType":"textualVariable","outputData":{"header":"struct with fields:","name":"toolRequest","value":"         name: 'primeSequence'\n    arguments: '{\"n\": 10, \"type\": \"Eisenstein\"}'\n"}}
%---
%[output:3f4342ce]
%   data: {"dataType":"textualVariable","outputData":{"name":"output","value":"\"[2,5,11,17,23,29,41,47,53,59]\""}}
%---
