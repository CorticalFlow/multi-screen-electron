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
const { app, BrowserWindow, ipcMain, screen, Tray, Menu, nativeImage, dialog } = require('electron');
const path = require('path');

// Handle creating/removing shortcuts on Windows when installing/uninstalling.
if (require('electron-squirrel-startup')) {
  app.quit();
}

// Array to store our windows
const windows = [];
let tray = null;

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

// Create system tray icon and menu
function createTray() {
  // Create icon for tray - use the generated PNG icon
  const iconPath = path.join(__dirname, '..', 'assets', 'tray-icon.png');
  let icon;
  
  try {
    // Try to load the PNG icon
    icon = nativeImage.createFromPath(iconPath);
    if (icon.isEmpty()) {
      throw new Error('Icon is empty');
    }
  } catch (error) {
    console.log('Creating fallback icon for tray...');
    // Create a simple, visible black square icon
    const fallbackIconData = Buffer.from([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, // IHDR chunk size
      0x49, 0x48, 0x44, 0x52, // IHDR
      0x00, 0x00, 0x00, 0x10, // Width: 16
      0x00, 0x00, 0x00, 0x10, // Height: 16
      0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth: 8, Color type: 2 (RGB), no alpha
      0x90, 0x91, 0x68, 0x36, // CRC
      0x00, 0x00, 0x00, 0x37, // IDAT chunk size (55 bytes)
      0x49, 0x44, 0x41, 0x54, // IDAT
      // Compressed image data for a solid black 16x16 square
      0x78, 0x9C, 0xED, 0xC1, 0x01, 0x01, 0x00, 0x00, 0x00, 0x80, 0x90, 0xFE, 0xAF, 0xEE, 0x08, 0x0A,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1F, 0x70, 0x00, 0x0B,
      0x1F, 0x10, 0x18, 0xDC, // IDAT CRC
      0x00, 0x00, 0x00, 0x00, // IEND chunk size
      0x49, 0x45, 0x4E, 0x44, // IEND
      0xAE, 0x42, 0x60, 0x82  // IEND CRC
    ]);
    icon = nativeImage.createFromBuffer(fallbackIconData);
  }
  
  // For macOS, set as template image for proper dark/light mode support
  icon.setTemplateImage(true);
  
  tray = new Tray(icon);
  
  // Create context menu for tray
  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Focus',
      submenu: [
        {
          label: 'Grab Focus (All Screens)',
          click: () => {
            grabFocus();
          }
        },
        {
          label: 'Show All Windows',
          click: () => {
            showAllWindows();
          }
        },
        {
          label: 'Focus Primary Screen',
          click: () => {
            focusSpecificScreen(0);
          }
        },
        {
          type: 'separator'
        },
        {
          label: 'Focus Screen 1',
          click: () => {
            focusSpecificScreen(0);
          }
        },
        {
          label: 'Focus Screen 2', 
          click: () => {
            focusSpecificScreen(1);
          }
        },
        {
          label: 'Focus Screen 3',
          click: () => {
            focusSpecificScreen(2);
          }
        },
        {
          label: 'Focus Screen 4',
          click: () => {
            focusSpecificScreen(3);
          }
        },
        {
          label: 'Focus Screen 5',
          click: () => {
            focusSpecificScreen(4);
          }
        },
        {
          label: 'Focus Screen 6',
          click: () => {
            focusSpecificScreen(5);
          }
        }
      ]
    },
    {
      type: 'separator'
    },
    {
      label: 'Windows',
      submenu: [
        {
          label: 'Create New Window Set',
          click: () => {
            createWindows();
          }
        },
        {
          label: 'Minimize All',
          click: () => {
            minimizeAllWindows();
          }
        },
        {
          label: 'Close All Windows',
          click: () => {
            closeAllWindows();
          }
        }
      ]
    },
    {
      type: 'separator'
    },
    {
      label: 'About Multi-Screen Electron App',
      click: () => {
        showAboutDialog();
      }
    },
    {
      type: 'separator'
    },
    {
      label: 'Quit',
      accelerator: process.platform === 'darwin' ? 'Cmd+Q' : 'Ctrl+Q',
      click: () => {
        app.quit();
      }
    }
  ]);
  
  tray.setToolTip('Multi-Screen Electron App');
  tray.setContextMenu(contextMenu);
  
  // Handle tray click (primarily for Windows, but works on macOS too)
  tray.on('click', () => {
    grabFocus();
  });
}

// Show all existing windows
function showAllWindows() {
  console.log('Showing all windows...');
  windows.forEach((window, index) => {
    if (window && !window.isDestroyed()) {
      if (window.isMinimized()) {
        window.restore();
      }
      window.show();
      window.focus();
    }
  });
  app.focus();
}

// "Grab Focus" function - brings all windows to front on all screens
function grabFocus() {
  console.log('Grabbing focus for all windows...');
  
  // Get all displays
  const displays = screen.getAllDisplays();
  console.log(`Found ${displays.length} display(s)`);
  
  // Show and focus all existing windows
  windows.forEach((window, index) => {
    if (window && !window.isDestroyed()) {
      console.log(`Processing window ${index + 1}`);
      
      // Restore if minimized
      if (window.isMinimized()) {
        window.restore();
      }
      
      // Show window
      window.show();
      
      // Force focus using the "always on top" trick
      window.setAlwaysOnTop(true);
      window.focus();
      
      // Remove always on top after a short delay
      setTimeout(() => {
        if (window && !window.isDestroyed()) {
          window.setAlwaysOnTop(false);
        }
      }, 100);
    }
  });
  
  // If no windows exist, create them
  if (windows.length === 0) {
    createWindows();
  }
  
  // Focus the app itself
  app.focus();
}

// Focus a specific screen/window
function focusSpecificScreen(screenIndex) {
  console.log(`Focusing screen ${screenIndex + 1}...`);
  
  if (screenIndex >= 0 && screenIndex < windows.length) {
    const window = windows[screenIndex];
    if (window && !window.isDestroyed()) {
      // Restore if minimized
      if (window.isMinimized()) {
        window.restore();
      }
      
      // Show and focus the window
      window.show();
      window.setAlwaysOnTop(true);
      window.focus();
      
      // Remove always on top after a short delay
      setTimeout(() => {
        if (window && !window.isDestroyed()) {
          window.setAlwaysOnTop(false);
        }
      }, 100);
      
      app.focus();
    } else {
      console.log(`Screen ${screenIndex + 1} window not available`);
    }
  } else {
    console.log(`Invalid screen index: ${screenIndex + 1}`);
  }
}

// Minimize all windows
function minimizeAllWindows() {
  console.log('Minimizing all windows...');
  windows.forEach((window, index) => {
    if (window && !window.isDestroyed()) {
      window.minimize();
      console.log(`Minimized window ${index + 1}`);
    }
  });
}

// Close all windows
function closeAllWindows() {
  console.log('Closing all windows...');
  windows.forEach((window, index) => {
    if (window && !window.isDestroyed()) {
      window.close();
      console.log(`Closed window ${index + 1}`);
    }
  });
  // Clear the windows array
  windows.length = 0;
}

// Show about dialog
function showAboutDialog() {
  dialog.showMessageBox(null, {
    type: 'info',
    title: 'About Multi-Screen Electron App',
    message: 'Multi-Screen Electron App',
    detail: `A powerful multi-screen Electron application with system tray integration.

Version: 1.0.0
Platform: ${process.platform}
Electron: ${process.versions.electron}
Node.js: ${process.versions.node}
Chrome: ${process.versions.chrome}

Features:
• Multi-screen window management
• System tray integration  
• Dark mode support
• Cross-screen synchronization
• Focus management across displays

Created with Electron Forge, React, and Tailwind CSS.`,
    buttons: ['OK']
  });
}

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
app.on('ready', () => {
  createTray();
  createWindows();
});

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

// Clean up tray when app is quitting
app.on('before-quit', () => {
  if (tray) {
    tray.destroy();
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

# Create a simple tray icon (SVG that can be converted to PNG)
echo "Creating system tray icon..."
mkdir -p src/assets
cat > src/assets/tray-icon.svg << 'EOL'
<svg width="16" height="16" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
  <rect width="16" height="16" fill="none"/>
  <rect x="2" y="2" width="12" height="12" fill="currentColor" stroke="currentColor" stroke-width="1" rx="2"/>
  <rect x="4" y="4" width="8" height="8" fill="none" stroke="white" stroke-width="1" rx="1"/>
  <rect x="6" y="6" width="4" height="4" fill="white" rx="1"/>
</svg>
EOL

# Create a PNG version for the tray icon (16x16 pixels, template image for macOS)
echo "Creating PNG tray icon..."
cat > src/assets/create-icon.js << 'EOL'
// Create a proper system tray icon for macOS
const fs = require('fs');
const path = require('path');

// Create a simple but visible 16x16 PNG icon (computer/monitor icon)
// This creates a black template icon that will be visible in the menu bar
const pngData = Buffer.from([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, // IHDR chunk size
  0x49, 0x48, 0x44, 0x52, // IHDR
  0x00, 0x00, 0x00, 0x10, // Width: 16
  0x00, 0x00, 0x00, 0x10, // Height: 16
  0x08, 0x06, 0x00, 0x00, 0x00, // Bit depth: 8, Color type: 6 (RGBA), Compression: 0, Filter: 0, Interlace: 0
  0x1F, 0xF3, 0xFF, 0x61, // IHDR CRC
  
  // IDAT chunk with simple monitor/screen icon
  0x00, 0x00, 0x00, 0x96, // IDAT chunk size
  0x49, 0x44, 0x41, 0x54, // IDAT
  0x78, 0x9C, 0x95, 0x90, 0x31, 0x0A, 0x80, 0x30, 0x10, 0x45, 0x5F, 0x53, 0x0A, 0x82, 0x20, 0x88,
  0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95,
  0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20,
  0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88,
  0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95,
  0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20,
  0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88,
  0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95,
  0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x20,
  0x88, 0x95, 0x20, 0x88, 0x95, 0x20, 0x88, 0x95, 0x9A, 0x54, 0x7A, 0x96, // Compressed data
  0xF7, 0x5A, 0x12, 0x34, // IDAT CRC
  
  0x00, 0x00, 0x00, 0x00, // IEND chunk size
  0x49, 0x45, 0x4E, 0x44, // IEND
  0xAE, 0x42, 0x60, 0x82  // IEND CRC
]);

// Alternative: Create a simple graphic icon programmatically
function createSimpleIcon() {
  // Create a basic 16x16 RGBA image data for a monitor icon
  const width = 16;
  const height = 16;
  const bytesPerPixel = 4; // RGBA
  const imageData = Buffer.alloc(width * height * bytesPerPixel);
  
  // Fill with transparent background
  imageData.fill(0);
  
  // Draw a simple computer monitor shape in black
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const index = (y * width + x) * bytesPerPixel;
      
      // Monitor outline (3-11 x, 2-10 y)
      if ((x >= 3 && x <= 11 && (y === 2 || y === 10)) || 
          (y >= 2 && y <= 10 && (x === 3 || x === 11))) {
        imageData[index] = 0;     // R
        imageData[index + 1] = 0; // G  
        imageData[index + 2] = 0; // B
        imageData[index + 3] = 255; // A
      }
      
      // Monitor base (6-8 x, 11-12 y)
      if (x >= 6 && x <= 8 && y >= 11 && y <= 12) {
        imageData[index] = 0;     // R
        imageData[index + 1] = 0; // G
        imageData[index + 2] = 0; // B  
        imageData[index + 3] = 255; // A
      }
      
      // Monitor base support (7, 13)
      if (x === 7 && y === 13) {
        imageData[index] = 0;     // R
        imageData[index + 1] = 0; // G
        imageData[index + 2] = 0; // B
        imageData[index + 3] = 255; // A
      }
    }
  }
  
  return imageData;
}

try {
  fs.writeFileSync(path.join(__dirname, 'tray-icon.png'), pngData);
  console.log('Tray icon created successfully');
} catch (error) {
  console.log('Creating fallback icon...');
  // Create a simple black square as absolute fallback
  const simpleIcon = Buffer.from([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00, 0x10,
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x91, 0x68, 0x36,
    0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, 0x54,
    0x78, 0x9C, 0x62, 0x00, 0x02, 0x00, 0x00, 0x05, 0x00, 0x01,
    0x0D, 0x0A, 0x2D, 0xB4,
    0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
  ]);
  fs.writeFileSync(path.join(__dirname, 'tray-icon.png'), simpleIcon);
  console.log('Fallback tray icon created');
}
EOL

# Generate the tray icon
echo "Generating tray icon PNG file..."
cd src/assets
node create-icon.js
cd ../..

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
echo "🖱️  SYSTEM TRAY FEATURES:"
echo "✅ System tray icon in macOS menu bar (top-right)"
echo "✅ Context menu with app controls"
echo "✅ 'Grab Focus' functionality to bring all windows to front"
echo "✅ 'Show All Windows' to restore minimized windows"
echo "✅ Template icon that adapts to macOS dark/light themes"
echo "✅ Cross-screen window management"
echo ""
echo "To start the app, run: npm start"
echo ""
echo "Features:"
echo "• Dark mode will be active by default on all screens"
echo "• System tray icon will appear in macOS menu bar"
echo "• Right-click tray icon for app controls"
echo "• Click tray icon to grab focus of all windows"
