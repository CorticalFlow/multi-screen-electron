#!/bin/bash

# A script to create a React Electron app with 6 screens using Electron Forge

echo "Creating multi-screen Electron app with React..."

# Create a new directory for the project
mkdir multi-screen-electron-app
cd multi-screen-electron-app

# Initialize a new Electron Forge project with webpack template
echo "Initializing Electron Forge project with webpack template..."
npx create-electron-app . --template=webpack

# Install React and related dependencies
echo "Installing React and dependencies..."
npm install --save react react-dom
npm install --save-dev @babel/core @babel/preset-react babel-loader

# Create a .babelrc file for React
echo "Creating .babelrc for React support..."
echo '{
  "presets": ["@babel/preset-react"]
}' > .babelrc

# Update webpack.rules.js to support JSX
echo "Updating webpack configuration for JSX support..."
cat > webpack.rules.js << 'EOL'
module.exports = [
  // Add support for native node modules
  {
    // We're specifying native_modules in the test because the asset relocator loader generates a
    // "fake" .node file which is really a cjs file.
    test: /native_modules[/\\].+\.node$/,
    use: 'node-loader',
  },
  {
    test: /[/\\]node_modules[/\\].+\.(m?js|node)$/,
    parser: { amd: false },
    use: {
      loader: '@vercel/webpack-asset-relocator-loader',
      options: {
        outputAssetBase: 'native_modules',
      },
    },
  },
  {
    test: /\.(js|jsx)$/,
    exclude: /(node_modules|\.webpack)/,
    use: {
      loader: 'babel-loader',
      options: {
        presets: ['@babel/preset-react']
      }
    }
  }
];
EOL

# Create webpack.renderer.config.js with proper JSX support
echo "Creating webpack.renderer.config.js with proper JSX support..."
cat > webpack.renderer.config.js << 'EOL'
const rules = require('./webpack.rules');

rules.push({
  test: /\.css$/,
  use: [{ loader: 'style-loader' }, { loader: 'css-loader' }],
});

module.exports = {
  // Put your normal webpack config below here
  module: {
    rules,
  },
  resolve: {
    extensions: ['.js', '.jsx', '.json', '.css']
  }
};
EOL

# Create webpack.main.config.js with proper JSX support
echo "Creating webpack.main.config.js with proper JSX support..."
cat > webpack.main.config.js << 'EOL'
module.exports = {
  /**
   * This is the main entry point for your application, it's the first file
   * that runs in the main process.
   */
  entry: './src/main.js',
  // Put your normal webpack config below here
  module: {
    rules: require('./webpack.rules'),
  },
  resolve: {
    extensions: ['.js', '.jsx', '.json']
  }
};
EOL

# Update package.json to use JSX
sed -i 's/"renderer.js"/"renderer.jsx"/g' package.json

# Create proper forge.config.js with explicit renderer.jsx reference
echo "Creating forge.config.js with proper renderer.jsx configuration..."
cat > forge.config.js << 'EOL'
const { FusesPlugin } = require('@electron-forge/plugin-fuses');
const { FuseV1Options, FuseVersion } = require('@electron/fuses');

module.exports = {
  packagerConfig: {
    asar: true,
  },
  rebuildConfig: {},
  makers: [
    {
      name: '@electron-forge/maker-squirrel',
      config: {},
    },
    {
      name: '@electron-forge/maker-zip',
      platforms: ['darwin'],
    },
    {
      name: '@electron-forge/maker-deb',
      config: {},
    },
    {
      name: '@electron-forge/maker-rpm',
      config: {},
    },
  ],
  plugins: [
    {
      name: '@electron-forge/plugin-auto-unpack-natives',
      config: {},
    },
    {
      name: '@electron-forge/plugin-webpack',
      config: {
        mainConfig: './webpack.main.config.js',
        renderer: {
          config: './webpack.renderer.config.js',
          entryPoints: [
            {
              html: './src/index.html',
              js: './src/renderer.jsx',
              name: 'main_window',
              preload: {
                js: './src/preload.js',
              },
            },
          ],
        },
      },
    },
    // Fuses are used to enable/disable various Electron functionality
    // at package time, before code signing the application
    new FusesPlugin({
      version: FuseVersion.V1,
      [FuseV1Options.RunAsNode]: false,
      [FuseV1Options.EnableCookieEncryption]: true,
      [FuseV1Options.EnableNodeOptionsEnvironmentVariable]: false,
      [FuseV1Options.EnableNodeCliInspectArguments]: false,
      [FuseV1Options.EnableEmbeddedAsarIntegrityValidation]: true,
      [FuseV1Options.OnlyLoadAppFromAsar]: true,
    }),
  ],
};
EOL

# Create the main process file
echo "Creating main process file..."
cat > src/main.js << 'EOL'
const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) {
  app.quit();
}

// Array to store our windows
const windows = [];

// Data service modules
const services = [
  require('./services/service1'),
  require('./services/service2'),
  require('./services/service3'),
  require('./services/service4'),
  require('./services/service5'),
  require('./services/service6')
];

const createWindows = () => {
  // Get all displays
  const displays = screen.getAllDisplays();
  const primaryDisplay = screen.getPrimaryDisplay();
  
  // Hardcoded setup for 6 screens (even if fewer are available)
  for (let i = 0; i < 6; i++) {
    // Use the actual display if available, otherwise use primary
    const display = displays[i] || primaryDisplay;
    
    // Create the browser window.
    const mainWindow = new BrowserWindow({
      x: display.bounds.x,
      y: display.bounds.y,
      width: display.bounds.width,
      height: display.bounds.height,
      fullscreen: true,
      webPreferences: {
        preload: MAIN_WINDOW_PRELOAD_WEBPACK_ENTRY,
        nodeIntegration: false,
        contextIsolation: true,
      },
    });

    // Load the renderer for this screen
    mainWindow.loadURL(MAIN_WINDOW_WEBPACK_ENTRY + `?screen=${i}`);
    
    // Add event listener to check if the window loaded successfully
    mainWindow.webContents.on('did-finish-load', () => {
      console.log(`Screen ${i} loaded successfully`);
    });

    // Add error handler for failed loads
    mainWindow.webContents.on('did-fail-load', (event, errorCode, errorDescription) => {
      console.error(`Screen ${i} failed to load: ${errorDescription}`);
      // Try to reload after a short delay
      setTimeout(() => {
        console.log(`Attempting to reload screen ${i}...`);
        mainWindow.loadURL(MAIN_WINDOW_WEBPACK_ENTRY + `?screen=${i}`);
      }, 1000);
    });
    
    // Set up IPC handlers for this screen
    setupIPC(i, mainWindow);
    
    // Store window reference
    windows.push(mainWindow);
    
    // Open the DevTools in development.
    if (process.env.NODE_ENV === 'development') {
      mainWindow.webContents.openDevTools();
    }
  }
};

const setupIPC = (screenIndex, window) => {
  // Set up a channel specific to this screen
  const channel = `screen-${screenIndex}`;
  
  // Handle messages from renderer
  ipcMain.on(`${channel}:send-data`, (event, data) => {
    console.log(`Received data from screen ${screenIndex}:`, data);
    
    // Process the data in the corresponding service
    const response = services[screenIndex].processData(data);
    
    // Send response back to renderer
    window.webContents.send(`${channel}:receive-data`, response);
  });
  
  // Initialize data push service for this screen
  services[screenIndex].startDataPush(data => {
    window.webContents.send(`${channel}:push-data`, data);
  });
};

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready', createWindows);

// Quit when all windows are closed, except on macOS.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindows();
  }
});
EOL

# Create the preload script
echo "Creating preload script..."
cat > src/preload.js << 'EOL'
const { contextBridge, ipcRenderer } = require('electron');

// Get the screen index from the URL
const urlParams = new URLSearchParams(window.location.search);
const screenIndex = parseInt(urlParams.get('screen')) || 0;
const channel = `screen-${screenIndex}`;

// Expose ipcRenderer to the renderer process
contextBridge.exposeInMainWorld('electron', {
  screen: {
    index: screenIndex,
  },
  ipc: {
    sendData: (data) => {
      ipcRenderer.send(`${channel}:send-data`, data);
    },
    onReceiveData: (callback) => {
      ipcRenderer.on(`${channel}:receive-data`, (_, data) => callback(data));
    },
    onPushData: (callback) => {
      ipcRenderer.on(`${channel}:push-data`, (_, data) => callback(data));
    }
  }
});
EOL

# Create the renderer entry file
echo "Creating renderer entry file..."
cat > src/renderer.jsx << 'EOL'
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './components/App';
import './styles.css';

// Create a root for the React tree
const rootElement = document.getElementById('root');
const root = createRoot(rootElement);

// Render the App component
root.render(<App />);
EOL

# Create index.html
echo "Creating HTML template..."
cat > src/index.html << 'EOL'
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8" />
    <title>Multi-Screen Electron App</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOL

# Create CSS styles
echo "Creating CSS styles..."
cat > src/styles.css << 'EOL'
body {
  font-family: Arial, sans-serif;
  margin: 0;
  padding: 0;
  overflow: hidden;
  background-color: #f0f0f0;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 100vh;
}

button {
  padding: 10px 15px;
  border: none;
  border-radius: 4px;
  background-color: #4285f4;
  color: white;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.3s;
}

button:hover {
  background-color: #3367d6;
}

.screen-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  padding: 20px;
  box-sizing: border-box;
  text-align: center;
}

.data-display {
  margin: 20px 0;
  padding: 15px;
  background-color: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  max-height: 300px;
  overflow-y: auto;
  width: 80%;
}

h1 {
  margin-bottom: 20px;
  color: #333;
}
EOL

# Create App component
echo "Creating React components..."
mkdir -p src/components
cat > src/components/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import Screen1 from './Screen1';
import Screen2 from './Screen2';
import Screen3 from './Screen3';
import Screen4 from './Screen4';
import Screen5 from './Screen5';
import Screen6 from './Screen6';

const screenComponents = [
  Screen1,
  Screen2,
  Screen3,
  Screen4,
  Screen5,
  Screen6
];

const App = () => {
  const [screenIndex, setScreenIndex] = useState(0);

  useEffect(() => {
    // Get the screen index from the electron global
    if (window.electron) {
      setScreenIndex(window.electron.screen.index);
    }
  }, []);

  // Render the appropriate screen component based on the index
  const ScreenComponent = screenComponents[screenIndex] || screenComponents[0];

  return <ScreenComponent />;
};

export default App;
EOL

# Create Screen components
for i in {1..6}; do
  echo "Creating Screen${i} component..."
  cat > src/components/Screen${i}.jsx << EOL
import React, { useState, useEffect } from 'react';

const Screen${i} = () => {
  const [receivedData, setReceivedData] = useState('');
  const [pushedData, setPushedData] = useState([]);

  useEffect(() => {
    // Set up listeners for IPC events
    if (window.electron) {
      window.electron.ipc.onReceiveData((data) => {
        setReceivedData(JSON.stringify(data, null, 2));
      });

      window.electron.ipc.onPushData((data) => {
        setPushedData(prev => [...prev, data].slice(-5)); // Keep only the last 5 items
      });
    }
  }, []);

  const handleSendData = () => {
    if (window.electron) {
      const data = {
        message: "Hello from Screen ${i}!",
        timestamp: new Date().toISOString()
      };
      window.electron.ipc.sendData(data);
    }
  };

  return (
    <div className="screen-container" style={{ backgroundColor: getScreenColor(${i}) }}>
      <h1>Screen ${i}</h1>
      
      <div className="data-display">
        <h3>Pushed Data from Service ${i}</h3>
        {pushedData.length > 0 ? (
          pushedData.map((data, index) => (
            <div key={index}>
              <pre>{JSON.stringify(data, null, 2)}</pre>
              <hr />
            </div>
          ))
        ) : (
          <p>No data received yet...</p>
        )}
      </div>

      <button onClick={handleSendData}>
        Send Data to Service ${i}
      </button>

      {receivedData && (
        <div className="data-display">
          <h3>Response from Service ${i}</h3>
          <pre>{receivedData}</pre>
        </div>
      )}
    </div>
  );
};

// Get a different color for each screen
function getScreenColor(index) {
  const colors = [
    '#f0e6ff', // Light Purple
    '#e6f0ff', // Light Blue
    '#e6fff0', // Light Green
    '#fff0e6', // Light Orange
    '#ffe6f0', // Light Pink
    '#f0ffe6', // Light Yellow
  ];
  return colors[index - 1] || colors[0];
}

export default Screen${i};
EOL
done

# Create services directory and service files
echo "Creating service modules..."
mkdir -p src/services
for i in {1..6}; do
  echo "Creating service${i} module..."
  cat > src/services/service${i}.js << EOL
/**
 * Service ${i} - Example data integration for Screen ${i}
 */

let intervalId = null;

// Process data received from the renderer
exports.processData = (data) => {
  console.log('Service ${i} processing data:', data);
  
  // Echo back the data with a service prefix
  return {
    source: 'Service${i}',
    receivedData: data,
    processed: true,
    timestamp: new Date().toISOString()
  };
};

// Start pushing example data to the renderer
exports.startDataPush = (callback) => {
  // Clear any existing interval
  if (intervalId) {
    clearInterval(intervalId);
  }
  
  // Push data every 5 seconds
  intervalId = setInterval(() => {
    const data = {
      source: 'Service${i}',
      type: 'push',
      value: Math.random() * 100,
      timestamp: new Date().toISOString()
    };
    callback(data);
  }, 5000);
};

// Stop pushing data
exports.stopDataPush = () => {
  if (intervalId) {
    clearInterval(intervalId);
    intervalId = null;
  }
};
EOL
done

echo "Project setup completed successfully!"
echo "To start the app, run: npm start"
