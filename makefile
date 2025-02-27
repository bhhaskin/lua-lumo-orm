# Docker settings
IMAGE_NAME=lua-lumo
DOCKER_FILE=Dockerfile.dev

# Declare phony targets (these are not filenames)
.PHONY: build test shell clean

# Build Docker image
build:
	@echo "🛠️ Building Docker image $(IMAGE_NAME)..."
	docker build -t $(IMAGE_NAME) -f $(DOCKER_FILE) .

# Run tests using Docker container
test: build
	@echo "✅ Running tests..."
	docker run --rm $(IMAGE_NAME)

# Open interactive shell in Docker container (useful for debugging)
shell: build
	@echo "🐚 Opening shell in Docker container..."
	docker run --rm -it $(IMAGE_NAME) sh

# Clean up Docker image
clean:
	@echo "🧹 Removing Docker image..."
	docker rmi -f $(IMAGE_NAME)