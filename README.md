# Flect - AI-Powered Journaling App

**Version 0.1** 🎉

An intelligent journaling app that transforms unstructured thoughts into organized journal entries with automatic task extraction.

## ✨ Features (v0.1)

### 📝 Brain Dump
- **Smart Input**: Natural language processing for unstructured thoughts
- **AI Processing**: Automatically structures your brain dumps into coherent journal entries
- **Task Extraction**: Identifies and extracts actionable tasks from your thoughts

### 📱 Views
- **Home View**: Main interface with brain dump functionality
- **Journal List**: Review all your journal entries
- **Journal Detail**: Deep dive into individual entries
- **Profile**: User settings and preferences

### 🏗️ Architecture
- **MVVM Pattern**: Clean separation of concerns
- **SwiftUI**: Modern, declarative UI framework
- **Local Storage**: Secure on-device data persistence
- **Modular Design**: Easily extensible for future features

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.5+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `flect.xcodeproj` in Xcode
3. Build and run on simulator or device

## 📁 Project Structure

```
flect/
├── flect/                    # Main app source
│   ├── Components/           # Reusable UI components
│   ├── Models/              # Data models
│   ├── Views/               # SwiftUI views
│   ├── ViewModels/          # MVVM view models
│   ├── Services/            # Business logic & data services
│   └── Utils/               # Utilities and helpers
├── flectTests/              # Unit tests
├── flectUITests/            # UI tests
└── backend/                 # Future backend services
```

## 🛣️ Roadmap

### 🔄 Backend Integration (v0.2)
- [ ] RESTful API server
- [ ] Real AI processing (OpenAI/Claude integration)
- [ ] Cloud synchronization
- [ ] User authentication
- [ ] Data backup & restore

### 🧠 Enhanced AI (v0.3)
- [ ] Advanced sentiment analysis
- [ ] Smart categorization
- [ ] Mood tracking
- [ ] Personalized insights
- [ ] Writing suggestions

### 🔧 Advanced Features (v0.4+)
- [ ] Cross-platform sync
- [ ] Collaborative journaling
- [ ] Rich media support (photos, voice)
- [ ] Analytics dashboard
- [ ] Export capabilities

## 🏛️ Architecture Decisions

### Frontend (iOS)
- **SwiftUI**: Native performance, modern declarative syntax
- **MVVM**: Testable, maintainable code structure
- **Local-first**: Works offline, syncs when connected

### Backend (Planned)
- **Node.js/TypeScript**: Fast development, shared language concepts
- **RESTful API**: Standard, scalable architecture
- **PostgreSQL**: Robust relational database
- **Redis**: Caching and session management

## 🔄 Development Workflow

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Individual feature development
- `hotfix/*`: Critical bug fixes

### Version Tagging
- Follow semantic versioning (v0.1.0, v0.2.0, etc.)
- Tag major milestones
- Maintain changelog

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📝 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

Built with passion for better journaling and mental wellness.

---

**Current Status**: ✅ iOS v0.1 Complete  
**Next Milestone**: 🔄 Backend Integration v0.2 