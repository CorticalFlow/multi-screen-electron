#!/bin/bash

# A script to create a React Electron app with 6 screens using Electron Forge and Tailwind CSS

echo "Creating multi-screen Electron app with React and Tailwind CSS (Dark Mode Default)..."

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

# Install Tailwind CSS and its dependencies
echo "Installing Tailwind CSS..."
npm install --save-dev tailwindcss @tailwindcss/postcss autoprefixer postcss-loader css-loader style-loader
npx tailwindcss init -p

# Create a .babelrc file for React
echo "Creating .babelrc for React support..."
echo '{
  "presets": ["@babel/preset-react"]
}' > .babelrc

# Update tailwind.config.js to include the src directory and enable dark mode
echo "Updating Tailwind configuration..."
cat > tailwind.config.js << 'EOL'
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{js,jsx,ts,tsx,html}",
  ],
  darkMode: 'class',
  theme: {
    extend: {},
  },
  plugins: [],
}
EOL

# Update postcss.config.js for proper Tailwind processing
echo "Creating PostCSS configuration..."
cat > postcss.config.js << 'EOL'
module.exports = {
  plugins: [
    '@tailwindcss/postcss',
    'autoprefixer',
  ],
}
EOL

# Update webpack.rules.js to support JSX and CSS with PostCSS
echo "Updating webpack configuration for JSX and Tailwind CSS support..."
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
  },
  {
    test: /\.css$/,
    use: [
      'style-loader',
      'css-loader',
      'postcss-loader'
    ],
  }
];
EOL

# Create webpack.renderer.config.js with proper JSX support
echo "Creating webpack.renderer.config.js with proper JSX support..."
cat > webpack.renderer.config.js << 'EOL'
const rules = require('./webpack.rules');

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

// Handle dark mode toggle across all screens
ipcMain.on('toggle-dark-mode', (event, isDark) => {
  console.log('Dark mode toggled:', isDark);
  // Broadcast dark mode state to all screens
  windows.forEach(window => {
    window.webContents.send('dark-mode-changed', isDark);
  });
});

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
    },
    toggleDarkMode: (isDark) => {
      ipcRenderer.send('toggle-dark-mode', isDark);
    },
    onDarkModeChanged: (callback) => {
      ipcRenderer.on('dark-mode-changed', (_, isDark) => callback(isDark));
    }
  }
});
EOL

# Create the renderer entry file with Tailwind CSS import
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
<html class="dark">
  <head>
    <meta charset="UTF-8" />
    <title>Multi-Screen Electron App</title>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
EOL

# Create Tailwind CSS base file with dark mode styles
echo "Creating Tailwind CSS with dark mode styles..."
cat > src/styles.css << 'EOL'
@import "tailwindcss";

@theme {
  --color-*: initial;
  --color-gray-50: #f8fafc;
  --color-gray-100: #f1f5f9;
  --color-gray-200: #e2e8f0;
  --color-gray-300: #cbd5e1;
  --color-gray-400: #94a3b8;
  --color-gray-500: #64748b;
  --color-gray-600: #475569;
  --color-gray-700: #334155;
  --color-gray-800: #1e293b;
  --color-gray-900: #0f172a;
  --color-blue-400: #60a5fa;
  --color-blue-500: #3b82f6;
  --color-blue-600: #2563eb;
  --color-blue-700: #1d4ed8;
  --color-yellow-400: #facc15;
}

/* Global styles for dark mode */
* {
  transition: background-color 0.3s ease, color 0.3s ease, border-color 0.3s ease;
}

/* Custom scrollbar styling */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 4px;
}

.dark ::-webkit-scrollbar-track {
  background: #1e293b;
}

::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 4px;
}

.dark ::-webkit-scrollbar-thumb {
  background: #4b5563;
}

::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.dark ::-webkit-scrollbar-thumb:hover {
  background: #6b7280;
}

/* Focus styles */
button:focus,
input:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

/* Custom animations */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in {
  animation: fadeIn 0.3s ease-out;
}

/* Ensure proper text rendering */
body {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  overflow: hidden;
  margin: 0;
  padding: 0;
}
EOL

# Create Dark Mode Context with dark mode as default
echo "Creating Dark Mode Context..."
mkdir -p src/contexts
cat > src/contexts/DarkModeContext.jsx << 'EOL'
import React, { createContext, useContext, useState, useEffect } from 'react';

const DarkModeContext = createContext();

export const useDarkMode = () => {
  const context = useContext(DarkModeContext);
  if (!context) {
    throw new Error('useDarkMode must be used within a DarkModeProvider');
  }
  return context;
};

export const DarkModeProvider = ({ children }) => {
  // Default to dark mode
  const [isDark, setIsDark] = useState(true);

  useEffect(() => {
    // Set dark mode as default on initial load
    document.documentElement.classList.add('dark');
    
    // Listen for dark mode changes from other screens
    if (window.electron && window.electron.ipc) {
      window.electron.ipc.onDarkModeChanged((darkMode) => {
        setIsDark(darkMode);
        if (darkMode) {
          document.documentElement.classList.add('dark');
        } else {
          document.documentElement.classList.remove('dark');
        }
      });
    }
  }, []);

  const toggleDarkMode = () => {
    const newDarkMode = !isDark;
    setIsDark(newDarkMode);
    
    if (newDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
    
    // Notify other screens via IPC
    if (window.electron && window.electron.ipc) {
      window.electron.ipc.toggleDarkMode(newDarkMode);
    }
  };

  return (
    <DarkModeContext.Provider value={{ isDark, toggleDarkMode }}>
      {children}
    </DarkModeContext.Provider>
  );
};
EOL

# Create App component with Dark Mode Provider
echo "Creating React components..."
mkdir -p src/components
cat > src/components/App.jsx << 'EOL'
import React, { useState, useEffect } from 'react';
import { DarkModeProvider } from '../contexts/DarkModeContext';
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
    if (window.electron && window.electron.screen) {
      setScreenIndex(window.electron.screen.index);
    }
  }, []);

  // Render the appropriate screen component based on the index
  const ScreenComponent = screenComponents[screenIndex] || screenComponents[0];

  return (
    <DarkModeProvider>
      <ScreenComponent />
    </DarkModeProvider>
  );
};

export default App;
EOL

# Create Screen components with unified background and dark mode support (default dark)
for i in {1..6}; do
  echo "Creating Screen${i} component..."
  cat > src/components/Screen${i}.jsx << EOL
import React, { useState, useEffect } from 'react';
import { useDarkMode } from '../contexts/DarkModeContext';

const Screen${i} = () => {
  const [receivedData, setReceivedData] = useState('');
  const [pushedData, setPushedData] = useState([]);
  const { isDark, toggleDarkMode } = useDarkMode();

  useEffect(() => {
    // Set up listeners for IPC events
    if (window.electron && window.electron.ipc) {
      window.electron.ipc.onReceiveData((data) => {
        setReceivedData(JSON.stringify(data, null, 2));
      });

      window.electron.ipc.onPushData((data) => {
        setPushedData(prev => [...prev, data].slice(-5)); // Keep only the last 5 items
      });
    }
  }, []);

  const handleSendData = () => {
    if (window.electron && window.electron.ipc) {
      const data = {
        message: "Hello from Screen ${i}!",
        timestamp: new Date().toISOString()
      };
      window.electron.ipc.sendData(data);
    }
  };

  return (
    <div className="w-full h-screen flex flex-col justify-center items-center p-8 bg-gray-900 text-gray-100">
      {/* Dark mode toggle button */}
      <button
        onClick={toggleDarkMode}
        className="fixed top-6 right-6 p-3 rounded-full bg-gray-700 hover:bg-gray-600 shadow-lg transition-all duration-200 z-50"
        title="Toggle Dark Mode"
      >
        {isDark ? (
          <svg className="w-6 h-6 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
            <path fillRule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" clipRule="evenodd" />
          </svg>
        ) : (
          <svg className="w-6 h-6 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
            <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
          </svg>
        )}
      </button>

      <div className="fade-in max-w-4xl w-full">
        <h1 className="text-5xl font-bold mb-12 text-center text-blue-400">
          Screen ${i}
        </h1>
        
        <div className="w-full max-h-96 overflow-y-auto bg-gray-800 rounded-xl shadow-2xl p-8 mb-8 border border-gray-700">
          <h3 className="text-2xl font-semibold mb-6 text-gray-200">
            Pushed Data from Service ${i}
          </h3>
          {pushedData.length > 0 ? (
            <div className="space-y-4">
              {pushedData.map((data, index) => (
                <div key={index} className="fade-in">
                  <pre className="text-sm text-left bg-gray-700 p-4 rounded-lg border border-gray-600 overflow-x-auto text-gray-200 font-mono">
                    {JSON.stringify(data, null, 2)}
                  </pre>
                  {index < pushedData.length - 1 && (
                    <hr className="my-4 border-gray-600" />
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p className="text-gray-400 text-center py-8">
              No data received yet...
            </p>
          )}
        </div>

        <div className="text-center">
          <button 
            onClick={handleSendData}
            className="px-8 py-4 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-xl shadow-lg transition-all duration-300 ease-in-out transform hover:scale-105 focus:outline-none focus:ring-4 focus:ring-blue-500 focus:ring-opacity-50"
          >
            Send Data to Service ${i}
          </button>
        </div>

        {receivedData && (
          <div className="w-full max-h-96 overflow-y-auto bg-gray-800 rounded-xl shadow-2xl p-8 mt-8 border border-gray-700 fade-in">
            <h3 className="text-2xl font-semibold mb-6 text-gray-200">
              Response from Service ${i}
            </h3>
            <pre className="text-sm text-left bg-gray-700 p-4 rounded-lg border border-gray-600 overflow-x-auto text-gray-200 font-mono">
              {receivedData}
            </pre>
          </div>
        )}
      </div>
    </div>
  );
};

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
echo ""
echo "🌙 DARK MODE FEATURES:"
echo "✅ Dark mode enabled by default"
echo "✅ Unified dark theme across all screens"
echo "✅ Dark mode toggle with cross-screen synchronization"
echo "✅ Modern dark UI with Tailwind CSS"
echo "✅ Smooth transitions and animations"
echo "✅ Proper dark mode styling (gray-900 backgrounds)"
echo ""
echo "To start the app, run: npm start"
echo ""
echo "Dark mode will be active by default on all screens!"
