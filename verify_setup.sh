#!/bin/bash

# Contact Management System - Setup Verification Script
# This script checks if all required components are properly set up

echo "=================================="
echo "CMS Setup Verification"
echo "=================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Flutter
echo -n "Checking Flutter... "
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓ $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}✗ Flutter not found${NC}"
    echo "  Install from: https://flutter.dev/docs/get-started/install"
fi

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo -e "${GREEN}✓ $DOCKER_VERSION${NC}"
else
    echo -e "${RED}✗ Docker not found${NC}"
    echo "  Install Docker Desktop from: https://www.docker.com/products/docker-desktop"
fi

# Check Docker Compose
echo -n "Checking Docker Compose... "
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo -e "${GREEN}✓ $COMPOSE_VERSION${NC}"
else
    echo -e "${RED}✗ Docker Compose not found${NC}"
fi

echo ""
echo "=================================="
echo "Project Files Check"
echo "=================================="
echo ""

# Check backend files
echo "Backend files:"
files=(
    "backend/app/main.py"
    "backend/app/models.py"
    "backend/app/auth.py"
    "backend/Dockerfile"
    "backend/requirements.txt"
    "backend/.env.example"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file"
    fi
done

echo ""
echo "Flutter files:"
flutter_files=(
    "lib/main.dart"
    "lib/screens/login_screen.dart"
    "lib/screens/home_screen.dart"
    "lib/services/api_service.dart"
    "pubspec.yaml"
)

for file in "${flutter_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file"
    fi
done

echo ""
echo "Infrastructure files:"
infra_files=(
    "docker-compose.yml"
    "README.md"
    "QUICKSTART.md"
)

for file in "${infra_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file"
    fi
done

echo ""
echo "=================================="
echo "Configuration Check"
echo "=================================="
echo ""

# Check if .env exists
if [ -f "backend/.env" ]; then
    echo -e "${GREEN}✓${NC} backend/.env exists"

    # Check if OpenAI key is set
    if grep -q "OPENAI_API_KEY=sk-" backend/.env; then
        echo -e "${GREEN}✓${NC} OpenAI API key appears to be set"
    else
        echo -e "${YELLOW}⚠${NC} OpenAI API key might not be configured"
        echo "  Edit backend/.env and add your OpenAI API key"
    fi
else
    echo -e "${YELLOW}⚠${NC} backend/.env not found"
    echo "  Run: cp backend/.env.example backend/.env"
    echo "  Then edit backend/.env to add your OpenAI API key"
fi

echo ""
echo "=================================="
echo "Docker Services Check"
echo "=================================="
echo ""

# Check if Docker is running
if docker info &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"

    # Check if containers are running
    if docker-compose ps | grep -q "Up"; then
        echo -e "${GREEN}✓${NC} Docker containers are running"
        docker-compose ps
    else
        echo -e "${YELLOW}⚠${NC} Docker containers are not running"
        echo "  Start with: docker-compose up -d"
    fi
else
    echo -e "${RED}✗${NC} Docker daemon is not running"
    echo "  Start Docker Desktop"
fi

echo ""
echo "=================================="
echo "Next Steps"
echo "=================================="
echo ""

if [ ! -f "backend/.env" ]; then
    echo "1. Configure backend environment:"
    echo "   cp backend/.env.example backend/.env"
    echo "   Edit backend/.env and add your OpenAI API key"
    echo ""
fi

if ! docker-compose ps | grep -q "Up"; then
    echo "2. Start backend services:"
    echo "   docker-compose up -d"
    echo ""
fi

echo "3. Install Flutter dependencies:"
echo "   flutter pub get"
echo ""

echo "4. Run the Flutter app:"
echo "   flutter run"
echo ""

echo "5. Access API documentation:"
echo "   http://localhost:8000/docs"
echo ""

echo "=================================="
echo "Setup verification complete!"
echo "=================================="
