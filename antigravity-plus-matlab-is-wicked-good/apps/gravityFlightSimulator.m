function gravityFlightSimulator()
    % GRAVITYFLIGHTSIMULATOR - Interactive gravity and physics simulation
    % Creates a uifigure window embedding the gravity simulation web app

    % Create main figure with appropriate size
    fig = uifigure('Name', 'Defying Gravity', ...
                   'Position', [100 100 1200 800], ...
                   'Color', [0 0 0], ...
                   'AutoResizeChildren', 'off');

    % Get the path to the HTML file and icon
    appDir = fileparts(mfilename('fullpath'));
    htmlFile = fullfile(appDir, 'dist', 'index.html');
    iconFile = fullfile(appDir, 'dist', 'broom.png');

    % Set the app icon
    fig.Icon = iconFile;

    % Create uihtml component filling the entire figure
    h = uihtml(fig, 'Position', [0 0 fig.Position(3) fig.Position(4)]);
    h.HTMLSource = htmlFile;

    % Handle figure resize to keep uihtml fullscreen
    fig.SizeChangedFcn = @(src, ~) resizeHTML(src, h);

    % Optional: Set up event handling for MATLAB-JavaScript communication
    h.HTMLEventReceivedFcn = @(src, event) handleEvent(src, event);
end

function resizeHTML(fig, h)
    % Resize uihtml component to match figure size
    h.Position = [0 0 fig.Position(3) fig.Position(4)];
end

function handleEvent(~, event)
    % Handle events from JavaScript (if needed)
    eventName = event.HTMLEventName;
    eventData = event.HTMLEventData;

    try
        switch eventName
            case 'Log'
                % Log messages from JavaScript
                fprintf('[JS] %s\n', string(eventData));
            otherwise
                fprintf('Received event: %s\n', eventName);
        end
    catch ME
        fprintf('Error handling event: %s\n', ME.message);
    end
end
