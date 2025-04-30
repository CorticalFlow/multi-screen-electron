# Multi-Screen Electron Application Framework

## Overview

A powerful framework for building multi-screen Electron applications designed to enhance cognitive workflows. This project enables professionals in data-intensive fields to process, visualize, and act upon multiple streams of information simultaneously by distributing information across physical screens.

## Features

- **Automatic multi-screen detection** - Identifies and utilizes all connected displays
- **Screen-specific UI components** - Tailored React components for each screen's purpose
- **Secure IPC communication** - Safe inter-process communication between screens
- **Service modules architecture** - Modular data processing and business logic
- **Real-time data simulation** - Built-in tools to simulate data streams
- **Fullscreen display management** - Optimal use of available screen real estate

## Why Multi-Screen Applications?

- **Spatial Memory**: Leverage the brain's ability to remember information based on spatial location
- **Reduced Cognitive Load**: Minimize window switching and mental context shifts
- **Parallel Processing**: Enable simultaneous observation of multiple data streams
- **Context Preservation**: Maintain visual context for related information

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/multi-screen-electron-app.git

# Navigate to project directory
cd multi-screen-electron-app

# Install dependencies
npm install

# Start the application
npm start
```

## Quick Start with Bootstrap Script

For a fresh installation:

1. Save the bootstrap script as `bootstrap.sh`
2. Make it executable: `chmod +x bootstrap.sh`
3. Run it: `./bootstrap.sh`
4. Navigate to the created directory: `cd multi-screen-electron-app`
5. Start the application: `npm start`

## Architecture

The application follows a layered architecture:

- **Main Process**: Coordinates windows across displays
- **Renderer Processes**: Screen-specific UI components
- **Service Modules**: Data processing and business logic
- **IPC Bridge**: Communication between processes

## Potential Applications

- **Financial Analysis**: Market data, news feeds, portfolio performance
- **Security Operations**: Network traffic, threat feeds, system status
- **Research Dashboards**: Literature review, data visualization, note-taking
- **Medical Monitoring**: Patient vitals, medical history, treatment protocols
- **Project Management**: Task boards, team activities, documentation, metrics

## Development

The project uses:
- Electron with Electron Forge
- React for UI components
- Webpack for bundling
- Custom IPC architecture for secure inter-screen communication

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT 