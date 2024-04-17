#!/usr/bin/ruby
#@author: Rahul Ghuge.

require 'webrick'
require 'json'

#set the stdout to file.
#$stdout = StringIO.new

#old puts with new puts
old_put = puts
$__ = []

def puts(*arg)
    $__ += arg
end

$OUTPUT = nil
$LAST_RUN_COMPLETED = false

class Evaluator

    def initialize(binding = TOPLEVEL_BINDING)
      @binding = binding
    end
  
    def eval(input)

        # Binding#source_location is available since Ruby 2.6.
        if @binding.respond_to? :source_location
            "#{@binding.eval(input, *@binding.source_location).inspect}"
        else
            "#{@binding.eval(input).inspect}"
        end
        rescue Exception => exc
            return exc
    end
  
end

class IW_RUBY

    def initialize
         @Evaluator = Evaluator.new
    end

    def run(input)
        if input == 'exit' or input == 'exit()'
            $server.shutdown
        else
            begin
                output = @Evaluator.eval(input)
                if output == nil
                    $OUTPUT == ""
                else
                    $OUTPUT =  $__.join("\n") + "\n" + output
                    $__ = []
                end
                $LAST_RUN_COMPLETED = true
            rescue Exception => e
                $OUTPUT = "#{e}\n"
                $LAST_RUN_COMPLETED = true
            end
        end
    end
end

#ruby object which allow us to run the code.
IWRB = IW_RUBY.new
#webrick server. 
$server = WEBrick::HTTPServer.new(Port: 8080)

# Serve a simple HTML page
$server.mount_proc '/' do |req, res|
  res.content_type = 'text/html'
  res.body = <<~HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <title>Infowork Ruby Console!</title>
    <!-- Load Monaco Editor -->
    <script src="https://cdn.jsdelivr.net/npm/monaco-editor@latest/min/vs/loader.js"></script>
    <style>
      /* Define the size of the container for the editor */
      .editor-container {
        width: 800px;
        border: 1px solid #ccc;
        margin-bottom: 20px;
      }
      .output-container {
        background-color: #1e1e1e;
        color : white;
        border: 1px solid #ccc;
        border-radius: 10px;
        padding: 5px;
        margin-top: 5px;
        min-height: 30px; /* Minimum height to maintain visibility */
        overflow-y: auto; /* Enable vertical scrollbar if content exceeds height */
      }
    </style>
  </head>
  <body>
    <div id="editors" style="background-color: #6f6f6f; border-radius: 10px;"></div>
    <button onclick="addCodeWindow()" style="background-color: transparent; border-radius: 5px; color: none;">+</button>
  
    <script>
        require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@latest/min/vs' }});
    
        let editorCount = 1;
    
        function createEditor(id) {
            const editorContainer = document.createElement('div');
            editorContainer.style.width = "100%";
            editorContainer.classList.add('editor-container');
            editorContainer.innerHTML = `
            <div id="editor${id}" style="height: 100px; width: 100%; margin: 5px;"></div>
            <button onclick="runCode(${id})" style="border: none;background-color: transparent;"><svg width="24" height="24" xmlns="http://www.w3.org/2000/svg" fill="white" stroke=1 fill-rule="evenodd" clip-rule="evenodd"><path d="M23 12l-22 12v-24l22 12zm-21 10.315l18.912-10.315-18.912-10.315v20.63z"/></svg>
            </button>
            <div id="output${id}" class="output-container" style="flex-grow:auto;"></div>
            `;
    
            document.getElementById('editors').appendChild(editorContainer);
    
            // Create Monaco Editor instance
            require(['vs/editor/editor.main'], function() {
            const editor = monaco.editor.create(document.getElementById(`editor${id}`), {
                value: '',
                language: 'ruby',
                theme: 'vs-dark'
            });
            // Register completion provider.
            monaco.languages.registerCompletionItemProvider('ruby', {
                    provideCompletionItems: function(model, position) {
                        // Fetch autocomplete suggestions from the backend service here
                        // Return autocomplete suggestions based on the context
                        return {
                            suggestions: [
                                {
                                    label: "for",
                                    kind: monaco.languages.CompletionItemKind.Text,
                                    insertText: "for var in  do\\n \\nend"
                                },
                                {
                                    label: "if",
                                    kind: monaco.languages.CompletionItemKind.Text,
                                    insertText: "if  do\\n \\nend"
                                },
                                {
                                    label: "ifelsif",
                                    kind: monaco.languages.CompletionItemKind.Text,
                                    insertText: "if  do\\n \\nelsif \\n \\nend"
                                },
                                {
                                    label: "while",
                                    kind: monaco.languages.CompletionItemKind.Text,
                                    insertText: "while condition  do\\n \\nend"
                                },
                                {
                                    label: "each",
                                    kind: monaco.languages.CompletionItemKind.Text,
                                    insertText: "each |e|\\n \\nend"
                                },
                                // Add more suggestions based on your backend response
                            ]
                        };
                    }
                });
            });
        }
    
        function addCodeWindow() {
            createEditor(++editorCount);
        }
    
        async function runCode(id) {
            // Get the code from the editor with the given ID and simulate running it
            const code = monaco.editor.getModels()[id - 1].getValue();
    
            try {
            // Send the code snippet to the '/run' endpoint using a POST request
                const runResponse = await fetch('/run', {
                    method: 'POST',
                    headers: {
                    'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({ code: code })
                });
    
                // Poll the '/getResult' endpoint until receiving the output in JSON format
                let result;
                while (true) {
                    const getResultResponse = await fetch('/getResult');
                    if (getResultResponse.ok) {
                        result = await getResultResponse.json();

                        if (result.output != null) {
                            break; // Exit the loop once output is received
                        }
                    }
                    // Wait for a short duration before polling again
                    await new Promise(resolve => setTimeout(resolve, 500));
                }
        
                // Display the received output in the respective output container
                document.getElementById(`output${id}`).innerText = `O/P ${id}:\n${result.output}`;
            } catch (error) {
                console.error('Error:', error);
            }
        }
        // Initial code window
        createEditor(editorCount);
        // closes the program on 
        window.addEventListener('beforeunload', async function (e) {
            //const code = monaco.editor.getModels()[id - 1].getValue();
            const runResponse = await fetch('/run', {
                method: 'POST',
                headers: {
                'Content-Type': 'application/json'
                },
                body: JSON.stringify({ code: "exit()"})
            });
        });
    </script>
  </body>
  </html>
  HTML
end

# Endpoint for POST request to simulate code execution
$server.mount_proc('/run') do |req, res|
    if req.request_method == 'POST'
        # Retrieve code from the request
        code = JSON.parse(req.body)#['code']
        p "code is #{code}"
        IWRB.run(code["code"])
        $LAST_RUN_COMPLETED = false
        res.status = 200
        res['Content-Type'] = 'application/json'
        res.body = "Ok"
    else
        res.status = 405 # Method Not Allowed
        res.body = 'Only POST method is allowed for this endpoint'
    end
end

# Endpoint for GET request to get results
$server.mount_proc('/getResult') do |req, res|
    res.status = 200
    res['Content-Type'] = 'application/json'

    if $OUTPUT != nil
        res.body = { :output => $OUTPUT }.to_json
        $OUTPUT = nil;
    else
        res.body = {:output =>  nil}.to_json
    end
    #puts "output is #{$OUTPUT}"
end

#open webpage in default browser.
system "start http://localhost:8080/"

#start the server.
trap('INT') { $server.shutdown }
$server.start
